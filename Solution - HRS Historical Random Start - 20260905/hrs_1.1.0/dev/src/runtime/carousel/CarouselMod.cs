using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using UnityEngine;

namespace BitWrecked.HistoricalRandomStart.QaCarousel
{
    public sealed class CarouselModApi : IModApi
    {
        private static CarouselRun run;
        private static bool initialized;

        public void InitMod(Mod modInstance)
        {
            if (initialized) return;
            initialized = true;
            if (!CompatibilityGuard.IsCompatible())
            {
                Log.Error("[HRS-CAROUSEL] stage=INIT reason=BUILD_MISMATCH");
                return;
            }
            ModEvents.PlayerSpawnedInWorld.RegisterHandler(OnPlayerSpawned);
            ModEvents.GameUpdate.RegisterHandler(OnGameUpdate);
            Log.Out("[HRS-CAROUSEL] stage=INIT reason=READY");
        }

        private static void OnPlayerSpawned(
            ref ModEvents.SPlayerSpawnedInWorldData data)
        {
            if (run != null || data.RespawnType != RespawnType.LoadedGame ||
                !data.IsLocalPlayer) return;
            try
            {
                CarouselPaths paths;
                CarouselArm arm;
                if (!CarouselPaths.TryResolve(out paths) ||
                    !CarouselArm.TryRead(paths.ArmPath, out arm)) return;
                if (!EnvironmentGuard.IsApproved(arm.GameName))
                {
                    CarouselResult.Write(paths, arm, "FAILED", "NONE", 0,
                        "ENVIRONMENT_REJECTED", Vector3.zero);
                    return;
                }
                World world = GameManager.Instance.World;
                EntityPlayer player = world.GetEntity(data.EntityId) as EntityPlayer;
                if (player == null || player.ChunkObserver == null)
                {
                    CarouselResult.Write(paths, arm, "FAILED", "NONE", 0,
                        "PLAYER_UNAVAILABLE", Vector3.zero);
                    return;
                }
                if (!CarouselArm.TryConsume(paths))
                {
                    CarouselResult.Write(paths, arm, "FAILED", "NONE", 0,
                        "ARM_CONSUME_FAILED", player.GetPosition());
                    return;
                }
                run = new CarouselRun(paths, arm, world, player);
                run.Begin();
            }
            catch
            {
                Log.Error("[HRS-CAROUSEL] stage=START reason=INTERNAL_FAILURE");
            }
        }

        private static void OnGameUpdate(ref ModEvents.SGameUpdateData data)
        {
            if (run == null) return;
            try
            {
                if (run.Tick()) run = null;
            }
            catch
            {
                run.Fail("INTERNAL_FAILURE");
                run = null;
            }
        }
    }

    internal static class CompatibilityGuard
    {
        private static readonly Guid ExpectedAssemblyCSharpMvid =
            new Guid("229796d0-95ca-4662-b426-1a6f1f1596ed");

        internal static bool IsCompatible()
        {
            return typeof(IModApi).Assembly.ManifestModule.ModuleVersionId ==
                ExpectedAssemblyCSharpMvid;
        }
    }

    internal static class EnvironmentGuard
    {
        internal static bool IsApproved(string gameName)
        {
            return CompatibilityGuard.IsCompatible() &&
                !GamePrefs.GetBool(EnumGamePrefs.EACEnabled) &&
                !GameManager.IsDedicatedServer &&
                ConnectionManager.Instance != null &&
                ConnectionManager.Instance.IsServer &&
                ConnectionManager.Instance.IsSinglePlayer &&
                GameManager.Instance != null &&
                GameManager.Instance.World != null &&
                string.Equals(GamePrefs.GetString(EnumGamePrefs.GameWorld),
                    "Navezgane", StringComparison.Ordinal) &&
                string.Equals(GamePrefs.GetString(EnumGamePrefs.GameName),
                    gameName, StringComparison.Ordinal);
        }
    }

    internal sealed class CarouselPoint
    {
        internal CarouselPoint(string id, string label, int x, int y, int z)
        {
            Id = id; Label = label; X = x; Y = y; Z = z;
        }
        internal string Id { get; private set; }
        internal string Label { get; private set; }
        internal int X { get; private set; }
        internal int Y { get; private set; }
        internal int Z { get; private set; }
    }

