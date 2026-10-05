using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using BitWrecked.HistoricalRandomStart;
using UnityEngine;

internal static class Program
{
    private static readonly Type Consumer=typeof(HistoricalRandomStartModApi);
    private static readonly BindingFlags Flags=BindingFlags.Static|BindingFlags.NonPublic;
    private static readonly List<object> Records=new List<object>();
    private static void Set(string name,object value)=>Consumer.GetField(name,Flags).SetValue(null,value);
    private static T Get<T>(string name)=>(T)Consumer.GetField(name,Flags).GetValue(null);
    private static void Call(string name,params object[] arguments)
    {
        try {Consumer.GetMethod(name,Flags).Invoke(null,arguments);}
        catch(TargetInvocationException error){throw error.InnerException;}
    }
    private static void Require(bool condition,string detail){if(!condition)throw new Exception(detail);}
    private static bool At(Vector3 left,Vector3 right)=>left.x==right.x&&left.y==right.y&&left.z==right.z;
    private static readonly Vector3 Original=new Vector3(0,21,0);
    private static string Result()=>AtomicResultWriter.Last?.Outcome+"/"+AtomicResultWriter.Last?.Reason;
    private static World Begin(int count=1,int safeAt=1)
    {
        var world=new World();world.Player.Position=Original;world.Player.QuestJournal.OwnerPlayer=world.Player;
        GameManager.Instance=new GameManager {World=world};GameManager.IsDedicatedServer=false;
        GamePrefs.GameName="Target Game";GamePrefs.EACEnabled=false;
        ConnectionManager.Instance=new ConnectionManager();CompatibilityGuard.Compatible=true;
        AtomicResultWriter.Last=null;AtomicResultWriter.Writes=0;SanitizedRuntimeLog.Entries.Clear();
        PlacedPoiResolver.Pool.Clear();PlacedPoiResolver.SelectCalls=0;ObjectiveGoto.LocationWorks=true;
        PlacedPoiResolver.ResolvedBiome=1;PlacedPoiResolver.ResolvedFamily=8;
        PlacedTraderResolver.Status=TraderIndexStatus.Ready;PlacedTraderResolver.SelectionAvailable=true;
        PlacedTraderResolver.CrossedBiome=false;PlacedTraderResolver.SelectCalls=0;
        PlacedTraderResolver.Selected=new PlacedTrader {Location=new Vector3(310,21,420),Size=new Vector3(40,30,50)};
        for(int i=1;i<=count;i++)PlacedPoiResolver.Pool.Add(new ResolvedPoi {
            WorldRef=world,InstanceId=i,BiomeId=1,Safe=i==safeAt,Approach=new Vector3(i*100,21,100)});
        var policy=new PolicyV2(1,"Target Game","Random",true,BiomePreference.Any,
            "2026-10-04T00:00:00.000Z",new string('0',64));
        Set("sessionPolicy",policy);Set("resultWriter",new AtomicResultWriter(new OwnedBridgePaths()));
        Set("pending",null);Set("sessionAttemptConsumed",false);Set("protectedEntityId",-1);
        Set("traderPreflightWorld",null);Set("traderPreflightWorldGuid",null);Set("traderPreflightEntityId",-1);
        Set("traderPreflightSelection",null);Set("traderPreflightPoi",null);Set("traderPreflightDeadline",0f);
        Set("traderRoutePlayer",null);Set("traderRouteEntityId",-1);Set("traderRouteSubscribed",false);
        Time.realtimeSinceStartup=0;return world;
    }
    private static void Spawn(RespawnType type=RespawnType.NewGame,bool local=true)=>Call("OnPlayerSpawned",
        new ModEvents.SPlayerSpawnedInWorldData {RespawnType=type,EntityId=1,IsLocalPlayer=local});
    private static void Update(float time){Time.realtimeSinceStartup=time;Call("OnGameUpdate",new ModEvents.SGameUpdateData());}
    private static void Finish(){for(float t=0;t<=150&&Get<PendingPlacement>("pending")!=null;t++)Update(t);}
    private static void Consumed(World world)
    {
        int before=world.Player.Positions.Count,writes=AtomicResultWriter.Writes;
        Spawn();Update(151);
        Require(world.Player.Positions.Count==before&&AtomicResultWriter.Writes==writes,"No-repeat reservation was lost");
    }
    private static void MovementFailure(string failure)
    {
        var world=Begin();Spawn();
        if(failure=="player")world.Player.ThrowAfterMoveOnce=true;
        if(failure=="observer")world.Player.ChunkObserver.ThrowAfterMoveOnce=true;
        if(failure=="semantic")world.Player.ChangeHealthAfterMoveOnce=true;
        Update(0);
        Require(Get<PendingPlacement>("pending")==null,"Failed transaction remains pending");
        Require(At(world.Player.Position,Original),"Player not returned to original start");
        Require(world.Player.ChunkObserver.Positions.Count>0&&At(world.Player.ChunkObserver.Positions.Last(),Original),"Observer not returned to original start");
        Require(MarkerStore.Read(world.Player)==MarkerState.Reserved,"Failure removed the consumed marker");
        Require(Result()=="FAILED/"+(failure=="semantic"?"SEMANTIC_CHANGED":"PLACEMENT_FAILED"),"Unexpected failure diagnostic: "+Result());
        Require(world.Player.Positions.Count==2,"Expected candidate movement then one restore");
        Consumed(world);
    }
    private static void Placement(bool success)
    {
        var world=Begin(6,success?5:0);Spawn();Finish();
        Require(Result()==(success?"COMPLETED/RELOCATION_COMPLETED":"FAILED/POI_SAFETY_EXHAUSTED"),"Wrong placement result: "+Result());
        Require(MarkerStore.Read(world.Player)==(success?MarkerState.Completed:MarkerState.Reserved),"Wrong terminal marker");
        Require(PlacedPoiResolver.SelectCalls==1,"Starting biome was redrawn");
        var attempts=SanitizedRuntimeLog.Entries.Where(value=>value.StartsWith("POI_ATTEMPT:")).ToArray();
        Require(attempts.Length==5&&attempts.Distinct().Count()==5,"Retry count/distinct instances changed");
        var moveTimes=world.Player.Positions.Select((position,index)=>(position,index))
            .Where(pair=>pair.position.x>0&&pair.position.y==21).Select(pair=>world.Player.PositionTimes[pair.index]).ToArray();
        Require(moveTimes.Length==5&&moveTimes.Zip(moveTimes.Skip(1),(a,b)=>b-a).All(delta=>delta>=3),"Retry delay changed");
        Require(SanitizedRuntimeLog.Entries.Count(value=>value=="CANDIDATE_PRIME_WAIT")==5,"Chunk prime schedule changed");
        if(success)
        {
            Require(world.Player.Positions.Last().x==500,"Fifth safe instance was not completed");
            Require(MarkerStore.ReadInitialBiome(world.Player)==1,"Starting biome was not persisted");
            var quest=new Quest {ID="quest_whiteRiverCitizen1"};quest.Objectives.Add(new ObjectiveGoto());
            world.Player.Accept(quest);
            Require(MarkerStore.ReadTraderRoute(world.Player)==TraderRouteState.Completed,"Valid trader route was lost");
        }
        else Require(At(world.Player.Position,Original),"Unsafe pool did not restore ordinary start");
        Consumed(world);
    }
    private static void WorldChanged(bool sameGuid)
    {
        var old=Begin();Spawn();Update(0);
        var replacement=new World {Guid=sameGuid?old.Guid:"replacement-world"};
        replacement.Player.Position=new Vector3(800,21,800);var before=replacement.Player.Position;
        GameManager.Instance.World=replacement;Update(1);
        Require(At(replacement.Player.Position,before)&&replacement.Player.Positions.Count==0,"Different-world player was moved by recovery");
        Require(replacement.Player.ChunkObserver.Positions.Count==0,"Different-world observer was moved by recovery");
        Require(Result()=="FAILED/VERIFY_CONTEXT_FAILED"&&Get<PendingPlacement>("pending")==null,"Wrong world rejection");
        Require(MarkerStore.Read(old.Player)==MarkerState.Reserved,"Original reservation was lost");
    }
    private static void EntityChanged()
    {
        var world=Begin();Spawn();Update(0);var originalPlayer=world.Player;
        world.Player=new EntityPlayer {Position=new Vector3(700,21,700)};var before=world.Player.Position;
        Update(1);
        Require(At(world.Player.Position,before)&&world.Player.Positions.Count==0,"Replacement entity with reused ID was moved");
        Require(Result()=="FAILED/VERIFY_CONTEXT_FAILED"&&Get<PendingPlacement>("pending")==null,"Replacement entity was not rejected");
        Require(MarkerStore.Read(originalPlayer)==MarkerState.Reserved,"Original entity reservation was lost");
    }
    private static void SameOwnerContextFailure()
    {
        var world=Begin();Spawn();Update(0);GamePrefs.GameName="Other Game";Update(1);
        Require(At(world.Player.Position,Original),"Original owner did not recover on context failure");
        Require(Result()=="FAILED/VERIFY_CONTEXT_FAILED","Context failure diagnostic changed");
        Require(MarkerStore.Read(world.Player)==MarkerState.Reserved,"Context failure cleared marker");
    }
    private static void QuestFilter(string context)
    {
        var world=Begin();var player=world.Player;
        if(context!="unmarked")
        {
            Require(MarkerStore.TryReserve(player)&&MarkerStore.TryComplete(player),"Fixture placement marker failed");
            Require(MarkerStore.TrySetInitialBiome(player,1),"Fixture initial biome failed");
            Require(MarkerStore.TryBeginTraderRoute(player)&&MarkerStore.TryReserveTraderRoute(player)&&MarkerStore.TryCompleteTraderRoute(player),"Fixture trader marker failed");
        }
        if(context=="name")GamePrefs.GameName="Other Game";
        if(context=="case")GamePrefs.GameName="target game";
        if(context=="eac")GamePrefs.EACEnabled=true;
        if(context=="multiplayer")ConnectionManager.Instance.IsSinglePlayer=false;
        if(context=="dedicated")GameManager.IsDedicatedServer=true;
        if(context=="build")CompatibilityGuard.Compatible=false;
        var objective=new ObjectiveRandomGotoNPC {biomeFilterType=BiomeFilterTypes.OnlyBiome,biomeFilter="pine_forest"};
        var quest=new Quest {ID="intro_buried_supplies"};quest.Objectives.Add(objective);
        Call("IntroRouteSetupPositionPrefix",quest,player);
        Require(objective.biomeFilter==(context=="valid"?"snow":"pine_forest"),"Objective changed outside eligible target/context");
        Require(objective.biomeFilterType==BiomeFilterTypes.OnlyBiome&&!objective.positionSet,"Other objective state changed");
    }
    private static void SpawnRejected(RespawnType type,bool mismatched)
    {
        var world=Begin();if(mismatched)GamePrefs.GameName="Other Game";Spawn(type);
        Require(world.Player.Positions.Count==0&&Get<PendingPlacement>("pending")==null&&MarkerStore.Read(world.Player)==MarkerState.Absent,"Ineligible spawn moved/reserved player");
        Require(Result()=="REJECTED/"+(mismatched?"GAME_NAME_MISMATCH":"LIFECYCLE_REJECTED"),"Wrong spawn rejection");
    }
    private static void Policy(string mode,BiomePreference preference=null)
    {
        Set("sessionPolicy",new PolicyV2(2,"Target Game",mode,true,preference ?? BiomePreference.Any,
            "2026-10-05T00:00:00.000Z",new string('1',64)));
    }
    private static void ResetTransientSession(EntityPlayer player)
    {
        player.ClearQuestAcceptedHandlers();
        Set("pending",null);Set("sessionAttemptConsumed",false);Set("protectedEntityId",-1);
        Set("traderPreflightWorld",null);Set("traderPreflightWorldGuid",null);Set("traderPreflightEntityId",-1);
        Set("traderPreflightSelection",null);Set("traderPreflightPoi",null);Set("traderPreflightDeadline",0f);
        Set("traderRoutePlayer",null);Set("traderRouteEntityId",-1);Set("traderRouteSubscribed",false);
        AtomicResultWriter.Last=null;AtomicResultWriter.Writes=0;SanitizedRuntimeLog.Entries.Clear();
        Time.realtimeSinceStartup=0;
    }
    private static void CompletedMarker(EntityPlayer player,int biome=1,int family=0)
    {
        Require(MarkerStore.TryReserve(player)&&MarkerStore.TryComplete(player),"Fixture completion failed");
        Require(MarkerStore.TrySetInitialBiome(player,biome),"Fixture initial biome failed");
        if(family>0)Require(MarkerStore.TryEnableProtection(player,biome,family),"Fixture protection failed");
    }
    private static void NoMovement(World world)
    {
        Require(At(world.Player.Position,Original)&&world.Player.Positions.Count==0,
            "Ineligible path changed the player's original position");
        Require(world.Player.ChunkObserver.Positions.Count==0&&Get<PendingPlacement>("pending")==null,
            "Ineligible path moved an observer or began a placement");
        Require(PlacedPoiResolver.SelectCalls==0,"Ineligible path selected a new location");
    }
    private static void StandardBypass()
    {
        var world=Begin();Policy("Standard");Spawn();Update(0);NoMovement(world);
        Require(Result()=="BYPASSED/STANDARD_BYPASS"&&MarkerStore.Read(world.Player)==MarkerState.Absent,
            "Standard consumed a character's one-time marker");
    }
    private static void SpawnEnvironment(string context)
    {
        var world=Begin();string reason="EXECUTION_REJECTED",outcome="REJECTED";
        if(context=="eac"){GamePrefs.EACEnabled=true;reason="RUNTIME_LANE_UNCONFIRMED";outcome="INCOMPATIBLE";}
        if(context=="multiplayer")ConnectionManager.Instance.IsSinglePlayer=false;
        if(context=="dedicated")GameManager.IsDedicatedServer=true;
        if(context=="notserver"){ConnectionManager.Instance.IsServer=false;reason="NOT_SERVER";}
        if(context=="noconnection")ConnectionManager.Instance=null;
        if(context=="build"){CompatibilityGuard.Compatible=false;reason="BUILD_MISMATCH";outcome="INCOMPATIBLE";}
        if(context=="case"){GamePrefs.GameName="target game";reason="GAME_NAME_MISMATCH";}
        Spawn(RespawnType.NewGame,context!="remote");NoMovement(world);
        Require(MarkerStore.Read(world.Player)==MarkerState.Absent&&Result()==outcome+"/"+reason,
            "Rejected runtime environment reserved the character or reported the wrong outcome: "+Result());
    }
    private static void CompletedReturn(bool changedPreference)
    {
        var world=Begin();Policy("RandomSafe");Spawn();Finish();
        Require(MarkerStore.Read(world.Player)==MarkerState.Completed&&MarkerStore.ReadProtectionFamily(world.Player)==8,
            "Completed source path did not persist the initial protection marker");
        var position=world.Player.Position;int movements=world.Player.Positions.Count,draws=PlacedPoiResolver.SelectCalls;
        ResetTransientSession(world.Player);
        Policy("RandomSafe",changedPreference ? new BiomePreference("Chosen",5,new int[5]) : BiomePreference.Any);
        Spawn(RespawnType.LoadedGame);Update(1);
        Require(At(world.Player.Position,position)&&world.Player.Positions.Count==movements&&PlacedPoiResolver.SelectCalls==draws,
            "Completed return or changed preference relocated the character");
        Require(MarkerStore.ReadInitialBiome(world.Player)==1&&MarkerStore.ReadProtectionFamily(world.Player)==8,
            "Completed return replaced the stored initial biome/protection family");
        Require(Get<int>("protectedEntityId")==1&&Result()=="COMPLETED/RELOCATION_COMPLETED",
            "Completed return did not reactivate protection through the loaded callback");
        Consumed(world);
    }
    private static void LoadedMarker(string state)
    {
        var world=Begin();world.Player.Buffs.AddCustomVar(MarkerStore.Name,state=="reserved" ? 1 : 99);
        Spawn(RespawnType.LoadedGame);Update(1);NoMovement(world);
        Require(Result()==(state=="reserved" ? "RESERVED/PLACEMENT_DEFERRED" : "FAILED/MARKER_INVALID"),
            "Reserved/invalid reload restarted the one-time placement: "+Result());
        Require(world.Player.Buffs.GetCustomVar(MarkerStore.Name)==(state=="reserved" ? 1 : 99),
            "Reserved/invalid reload changed its stored marker");
    }
    private static string[] HazardNames(string prefix)=>new[] {"buff"+prefix+"_Hazard","buff"+prefix+"_Hazard_Over",
        "buff"+prefix+"_Hazard_Recover","buff"+prefix+"_Hazard01","buff"+prefix+"_Hazard02"};
    private static void ProtectionReturn(int biome,int family,string prefix,bool enabled)
    {
        var world=Begin();Policy(enabled ? "RandomSafe" : "Random");CompletedMarker(world.Player,biome,family);
        var names=HazardNames(prefix);
        foreach(string name in names)world.Player.Buffs.ActiveBuffs.Add(new BuffValue {buffName=name});
        string other=prefix=="Desert" ? "buffSnow_Hazard" : "buffDesert_Hazard";
        world.Player.Buffs.ActiveBuffs.Add(new BuffValue {buffName=other});
        world.Player.Buffs.ActiveBuffs.Add(new BuffValue {buffName="buffInjuryBleeding"});
        world.Player.Buffs.AddCustomVar("$"+prefix+"HazardTimer",2);
        world.Player.Buffs.AddCustomVar("$"+prefix+"HazardTimerMax",30);
        Spawn(RespawnType.LoadedGame);Update(1);NoMovement(world);
        Require(names.All(name=>world.Player.Buffs.HasBuff(name)==!enabled),"Protection did not preserve its requested enabled/disabled boundary");
        Require(world.Player.Buffs.HasBuff(other)&&world.Player.Buffs.HasBuff("buffInjuryBleeding"),
            "Stored-family protection removed an unrelated hazard or injury");
        Require(world.Player.Buffs.GetCustomVar("$"+prefix+"HazardTimer")== (enabled ? 30 : 2),
            "Stored-family protection did not maintain the intended timer boundary");
        Require(MarkerStore.ReadProtectionFamily(world.Player)==family&&MarkerStore.ReadInitialBiome(world.Player)==biome,
            "Return changed the stored family/biome instead of maintaining it");
    }
    private static void TraderPreflight(string transition)
    {
        var world=Begin();PlacedTraderResolver.Status=transition=="empty" ? TraderIndexStatus.Empty : TraderIndexStatus.Unavailable;
        Spawn();Require(world.Player.Positions.Count==0&&MarkerStore.Read(world.Player)==MarkerState.Absent,
            "Trader preflight moved or reserved before metadata qualification");
        if(transition=="empty")
        {
            Require(Result()=="REJECTED/TRADER_POOL_EMPTY","Empty trader preflight did not reject");Consumed(world);return;
        }
        Require(Get<World>("traderPreflightWorld")==world&&SanitizedRuntimeLog.Entries.Contains("TRADER_METADATA_WAIT"),
            "Unavailable metadata did not start the bounded preflight wait");
        Update(9);Require(MarkerStore.Read(world.Player)==MarkerState.Absent&&Get<World>("traderPreflightWorld")==world,
            "Trader wait consumed a marker or timed out before its deadline");
        if(transition=="ready")PlacedTraderResolver.Status=TraderIndexStatus.Ready;
        if(transition=="becomesempty")PlacedTraderResolver.Status=TraderIndexStatus.Empty;
        if(transition=="name")GamePrefs.GameName="Other Game";
        Update(10);
        Require(Get<World>("traderPreflightWorld")==null,"Trader preflight stayed active after a terminal transition");
        if(transition=="ready")
        {
            Finish();Require(Result()=="COMPLETED/RELOCATION_COMPLETED"&&MarkerStore.Read(world.Player)==MarkerState.Completed,
                "Recovered trader metadata did not continue the qualified placement");
            Require(PlacedPoiResolver.SelectCalls==1,"Trader metadata wait redrew the biome/location pool");
        }
        else
        {
            Require(At(world.Player.Position,Original)&&world.Player.Positions.Count==0&&MarkerStore.Read(world.Player)==MarkerState.Absent,
                "Failed trader preflight changed the original start");
            Require(Result()=="REJECTED/"+(transition=="becomesempty" ? "TRADER_POOL_EMPTY" : "TRADER_METADATA_UNAVAILABLE"),
                "Trader preflight failure was attributed incorrectly: "+Result());
        }
        Consumed(world);
    }
    private static (Quest Quest,ObjectiveGoto Objective) TraderQuest()
    {
        var objective=new ObjectiveGoto {biomeFilterType=BiomeFilterTypes.OnlyBiome,biomeFilter="pine_forest",positionSet=true};
        var quest=new Quest {ID="quest_whiteRiverCitizen1"};quest.Objectives.Add(objective);return (quest,objective);
    }
    private static void TraderReturn(string transition)
    {
        var world=Begin();CompletedMarker(world.Player);Require(MarkerStore.TryBeginTraderRoute(world.Player),"Fixture pending route failed");
        var pair=TraderQuest();world.Player.QuestJournal.quests.Add(pair.Quest);
        if(transition=="failure")ObjectiveGoto.LocationWorks=false;
        if(transition=="wait")PlacedTraderResolver.SelectionAvailable=false;
        if(transition=="crossed")PlacedTraderResolver.CrossedBiome=true;
        Spawn(RespawnType.LoadedGame);NoMovement(world);
        if(transition=="failure")
        {
            Require(MarkerStore.ReadTraderRoute(world.Player)==TraderRouteState.Reserved&&pair.Objective.LocationCalls==1,
                "Failed destination did not retain the reserved route");
            Require(pair.Objective.biomeFilterType==BiomeFilterTypes.OnlyBiome&&pair.Objective.biomeFilter=="pine_forest"&&pair.Objective.positionSet,
                "Failed destination changed the vanilla objective fields");
            Require(world.Player.QuestJournal.RefreshCalls==0,"Failed destination was acknowledged to the journal");
            ObjectiveGoto.LocationWorks=true;world.Player.Accept(pair.Quest);
        }
        if(transition=="wait")
        {
            Require(MarkerStore.ReadTraderRoute(world.Player)==TraderRouteState.Pending&&pair.Objective.LocationCalls==0,
                "Unavailable trader selection reserved or edited an objective");
            PlacedTraderResolver.SelectionAvailable=true;world.Player.Accept(pair.Quest);
        }
        Require(MarkerStore.ReadTraderRoute(world.Player)==TraderRouteState.Completed&&pair.Objective.positionSet&&
            pair.Objective.biomeFilterType==BiomeFilterTypes.AnyBiome&&pair.Objective.biomeFilter==string.Empty,
            "Journal/pending return failed to complete the assigned route");
        Require(At(pair.Objective.LastLocation,PlacedTraderResolver.Selected.Location)&&At(pair.Objective.LastSize,PlacedTraderResolver.Selected.Size),
            "The assigned destination was not the selected placed trader");
        Require(world.Player.QuestJournal.RefreshCalls==1,"Successful assignment did not acknowledge exactly once");
        Require(SanitizedRuntimeLog.Entries.Contains(transition=="crossed" ? "TRADER_ROUTE_CROSS_BIOME" : "TRADER_ROUTE_SAME_BIOME"),
            "Trader biome disposition was not recorded");
        int calls=pair.Objective.LocationCalls,draws=PlacedTraderResolver.SelectCalls;
        world.Player.Accept(pair.Quest);Update(30);
        Require(pair.Objective.LocationCalls==calls&&PlacedTraderResolver.SelectCalls==draws&&world.Player.QuestJournal.RefreshCalls==1,
            "Completed route assigned or refreshed twice");
    }
    private static void WrongNameCompletedRoute()
    {
        var world=Begin();CompletedMarker(world.Player);Require(MarkerStore.TryBeginTraderRoute(world.Player),"Fixture pending route failed");
        var pair=TraderQuest();world.Player.QuestJournal.quests.Add(pair.Quest);GamePrefs.GameName="Other Game";
        Spawn(RespawnType.LoadedGame);Update(30);NoMovement(world);
        Require(Result()=="REJECTED/GAME_NAME_MISMATCH"&&MarkerStore.ReadTraderRoute(world.Player)==TraderRouteState.Pending,
            "Wrong-name completed return changed its pending route");
        Require(PlacedTraderResolver.SelectCalls==0&&pair.Objective.LocationCalls==0&&world.Player.QuestJournal.RefreshCalls==0,
            "Wrong-name completed return changed a quest destination");
    }
    private static void IntroShape(string shape,int biome=1,string expected="snow")
    {
        var world=Begin();CompletedMarker(world.Player,biome);
        Require(MarkerStore.TryBeginTraderRoute(world.Player)&&MarkerStore.TryReserveTraderRoute(world.Player)&&MarkerStore.TryCompleteTraderRoute(world.Player),
            "Fixture completed trader route failed");
        var objective=new ObjectiveRandomGotoNPC {biomeFilterType=BiomeFilterTypes.OnlyBiome,biomeFilter="pine_forest"};
        var quest=new Quest {ID="intro_buried_supplies"};quest.Objectives.Add(objective);
        if(shape=="ambiguous")quest.Objectives.Add(new ObjectiveRandomGotoNPC {biomeFilterType=BiomeFilterTypes.OnlyBiome,biomeFilter="pine_forest"});
        if(shape=="positioned")objective.positionSet=true;
        if(shape=="phase")objective.Phase=2;
        if(shape=="quest")quest.ID="ordinary_trader_job";
        Call("IntroRouteSetupPositionPrefix",quest,world.Player);
        Require(objective.biomeFilter==(shape=="valid" ? expected : "pine_forest")&&objective.biomeFilterType==BiomeFilterTypes.OnlyBiome,
            "Intro routing changed a non-owned objective or chose the wrong initial biome");
        Require(objective.positionSet==(shape=="positioned"),"Intro routing changed position ownership");
        Require(world.Player.Positions.Count==0&&world.Player.QuestJournal.RefreshCalls==0,
            "Intro prefix moved the player or completed another quest stage");
    }
    private static void PlacementTimeout(bool chunks)
    {
        var world=Begin();if(chunks)world.ChunkReady=false;else world.Player.onGround=false;
        Spawn();Finish();
        Require(Result()=="FAILED/"+(chunks ? "VERIFY_CHUNK_TIMEOUT" : "VERIFY_POSITION_MISMATCH"),
            "Unqualified surface/chunk did not fail by the bounded verification deadline: "+Result());
        Require(At(world.Player.Position,Original)&&MarkerStore.Read(world.Player)==MarkerState.Reserved&&Get<PendingPlacement>("pending")==null,
            "Timed-out placement failed to recover its owned original start");Consumed(world);
    }
    public static int Main()
    {
        var scenarios=new (string Name,Action Run)[] {
            ("PostPlayerMoveFailure",()=>MovementFailure("player")),
            ("PostObserverMoveFailure",()=>MovementFailure("observer")),
            ("SemanticMismatchRecovery",()=>MovementFailure("semantic")),
            ("ValidFifthPlacementAndTrader",()=>Placement(true)),
            ("FiveUnsafePlacementsFallback",()=>Placement(false)),
            ("ChangedWorldRecoveryRejected",()=>WorldChanged(false)),
            ("DifferentWorldSameGuidRecoveryRejected",()=>WorldChanged(true)),
            ("ReplacementEntitySameIdRejected",EntityChanged),
            ("SameOwnerContextFailureRestores",SameOwnerContextFailure),
            ("ValidIntroQuestFilter",()=>QuestFilter("valid")),
            ("OtherGameIntroQuestUnchanged",()=>QuestFilter("name")),
            ("CaseMismatchIntroQuestUnchanged",()=>QuestFilter("case")),
            ("EacIntroQuestUnchanged",()=>QuestFilter("eac")),
            ("MultiplayerIntroQuestUnchanged",()=>QuestFilter("multiplayer")),
            ("DedicatedIntroQuestUnchanged",()=>QuestFilter("dedicated")),
            ("IncompatibleIntroQuestUnchanged",()=>QuestFilter("build")),
            ("UnmarkedIntroQuestUnchanged",()=>QuestFilter("unmarked")),
            ("OtherGameFirstSpawnRejected",()=>SpawnRejected(RespawnType.NewGame,true)),
            ("LoadedUnmarkedCharacterRejected",()=>SpawnRejected(RespawnType.LoadedGame,false)),
            ("NormalRespawnRejected",()=>SpawnRejected(RespawnType.Died,false)),
            ("StandardFreshStartBypasses",StandardBypass),
            ("EacFirstSpawnRejected",()=>SpawnEnvironment("eac")),
            ("MultiplayerFirstSpawnRejected",()=>SpawnEnvironment("multiplayer")),
            ("DedicatedFirstSpawnRejected",()=>SpawnEnvironment("dedicated")),
            ("ClientFirstSpawnRejected",()=>SpawnEnvironment("notserver")),
            ("MissingConnectionFirstSpawnRejected",()=>SpawnEnvironment("noconnection")),
            ("RemotePlayerFirstSpawnRejected",()=>SpawnEnvironment("remote")),
            ("IncompatibleFirstSpawnRejected",()=>SpawnEnvironment("build")),
            ("CaseMismatchFirstSpawnRejected",()=>SpawnEnvironment("case")),
            ("CompletedProtectedReturnDoesNotRelocate",()=>CompletedReturn(false)),
            ("ChangedPreferenceCompletedReturnDoesNotRelocate",()=>CompletedReturn(true)),
            ("ReservedReturnDoesNotRestart",()=>LoadedMarker("reserved")),
            ("InvalidMarkerReturnRejected",()=>LoadedMarker("invalid")),
            ("BurntStoredProtectionReturn",()=>ProtectionReturn(9,1,"Burnt",true)),
            ("DesertStoredProtectionReturn",()=>ProtectionReturn(5,2,"Desert",true)),
            ("WastelandStoredProtectionReturn",()=>ProtectionReturn(8,4,"Wasteland",true)),
            ("SnowStoredProtectionReturn",()=>ProtectionReturn(1,8,"Snow",true)),
            ("ExplicitProtectionOptOutReturn",()=>ProtectionReturn(8,4,"Wasteland",false)),
            ("EmptyTraderPreflightRejectsBeforeMovement",()=>TraderPreflight("empty")),
            ("DelayedReadyTraderPreflightCompletes",()=>TraderPreflight("ready")),
            ("TraderMetadataTimeoutKeepsNormalStart",()=>TraderPreflight("timeout")),
            ("TraderMetadataBecomesEmptyKeepsNormalStart",()=>TraderPreflight("becomesempty")),
            ("WrongNameDuringTraderPreflightKeepsNormalStart",()=>TraderPreflight("name")),
            ("LoadedPendingTraderJournalCompletesOnce",()=>TraderReturn("journal")),
            ("FailedTraderDestinationRestoresAndRetries",()=>TraderReturn("failure")),
            ("UnavailableTraderSelectionWaitsAndRetries",()=>TraderReturn("wait")),
            ("CrossBiomeTraderFallbackCompletes",()=>TraderReturn("crossed")),
            ("WrongNameCompletedPendingQuestUnchanged",WrongNameCompletedRoute),
            ("AmbiguousIntroObjectivesUnchanged",()=>IntroShape("ambiguous")),
            ("PositionedIntroObjectiveUnchanged",()=>IntroShape("positioned")),
            ("OtherPhaseIntroObjectiveUnchanged",()=>IntroShape("phase")),
            ("OrdinaryTraderJobUnchanged",()=>IntroShape("quest")),
            ("BurntInitialBiomeIntroFilter",()=>IntroShape("valid",9,"burnt_forest")),
            ("DesertInitialBiomeIntroFilter",()=>IntroShape("valid",5,"desert")),
            ("WastelandInitialBiomeIntroFilter",()=>IntroShape("valid",8,"wasteland")),
            ("ForestInitialBiomeIntroFilter",()=>IntroShape("valid",3,"pine_forest")),
            ("ChunkTimeoutRestoresOwnedStart",()=>PlacementTimeout(true)),
            ("UnstableSurfaceTimeoutRestoresOwnedStart",()=>PlacementTimeout(false))
        };
        int failures=0;
        foreach(var scenario in scenarios)
        {
            string error=null;try{scenario.Run();}catch(Exception caught){failures++;error=caught.Message;}
            Records.Add(new {scenario=scenario.Name,pass=error==null,error,result=Result(),
                logs=SanitizedRuntimeLog.Entries.ToArray()});
        }
        Console.WriteLine(JsonSerializer.Serialize(new {total=scenarios.Length,passed=scenarios.Length-failures,
            failed=failures,cases=Records},new JsonSerializerOptions {WriteIndented=true}));
        return failures==0?0:1;
    }
}
