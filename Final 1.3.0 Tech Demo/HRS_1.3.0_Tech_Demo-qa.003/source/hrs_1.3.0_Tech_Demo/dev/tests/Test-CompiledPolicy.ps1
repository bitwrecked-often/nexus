$ErrorActionPreference='Stop'
$dev=Split-Path -Parent $PSScriptRoot
$assembly=[Reflection.Assembly]::LoadFrom((Join-Path $dev 'verified/main/d0163.dll'))
$codec=$assembly.GetType('BitWrecked.HistoricalRandomStart.PolicyV2Codec',$true)
$flags=[Reflection.BindingFlags]::NonPublic -bor [Reflection.BindingFlags]::Static
$reader=$codec.GetMethod('TryRead',$flags)
$serializer=$codec.GetMethod('Serialize',$flags)
$path=[IO.Path]::GetTempFileName()
$vectors=Get-Content (Join-Path $dev 'qa/POLICY_V2_VECTORS.json') -Raw | ConvertFrom-Json
try {
    foreach($vector in $vectors) {
        [IO.File]::WriteAllText($path,$vector.canonical,(New-Object Text.UTF8Encoding($false)))
        $args=[object[]]@($path,$null,$null)
        if(!$reader.Invoke($null,$args)){throw 'COMPILED_POLICY_REJECTED_VECTOR'}
        if($serializer.Invoke($null,@($args[1])) -cne $vector.canonical){throw 'COMPILED_POLICY_BYTES_MISMATCH'}
    }
    [IO.File]::WriteAllText($path,$vector.canonical.Replace('"forest":10','"forest":11'),(New-Object Text.UTF8Encoding($false)))
    $args=[object[]]@($path,$null,$null)
    if($reader.Invoke($null,$args)){throw 'COMPILED_POLICY_ACCEPTED_TAMPER'}
    'PASS: 7 canonical vectors and tamper rejection through the verified runtime DLL'
} finally {[IO.File]::Delete($path)}