    internal static class CarouselCatalog
    {
        private const int CoordinateLimit = 2600;
        private const int SearchRadius = 32;
        private const int SearchStep = 4;
        private const int MaximumTerrainDelta = 24;
        private static readonly CarouselPoint[] Points =
            GeneratedCarouselCatalog.Create();

        internal static int Count { get { return Points.Length; } }
        internal static CarouselPoint Get(int index) { return Points[index]; }

        internal static bool TryResolve(World world, CarouselPoint point,
            out Vector3 anchor)
        {
            anchor = Vector3.zero;
            if (world == null || point == null || Math.Abs(point.X) > CoordinateLimit ||
                Math.Abs(point.Z) > CoordinateLimit) return false;
            anchor = new Vector3(point.X, point.Y + 1f, point.Z);
            return world.IsPositionInBounds(anchor);
        }

        internal static bool TryFindSafeLanding(World world, Vector3 anchor,
            CarouselPoint point, out Vector3 landing)
        {
            int limit = string.Equals(point.Id, "NG01", StringComparison.Ordinal)
                ? 8 : SearchRadius;
            landing = Vector3.zero;
            for (int radius = 0; radius <= limit; radius += SearchStep)
            {
                if (radius == 0)
                {
                    if (TryOffset(world, point, anchor, 0, 0, out landing)) return true;
                    continue;
                }
                for (int delta = -radius; delta <= radius; delta += SearchStep)
                {
                    if (TryOffset(world, point, anchor, delta, -radius, out landing)) return true;
                    if (TryOffset(world, point, anchor, delta, radius, out landing)) return true;
                }
                for (int delta = -radius + SearchStep;
                    delta <= radius - SearchStep; delta += SearchStep)
                {
                    if (TryOffset(world, point, anchor, -radius, delta, out landing)) return true;
                    if (TryOffset(world, point, anchor, radius, delta, out landing)) return true;
                }
            }
            return false;
        }

        private static bool TryOffset(World world, CarouselPoint point,
            Vector3 anchor, int dx, int dz, out Vector3 candidate)
        {
            int x = (int)anchor.x + dx;
            int z = (int)anchor.z + dz;
            float terrainY = world.GetTerrainHeight(x, z);
            candidate = new Vector3(x, terrainY + 1f, z);
            if (Math.Abs(terrainY - point.Y) > MaximumTerrainDelta) return false;
            if (!world.IsPositionInBounds(candidate)) return false;
            if (world.GetChunkFromWorldPos(World.worldToBlockPos(candidate)) == null)
                return false;
            return world.CanPlayersSpawnAtPos(candidate, false);
        }
    }

    internal enum CarouselStage
    {
        StartDelay,
        LoadAnchor,
        PrimeDelay,
        ResolveLanding,
        Settle,
        Dwell,
        Restore
    }

    internal sealed class CarouselRun
    {
        private const float StartDelaySeconds = 30f;
        private const float ChunkTimeoutSeconds = 15f;
        private const float PrimeDelaySeconds = 2f;
        private const float SecondLandingLift = 2f;
        private const float SettleTimeoutSeconds = 15f;
        private const float RestoreTimeoutSeconds = 10f;
        private const float DwellGroundGraceSeconds = 2f;
        private const float PositionTolerance = 3f;
        private const float SettledHeightTolerance = 3f;
        private const int StableSamplesRequired = 3;
        private readonly CarouselPaths paths;
        private readonly CarouselArm arm;
        private readonly World world;
        private readonly int entityId;
        private readonly string worldGuid;
        private readonly Vector3 origin;
        private readonly float initialHealth;
        private CarouselStage stage;
        private CarouselPoint point;
        private Vector3 anchor;
        private Vector3 landing;
        private float deadline;
        private float dwellGroundDeadline;
        private float baselineHealth;
        private int stableSamples;
        private int pointIndex;
        private int passed;
        private string finalStatus;
        private string finalReason;

