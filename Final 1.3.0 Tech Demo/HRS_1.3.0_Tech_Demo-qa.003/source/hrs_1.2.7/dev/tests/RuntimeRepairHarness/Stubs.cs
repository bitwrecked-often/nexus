using System;
using System.Collections.Generic;

// Controlled engine/resolver seams only. The project links the actual runtime
// callbacks, environment guard, markers, semantic snapshot and policy/result code.
namespace UnityEngine
{
    public struct Vector3
    {
        public float x, y, z;
        public Vector3(float x, float y, float z) { this.x=x; this.y=y; this.z=z; }
        public static Vector3 up => new Vector3(0,1,0);
        public static Vector3 zero => new Vector3(0,0,0);
        public static Vector3 operator +(Vector3 a, Vector3 b) => new Vector3(a.x+b.x,a.y+b.y,a.z+b.z);
        public static Vector3 operator *(Vector3 a, float b) => new Vector3(a.x*b,a.y*b,a.z*b);
    }
    public struct Vector2 { public float x,y; }
    public static class Time { public static float realtimeSinceStartup; }
}
namespace HarmonyLib
{
    public sealed class Harmony
    {
        public Harmony(string id) { }
        public void Patch(System.Reflection.MethodBase original, HarmonyMethod prefix,
            object postfix, object transpiler, object finalizer, object ilmanipulator) { }
    }
    public sealed class HarmonyMethod { public HarmonyMethod(System.Reflection.MethodInfo method) { } }
}
public interface IModApi { void InitMod(Mod instance); }
public sealed class Mod { }
public enum RespawnType { NewGame, LoadedGame, Died }
public enum BiomeFilterTypes { AnyBiome, OnlyBiome }
public enum EnumGamePrefs { GameName, GameWorld, EACEnabled }
public static class GamePrefs
{
    public static string GameName="Target Game";
    public static bool EACEnabled;
    public static string GetString(EnumGamePrefs pref) => pref==EnumGamePrefs.GameName ? GameName : "Navezgane";
    public static bool GetBool(EnumGamePrefs pref) => EACEnabled;
}
public sealed class ConnectionManager
{
    public static ConnectionManager Instance=new ConnectionManager();
    public bool IsServer=true, IsSinglePlayer=true;
}
public sealed class EntityNPC { }
public sealed class Quest
{
    public string ID;
    public bool Active=true;
    public int CurrentPhase=1, CurrentState, ActiveObjectives;
    public bool OptionalComplete;
    public readonly List<object> Objectives=new List<object>();
    public void SetupPosition(EntityNPC npc,EntityPlayer player,List<UnityEngine.Vector2> points,int phase) { }
}
public sealed class ObjectiveGoto
{
    public static bool LocationWorks=true;
    public int Phase=1;
    public string ID="trader";
    public BiomeFilterTypes biomeFilterType;
    public string biomeFilter;
    public bool positionSet;
    public bool SetLocation(UnityEngine.Vector3 location,UnityEngine.Vector3 size) => LocationWorks;
}
public sealed class ObjectiveRandomGotoNPC
{
    public int Phase=1;
    public bool positionSet;
    public BiomeFilterTypes biomeFilterType;
    public string biomeFilter;
}
public sealed class QuestJournal
{
    public EntityPlayer OwnerPlayer;
    public readonly List<Quest> quests=new List<Quest>();
    public void RefreshQuest(Quest quest) { }
}
public sealed class BuffValue { public string buffName; public float stackEffectMultiplier; public int buffFlags; }
public sealed class EntityBuffs
{
    private readonly Dictionary<string,float> variables=new Dictionary<string,float>();
    public readonly List<BuffValue> ActiveBuffs=new List<BuffValue>();
    public bool HasBuff(string name) => ActiveBuffs.Exists(value=>value.buffName==name);
    public void RemoveBuff(string name,int count,bool force) => ActiveBuffs.RemoveAll(value=>value.buffName==name);
    public bool HasCustomVar(string name) => variables.ContainsKey(name);
    public float GetCustomVar(string name) => variables.TryGetValue(name,out var value) ? value : 0;
    public void AddCustomVar(string name,float value) => variables[name]=value;
}
public sealed class StatValue { public float Value=100; }
public sealed class EntityStats { public StatValue Health=new StatValue(),Stamina=new StatValue(),Food=new StatValue(),Water=new StatValue(); }
public sealed class Progression { public int Level=1,ExpToNextLevel,ExpDeficit,SkillPoints; public static float XPGain=1; }
public sealed class ItemValue
{
    public int type,Meta,Quality,SelectedAmmoTypeIndex;
    public float UseTimes;
    public bool Activated;
    public ItemValue[] modifications,cosmeticMods;
}
public sealed class ItemStack { public int count; public ItemValue itemValue; }
public sealed class ItemStackGrid
{
    public int Length=>0;
    public ItemStack GetItem(int index)=>null;
}
public sealed class ItemContainer { public ItemStackGrid ItemGrid=new ItemStackGrid(); }
public sealed class EntityPlayer
{
    public int entityId=1,Health=100,gameStage=1;
    public UnityEngine.Vector3 Position;
    public bool onGround=true;
    public readonly List<UnityEngine.Vector3> Positions=new List<UnityEngine.Vector3>();
    public readonly List<float> PositionTimes=new List<float>();
    public readonly ChunkManager.ChunkObserver ChunkObserver=new ChunkManager.ChunkObserver();
    public readonly EntityBuffs Buffs=new EntityBuffs();
    public readonly QuestJournal QuestJournal=new QuestJournal();
    public readonly EntityStats Stats=new EntityStats();
    public readonly Progression Progression=new Progression();
    public readonly ItemContainer inventory=new ItemContainer(),bag=new ItemContainer();
    public bool ThrowAfterMoveOnce,ChangeHealthAfterMoveOnce;
    public event Action<Quest> QuestAccepted;
    public UnityEngine.Vector3 GetPosition()=>Position;
    public void SetPosition(UnityEngine.Vector3 value,bool update)
    {
        Position=value; Positions.Add(value); PositionTimes.Add(UnityEngine.Time.realtimeSinceStartup);
        if(ChangeHealthAfterMoveOnce) { ChangeHealthAfterMoveOnce=false; Health--; }
        if(ThrowAfterMoveOnce) { ThrowAfterMoveOnce=false; throw new InvalidOperationException("Injected after player movement"); }
    }
    public void Accept(Quest quest)=>QuestAccepted?.Invoke(quest);
}
public sealed class ChunkManager
{
    public sealed class ChunkObserver
    {
        public readonly List<UnityEngine.Vector3> Positions=new List<UnityEngine.Vector3>();
        public bool ThrowAfterMoveOnce;
        public void SetPosition(UnityEngine.Vector3 value)
        {
            Positions.Add(value);
            if(ThrowAfterMoveOnce) { ThrowAfterMoveOnce=false; throw new InvalidOperationException("Injected after observer movement"); }
        }
    }
}
public struct Vector3i { public int x,y,z; public Vector3i(int x,int y,int z){this.x=x;this.y=y;this.z=z;} }
public sealed class GameRandom { public int RandomRange(int count)=>0; }
public sealed class World
{
    public string Guid="fixture-world";
    public EntityPlayer Player=new EntityPlayer();
    public bool ChunkReady=true;
    public object GetEntity(int id)=>id==Player.entityId ? Player : null;
    public bool IsPositionInBounds(UnityEngine.Vector3 point)=>true;
    public object GetChunkFromWorldPos(Vector3i point)=>ChunkReady ? new object() : null;
    public float GetTerrainHeight(int x,int z)=>20;
    public bool CanPlayersSpawnAtPos(UnityEngine.Vector3 point,bool value)=>true;
    public GameRandom GetGameRandom()=>new GameRandom();
    public static Vector3i worldToBlockPos(UnityEngine.Vector3 point)=>new Vector3i((int)point.x,(int)point.y,(int)point.z);
}
public sealed class GameManager
{
    public static GameManager Instance=new GameManager();
    public static bool IsDedicatedServer;
    public World World=new World();
}
public static class ModEvents
{
    public struct SPlayerSpawnedInWorldData { public RespawnType RespawnType; public int EntityId; public bool IsLocalPlayer; }
    public struct SGameUpdateData { }
    public delegate void SpawnHandler(ref SPlayerSpawnedInWorldData data);
    public delegate void UpdateHandler(ref SGameUpdateData data);
    public static class PlayerSpawnedInWorld { public static void RegisterHandler(SpawnHandler handler) { } }
    public static class GameUpdate { public static void RegisterHandler(UpdateHandler handler) { } }
}
namespace BitWrecked.HistoricalRandomStart
{
    internal sealed class OwnedBridgePaths
    {
        internal string PolicyPath;
        internal static bool TryResolve(out OwnedBridgePaths paths) {paths=new OwnedBridgePaths();return true;}
    }
    internal sealed class AtomicResultWriter
    {
        internal static ResultV1 Last;
        internal static int Writes;
        internal AtomicResultWriter(OwnedBridgePaths paths) { }
        internal bool TryWrite(ResultV1 result) {Last=result;Writes++;return true;}
    }
    internal static class CompatibilityGuard
    {
        internal static bool Compatible=true;
        internal static bool IsKnownBuild()=>true;
        internal static bool IsCompatible()=>Compatible;
    }
    internal sealed class SanitizedRuntimeLog
    {
        internal static readonly List<string> Entries=new List<string>();
        internal void Write(string value)=>Entries.Add(value);
        internal void WritePoiAttempt(ResolvedPoi poi,int number)=>Entries.Add("POI_ATTEMPT:"+number+":"+poi.InstanceId);
        internal void WritePoiCompleted(ResolvedPoi poi,int number,UnityEngine.Vector3 position)=>Entries.Add("POI_COMPLETED:"+number);
        internal void WriteBiomeSelection(BiomePreference preference,string eligible,int biome,string reason)=>Entries.Add(reason);
        internal void WriteTraderSelection(PlacedTrader trader,bool crossed)=>Entries.Add("TRADER_SELECTED");
    }
    internal sealed class ResolvedPoi
    {
        internal World WorldRef;
        internal int InstanceId,BiomeId;
        internal bool Safe;
        internal UnityEngine.Vector3 Approach;
    }
    internal sealed class PoiSelection
    {
        private readonly List<ResolvedPoi> pois;
        private int cursor=1;
        internal readonly int TargetBiomeId;
        internal PoiSelection(List<ResolvedPoi> values){pois=values;TargetBiomeId=values.Count==0?0:values[0].BiomeId;}
        internal bool TryNext(out ResolvedPoi next)
        {next=cursor<pois.Count ? pois[cursor++] : null;return next!=null;}
    }
    internal static class PlacedPoiResolver
    {
        internal static readonly List<ResolvedPoi> Pool=new List<ResolvedPoi>();
        internal static int SelectCalls;
        internal static bool TrySelect(World world,BiomePreference preference,out PoiSelection selection,
            out ResolvedPoi selected,out string reason,out string eligible)
        {SelectCalls++;selection=new PoiSelection(Pool);selected=Pool.Count==0 ? null : Pool[0];reason="BIOME_SELECTED";eligible="1";return selected!=null;}
        internal static bool TryFindSafeLanding(World world,ResolvedPoi poi,out UnityEngine.Vector3 landing)
        {landing=new UnityEngine.Vector3(poi.Approach.x,21,poi.Approach.z);return poi.Safe;}
        internal static bool TryResolveBiome(World world,UnityEngine.Vector3 position,out int biome,out int family)
        {biome=1;family=8;return true;}
    }
    internal enum TraderIndexStatus {Ready,Empty,Unavailable}
    internal sealed class PlacedTrader {internal UnityEngine.Vector3 Location,Size;}
    internal static class PlacedTraderResolver
    {
        internal static TraderIndexStatus GetStatus(World world)=>TraderIndexStatus.Ready;
        internal static bool TrySelect(World world,UnityEngine.Vector3 position,int initialBiome,out PlacedTrader trader,out bool crossed)
        {trader=new PlacedTrader();crossed=false;return true;}
    }
}
