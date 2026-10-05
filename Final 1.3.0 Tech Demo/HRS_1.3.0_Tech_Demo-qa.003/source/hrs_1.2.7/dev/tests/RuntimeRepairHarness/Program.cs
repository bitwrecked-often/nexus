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
    private static void Spawn(RespawnType type=RespawnType.NewGame)=>Call("OnPlayerSpawned",
        new ModEvents.SPlayerSpawnedInWorldData {RespawnType=type,EntityId=1,IsLocalPlayer=true});
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
            ("NormalRespawnRejected",()=>SpawnRejected(RespawnType.Died,false))
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