        internal CarouselRun(CarouselPaths paths, CarouselArm arm, World world,
            EntityPlayer player)
        {
            this.paths = paths; this.arm = arm; this.world = world;
            entityId = player.entityId; worldGuid = world.Guid;
            origin = player.GetPosition();
            initialHealth = player.Health;
            pointIndex = arm.StartIndex;
        }

        internal void Begin()
        {
            stage = CarouselStage.StartDelay;
            deadline = Time.realtimeSinceStartup + StartDelaySeconds;
            CarouselLog.Event(paths, arm, "NONE", "RUN_START", Vector3.zero,
                origin, Health(), "OK");
        }

        internal bool Tick()
        {
            EntityPlayer player;
            if (!TryContext(out player)) return FinishFailure("CONTEXT_LOST");
            if (stage != CarouselStage.Restore && File.Exists(paths.StopPath))
                return FinishFailure("MANUAL_STOP");
            if (stage == CarouselStage.StartDelay)
            {
                if (Time.realtimeSinceStartup < deadline) return false;
                if (Health() + 0.001f < initialHealth ||
                    Vector3.Distance(player.GetPosition(), origin) > PositionTolerance)
                    return FinishFailure("PREFLIGHT_CHANGED");
                return BeginPoint(player);
            }
            if (stage == CarouselStage.LoadAnchor)
                return TickLoadAnchor(player);
            if (stage == CarouselStage.PrimeDelay)
                return TickPrimeDelay(player);
            if (stage == CarouselStage.ResolveLanding)
                return TickResolveLanding(player);
            if (stage == CarouselStage.Settle)
                return TickSettle(player);
            if (stage == CarouselStage.Dwell)
                return TickDwell(player);
            return TickRestore(player);
        }

        internal void Fail(string reason)
        {
            try
            {
                finalStatus = "FAILED"; finalReason = reason;
                EntityPlayer player;
                if (TryContext(out player)) SetPosition(player, origin);
                CarouselResult.Write(paths, arm, "FAILED", CurrentId(), passed,
                    reason, origin);
            }
            catch { Log.Error("[HRS-CAROUSEL] stage=FAIL reason=RESTORE_ERROR"); }
        }

        private bool BeginPoint(EntityPlayer player)
        {
            if (pointIndex > arm.EndIndex)
                return BeginRestore(player, "COMPLETED", "ALL_POINTS_PASSED");
            point = CarouselCatalog.Get(pointIndex);
            if (!CarouselCatalog.TryResolve(world, point, out anchor))
                return FinishFailure("ANCHOR_RESOLVE_FAILED");
            baselineHealth = Health();
            if (baselineHealth <= 0f) return FinishFailure("HEALTH_INVALID");
            CarouselLog.Event(paths, arm, point.Id, "POINT_BEGIN", anchor,
                player.GetPosition(), baselineHealth, "OK");
            SetPosition(player, anchor);
            stage = CarouselStage.LoadAnchor;
            deadline = Time.realtimeSinceStartup + ChunkTimeoutSeconds;
            return false;
        }

        private bool TickLoadAnchor(EntityPlayer player)
        {
            if (!Healthy(player)) return FinishFailure("HEALTH_FAILED");
            if (world.GetChunkFromWorldPos(World.worldToBlockPos(anchor)) == null)
            {
                if (Time.realtimeSinceStartup < deadline) return false;
                return FinishFailure("CHUNK_TIMEOUT");
            }
            stage = CarouselStage.PrimeDelay;
            deadline = Time.realtimeSinceStartup + PrimeDelaySeconds;
            CarouselLog.Event(paths, arm, point.Id, "CHUNK_PRIME_BEGIN", anchor,
                player.GetPosition(), Health(), "WAIT_2_SECONDS");
            return false;
        }

        private bool TickPrimeDelay(EntityPlayer player)
        {
            if (!Healthy(player)) return FinishFailure("HEALTH_FAILED");
            if (Time.realtimeSinceStartup < deadline) return false;
            if (world.GetChunkFromWorldPos(World.worldToBlockPos(anchor)) == null)
                return FinishFailure("CHUNK_LOST_AFTER_PRIME");
            stage = CarouselStage.ResolveLanding;
            return false;
        }

