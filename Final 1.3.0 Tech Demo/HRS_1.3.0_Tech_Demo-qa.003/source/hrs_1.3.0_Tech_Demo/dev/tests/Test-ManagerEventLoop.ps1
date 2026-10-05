# Exercise the real blocking native message loop in a separate STA file host.
# Only the discovered game-root assignment and DEV dispatch switch are staged.
# Native C# events drive controls without PowerShell test callbacks or DoEvents.
param([Parameter(Mandatory=$true)][string]$EvidenceRoot)
$ErrorActionPreference='Stop'
$devRoot=Split-Path -Parent $PSScriptRoot
$source=Join-Path $devRoot 'ui/p0158.ps1'
$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$root=Join-Path ([IO.Path]::GetTempPath()) ('hrs130-event-loop-'+[guid]::NewGuid().ToString('N'))
$stage=Join-Path $root 'stage'; $fixture=Join-Path $root 'game'
$evidence=[IO.Path]::GetFullPath($EvidenceRoot)
foreach($path in @($evidence,(Join-Path $stage 'dev/ui'),(Join-Path $stage 'dev/src/launcher'),(Join-Path $stage 'dev/verified/main'),(Join-Path $fixture '7DaysToDie_Data/Managed'))) {
    [void][IO.Directory]::CreateDirectory($path)
}
Copy-Item (Join-Path $devRoot 'src/launcher/*.psm1') (Join-Path $stage 'dev/src/launcher')
Copy-Item (Join-Path $devRoot 'verified/main/*') (Join-Path $stage 'dev/verified/main')
Copy-Item -LiteralPath (Join-Path $devRoot 'ui/logo.ico') -Destination (Join-Path $stage 'dev/ui/logo.ico')
[IO.File]::WriteAllText((Join-Path $fixture '7DaysToDie.exe'),'Inert fixture; never executed.')
[IO.File]::WriteAllText((Join-Path $fixture '7DaysToDie_Data/Managed/Assembly-CSharp.dll'),'Inert fixture; never loaded.')
$text=[IO.File]::ReadAllText($source).Replace('$useDevCandidate = $true','$useDevCandidate = $false')
$assemblyEntry='Add-Type -AssemblyName System.Windows.Forms'
if($text.Split(@($assemblyEntry),[StringSplitOptions]::None).Length -ne 2){throw 'Native assembly entry is not unique.'}
$text=$text.Replace($assemblyEntry,$assemblyEntry+"`r`n"+'[Windows.Forms.Application]::SetUnhandledExceptionMode([Windows.Forms.UnhandledExceptionMode]::CatchException)')
$entry='$gameRoot = if ($SmokeTest -and $GameRootOverride) { $GameRootOverride } else { Select-HrsGameRoot -StartPath $managerRoot }'
if($text.Split(@($entry),[StringSplitOptions]::None).Length -ne 2){throw 'Game-root entry is not unique.'}
$text=$text.Replace($entry,'$gameRoot = '+"'"+$fixture.Replace("'","''")+"'")
$tail='[void]$form.ShowDialog()'
if($text.Split(@($tail),[StringSplitOptions]::None).Length -ne 2){throw 'Normal event-loop entry is not unique.'}
$driver=@'
$nativeLoopCode=@"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Windows.Forms;
public sealed class HrsEventLoopProbe : IDisposable {
    public readonly List<string> Events=new List<string>();
    public readonly List<string> Errors=new List<string>();
    private readonly Form form;
    private readonly string evidence;
    private readonly Timer timer=new Timer();
    private int step;
    public HrsEventLoopProbe(Form form,string evidence) {
        this.form=form; this.evidence=evidence;
        Application.ThreadException+=OnException;
        form.Shown+=OnShown;
        timer.Interval=250; timer.Tick+=OnTick;
    }
    private void OnShown(object sender,EventArgs args){Events.Add("Shown");timer.Start();}
    private void OnException(object sender,System.Threading.ThreadExceptionEventArgs args){Errors.Add(args.Exception.ToString());timer.Stop();form.Close();}
    private Control Find(Control parent,string name){
        if(parent.AccessibleName==name)return parent;
        foreach(Control child in parent.Controls){Control match=Find(child,name);if(match!=null)return match;}
        return null;
    }
    private void OnTick(object sender,EventArgs args){
        try {
            switch(++step){
                case 1: Find(form,"Exact Game Name for the save").Text="Future Save";Events.Add("draft name");break;
                case 2: ((RadioButton)Find(form,"Random start")).Checked=true;Events.Add("random mode");break;
                case 3: form.Invalidate(true);form.Update();Events.Add("repaint");break;
                case 4: form.WindowState=FormWindowState.Minimized;Events.Add("minimize");break;
                case 5: form.WindowState=FormWindowState.Normal;form.Activate();Events.Add("restore and activate");break;
                case 6: form.Width+=20;form.Invalidate(true);Events.Add("resize");break;
                case 7:
                    if(Find(form,"Exact Game Name for the save").Text!="Future Save")throw new Exception("Native draft name changed during event-loop transitions.");
                    Events.Add("draft name retained");
                    using(Bitmap bitmap=new Bitmap(form.Width,form.Height)){
                        form.DrawToBitmap(bitmap,new Rectangle(0,0,form.Width,form.Height));
                        bitmap.Save(Path.Combine(evidence,"normal-event-loop.png"));
                    }
                    Control logo=Find(form,"Bit Wrecked picture-only logo");
                    using(Bitmap bitmap=new Bitmap(logo.Width,logo.Height)){
                        logo.DrawToBitmap(bitmap,new Rectangle(0,0,logo.Width,logo.Height));
                        bitmap.Save(Path.Combine(evidence,"normal-event-loop-logo.png"));
                        int colored=0,red=0;
                        for(int x=0;x<bitmap.Width;x++)for(int y=0;y<bitmap.Height;y++){
                            Color c=bitmap.GetPixel(x,y);
                            if(Math.Max(c.R,Math.Max(c.G,c.B))-Math.Min(c.R,Math.Min(c.G,c.B))>50)colored++;
                            if(c.R>220&&c.G<30&&c.B<30)red++;
                        }
                        // The WinForms error picture is a pure-red border/X on white.
                        // The owned multicolored icon supplies many non-red pixels.
                        if(colored<bitmap.Width*bitmap.Height/10||red>colored*3/4)throw new Exception("Header logo resembles an error placeholder.");
                        Events.Add("multicolor logo rendered");
                    }
                    break;
                case 9: timer.Stop();Events.Add("normal close");form.Close();break;
            }
        }catch(Exception exception){Errors.Add(exception.ToString());timer.Stop();form.Close();}
    }
    public void Dispose(){timer.Dispose();form.Shown-=OnShown;Application.ThreadException-=OnException;}
}
"@
Add-Type -TypeDefinition $nativeLoopCode -ReferencedAssemblies System.Windows.Forms,System.Drawing
$probe=New-Object HrsEventLoopProbe($form,$probeEvidence)
try { [void]$form.ShowDialog() }
finally {
    $form.Dispose()
    $probe.Dispose()
    [IO.File]::WriteAllText((Join-Path $probeEvidence 'native-events.json'),(ConvertTo-Json -InputObject @($probe.Events.ToArray())))
    [IO.File]::WriteAllText((Join-Path $probeEvidence 'native-errors.json'),(ConvertTo-Json -InputObject @($probe.Errors.ToArray())))
}
if($probe.Errors.Count){throw ($probe.Errors -join "`r`n")}
if(!$probe.Events.Contains('normal close')){throw 'Native loop did not finish.'}
'PASS: normal STA file-host event loop, repaint, logo, activation, resize, minimize/restore and clean close.'
'@
$driver='$probeEvidence='+"'"+$evidence.Replace("'","''")+"'`r`n"+$driver
$text=$text.Replace($tail,$driver)
$child=Join-Path $stage 'dev/ui/p0158.ps1'
[IO.File]::WriteAllText($child,$text,(New-Object Text.UTF8Encoding($false)))
$savedPreference=$ErrorActionPreference
try { $ErrorActionPreference='Continue'; $output=& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $child 2>&1; $code=$LASTEXITCODE }
finally {$ErrorActionPreference=$savedPreference}
$output | Set-Content -LiteralPath (Join-Path $evidence 'output.txt') -Encoding UTF8
if($code -ne 0){throw "Native event loop failed: $($output | Out-String)"}
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $sourceHash){throw 'Manager source changed during native event-loop check.'}
[ordered]@{schema='hrs-manager-native-event-loop/v1';status='Pass';sourceSha256=$sourceHash;harnessSha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash;host='Windows PowerShell 5.1 STA file process';scope='Current actual display and normal blocking ShowDialog; isolated inert game. No Apply, launch, removal, gameplay, Narrator or OS-scale qualification.';completedUtc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $evidence 'verification.json') -Encoding UTF8
$output