        private bool TickResolveLanding(EntityPlayer player)
        {
            if (!CarouselCatalog.TryFindSafeLanding(world, anchor, point,
                out landing)) return FinishFailure("SAFE_LANDING_FAILED");
            landing += Vector3.up * SecondLandingLift;
            SetPosition(player, landing);
            stableSamples = 0;
            stage = CarouselStage.Settle;
            deadline = Time.realtimeSinceStartup + SettleTimeoutSeconds;
            CarouselLog.Event(paths, arm, point.Id, "LANDING_SET", anchor,
                landing, Health(), "PRIMED_PLUS_2M");
            return false;
        }

        private bool TickSettle(EntityPlayer player)
        {
            if (!Healthy(player)) return FinishFailure("HEALTH_FAILED");
            Vector3 position = player.GetPosition();
            bool stable = player.onGround &&
                HorizontalDistance(position, landing) <= PositionTolerance &&
                Math.Abs(position.y - point.Y) <= SettledHeightTolerance;
            stableSamples = stable ? stableSamples + 1 : 0;
            if (stableSamples >= StableSamplesRequired)
            {
                landing = position;
                stage = CarouselStage.Dwell;
                deadline = Time.realtimeSinceStartup + arm.DwellSeconds;
                dwellGroundDeadline = deadline + DwellGroundGraceSeconds;
                stableSamples = 0;
                CarouselLog.Event(paths, arm, point.Id, "SURFACE_SETTLED", anchor,
                    landing, Health(), "ACTUAL_GROUNDED_SURFACE");
                CarouselLog.Event(paths, arm, point.Id, "DWELL_BEGIN", anchor,
                    landing, Health(), "OK");
                return false;
            }
            if (Time.realtimeSinceStartup < deadline) return false;
            return FinishFailure("SETTLE_FAILED");
        }

        private static float HorizontalDistance(Vector3 first, Vector3 second)
        {
            float dx = first.x - second.x;
            float dz = first.z - second.z;
            return (float)Math.Sqrt(dx * dx + dz * dz);
        }

        private bool TickDwell(EntityPlayer player)
        {
            if (!Healthy(player)) return FinishFailure("HEALTH_FAILED");
            if (!world.IsPositionInBounds(player.GetPosition()))
                return FinishFailure("POSITION_OUT_OF_BOUNDS");
            if (Vector3.Distance(player.GetPosition(), landing) > PositionTolerance)
                return FinishFailure("DWELL_POSITION_FAILED");
            stableSamples = player.onGround
                ? Math.Min(stableSamples + 1, StableSamplesRequired) : 0;
            if (Time.realtimeSinceStartup < deadline) return false;
            if (stableSamples < StableSamplesRequired)
            {
                if (Time.realtimeSinceStartup < dwellGroundDeadline) return false;
                return FinishFailure("DWELL_GROUND_FAILED");
            }
            passed++;
            CarouselLog.Event(paths, arm, point.Id, "POINT_PASS", anchor,
                player.GetPosition(), Health(), "OK");
            pointIndex++;
            return BeginPoint(player);
        }

        private bool BeginRestore(EntityPlayer player, string status, string reason)
        {
            finalStatus = status; finalReason = reason;
            SetPosition(player, origin);
            stage = CarouselStage.Restore;
            deadline = Time.realtimeSinceStartup + RestoreTimeoutSeconds;
            CarouselLog.Event(paths, arm, CurrentId(), "RESTORE_BEGIN",
                origin, player.GetPosition(), Health(), reason);
            return false;
        }

        private bool TickRestore(EntityPlayer player)
        {
            if (Vector3.Distance(player.GetPosition(), origin) <= PositionTolerance)
            {
                CarouselLog.Event(paths, arm, CurrentId(), "RUN_END", origin,
                    player.GetPosition(), Health(), finalReason);
                CarouselResult.Write(paths, arm, finalStatus, CurrentId(), passed,
                    finalReason, player.GetPosition());
                return true;
            }
            if (Time.realtimeSinceStartup < deadline) return false;
            CarouselResult.Write(paths, arm, "FAILED", CurrentId(), passed,
                "RESTORE_FAILED", player.GetPosition());
            return true;
        }

        private bool FinishFailure(string reason)
        {
            EntityPlayer player;
            if (!TryContext(out player))
            {
                CarouselResult.Write(paths, arm, "FAILED", CurrentId(), passed,
                    reason, origin);
                return true;
            }
            CarouselLog.Event(paths, arm, CurrentId(), "POINT_FAIL", anchor,
                player.GetPosition(), Health(), reason);
            return BeginRestore(player, "FAILED", reason);
        }

        private bool TryContext(out EntityPlayer player)
        {
            player = null;
            if (!EnvironmentGuard.IsApproved(arm.GameName) ||
                !string.Equals(world.Guid, worldGuid, StringComparison.Ordinal))
                return false;
            player = world.GetEntity(entityId) as EntityPlayer;
            return player != null && player.ChunkObserver != null;
        }

        private bool Healthy(EntityPlayer player)
        {
            float health = Health();
            return health > 0f && health + 0.001f >= baselineHealth;
        }

        private float Health()
        {
            EntityPlayer player = world.GetEntity(entityId) as EntityPlayer;
            return player == null ? 0f : player.Health;
        }

        private static void SetPosition(EntityPlayer player, Vector3 position)
        {
            player.SetPosition(position, true);
            player.ChunkObserver.SetPosition(position);
        }

        private string CurrentId()
        {
            return point == null ? "NONE" : point.Id;
        }
    }

    internal sealed class CarouselArm
    {
        internal string RunId { get; private set; }
        internal string GameName { get; private set; }
        internal int DwellSeconds { get; private set; }
        internal int StartIndex { get; private set; }
        internal int EndIndex { get; private set; }

        internal static bool TryRead(string path, out CarouselArm arm)
        {
            arm = null;
            try
            {
                if (!File.Exists(path) || new FileInfo(path).Length > 512) return false;
                string[] lines = File.ReadAllLines(path);
                if (lines.Length != 7 || lines[0] != "HRS-CAROUSEL-ARM-V2")
                    return false;
                string runId = Value(lines[1], "RUN=");
                string game = Value(lines[2], "GAME=");
                string dwellText = Value(lines[3], "DWELL_SECONDS=");
                string startText = Value(lines[4], "START_INDEX=");
                string endText = Value(lines[5], "END_INDEX=");
                string pointsText = Value(lines[6], "POINTS=");
                Guid parsed;
                int dwell;
                int start;
                int end;
                int points;
                if (!Guid.TryParseExact(runId, "N", out parsed) ||
                    !SafeToken(game, 64) || !int.TryParse(dwellText,
                    NumberStyles.None, CultureInfo.InvariantCulture, out dwell) ||
                    dwell < 5 || dwell > 300 || !int.TryParse(startText,
                    NumberStyles.None, CultureInfo.InvariantCulture, out start) ||
                    !int.TryParse(endText, NumberStyles.None,
                    CultureInfo.InvariantCulture, out end) ||
                    !int.TryParse(pointsText, NumberStyles.None,
                    CultureInfo.InvariantCulture, out points) ||
                    points != CarouselCatalog.Count || start < 0 ||
                    start >= CarouselCatalog.Count || end < start ||
                    end >= CarouselCatalog.Count) return false;
                arm = new CarouselArm
                {
                    RunId = runId, GameName = game, DwellSeconds = dwell,
                    StartIndex = start, EndIndex = end
                };
                return true;
            }
            catch { return false; }
        }

        internal static bool TryConsume(CarouselPaths paths)
        {
            try
            {
                if (File.Exists(paths.ConsumedPath)) return false;
                File.Move(paths.ArmPath, paths.ConsumedPath);
                return File.Exists(paths.ConsumedPath) && !File.Exists(paths.ArmPath);
            }
            catch { return false; }
        }

        private static string Value(string line, string prefix)
        {
            return line.StartsWith(prefix, StringComparison.Ordinal)
                ? line.Substring(prefix.Length) : null;
        }

        private static bool SafeToken(string value, int limit)
        {
            if (string.IsNullOrEmpty(value) || value.Length > limit) return false;
            for (int i = 0; i < value.Length; i++)
            {
                char c = value[i];
                if (!(char.IsLetterOrDigit(c) || c == '_' || c == '-')) return false;
            }
            return true;
        }
    }

    internal sealed class CarouselPaths
    {
        private const string Folder = "BitWrecked_HRS_QA_Carousel";
        private CarouselPaths(string root)
        {
            Root = root;
            Bridge = Path.Combine(root, "Bridge");
            ArmPath = Path.Combine(Bridge, "carousel.arm");
            ConsumedPath = Path.Combine(Bridge, "carousel.consumed");
            StopPath = Path.Combine(Bridge, "carousel.stop");
            EventsPath = Path.Combine(Bridge, "carousel-events.tsv");
            ResultPath = Path.Combine(Bridge, "carousel-result.v1.json");
        }
        internal string Root { get; private set; }
        internal string Bridge { get; private set; }
        internal string ArmPath { get; private set; }
        internal string ConsumedPath { get; private set; }
        internal string StopPath { get; private set; }
        internal string EventsPath { get; private set; }
        internal string ResultPath { get; private set; }

        internal static bool TryResolve(out CarouselPaths paths)
        {
            paths = null;
            try
            {
                string root = Path.GetFullPath(Path.GetDirectoryName(
                    typeof(CarouselModApi).Assembly.Location));
                if (!string.Equals(new DirectoryInfo(root).Name, Folder,
                    StringComparison.Ordinal)) return false;
                string expected = Path.GetFullPath(Path.Combine(
                    AppDomain.CurrentDomain.BaseDirectory, "Mods", Folder));
                if (!string.Equals(root.TrimEnd(Path.DirectorySeparatorChar),
                    expected.TrimEnd(Path.DirectorySeparatorChar),
                    StringComparison.OrdinalIgnoreCase)) return false;
                CarouselPaths candidate = new CarouselPaths(root);
                if (!Directory.Exists(candidate.Bridge)) return false;
                paths = candidate;
                return true;
            }
            catch { return false; }
        }
    }

    internal static class CarouselLog
    {
        internal static void Event(CarouselPaths paths, CarouselArm arm,
            string point, string stage, Vector3 requested, Vector3 actual,
            float health, string reason)
        {
            string line = string.Join("\t", new[]
            {
                DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture),
                arm.RunId, point, stage,
                F(requested.x), F(requested.y), F(requested.z),
                F(actual.x), F(actual.y), F(actual.z), F(health), reason
            });
            File.AppendAllText(paths.EventsPath, line + Environment.NewLine);
            Log.Out(string.Format(CultureInfo.InvariantCulture,
                "[HRS-CAROUSEL] run={0} point={1} stage={2} actual={3},{4},{5} health={6} reason={7}",
                arm.RunId, point, stage, F(actual.x), F(actual.y), F(actual.z),
                F(health), reason));
        }

        private static string F(float value)
        {
            return value.ToString("0.###", CultureInfo.InvariantCulture);
        }
    }

    internal static class CarouselResult
    {
        internal static void Write(CarouselPaths paths, CarouselArm arm,
            string status, string point, int passed, string reason, Vector3 position)
        {
            string json = string.Format(CultureInfo.InvariantCulture,
                "{{\n  \"schema\": \"hrs-carousel-result/v1\",\n  \"runId\": \"{0}\",\n  \"gameName\": \"{1}\",\n  \"status\": \"{2}\",\n  \"point\": \"{3}\",\n  \"passedPoints\": {4},\n  \"totalPoints\": {5},\n  \"reason\": \"{6}\",\n  \"position\": {{ \"x\": {7}, \"y\": {8}, \"z\": {9} }},\n  \"writtenUtc\": \"{10}\"\n}}\n",
                arm.RunId, arm.GameName, status, point, passed,
                arm.EndIndex - arm.StartIndex + 1, reason,
                position.x, position.y, position.z,
                DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture));
            string temp = paths.ResultPath + ".tmp";
            File.WriteAllText(temp, json);
            if (File.Exists(paths.ResultPath)) File.Delete(paths.ResultPath);
            File.Move(temp, paths.ResultPath);
        }
    }
}
