using System;
using System.Collections.Generic;
using System.Reflection;
using HarmonyLib;
using UnityEngine;

namespace BitWrecked.HistoricalRandomStart
{
    public sealed class HistoricalRandomStartModApi : IModApi
    {
        private const int FirstVerificationTick = 2;
        private const int RequiredStableVerificationSamples = 3;
        private const float VerificationWindowSeconds = 30f;
        private const float PrimeDelaySeconds = 2f;
        private const float SecondLandingLift = 2f;
        private const float HorizontalPositionTolerance = 3f;
        private const float SettledHeightTolerance = 3f;
        private static readonly SanitizedRuntimeLog RuntimeLog =
            new SanitizedRuntimeLog();
        private static PolicyV1 sessionPolicy;
        private static AtomicResultWriter resultWriter;
        private static PendingPlacement pending;
        private static bool sessionAttemptConsumed;
        private static int protectedEntityId = -1;
        private static int traderRouteEntityId = -1;
        private static EntityPlayer traderRoutePlayer;
        private static bool traderRouteSubscribed;
        private static int traderRouteObserveTicks;
        private static bool traderRouteJournalLogged;
        private static bool traderRouteQuestLogged;
        private static bool traderRouteWaitingLogged;
        private static bool initialized;

        public void InitMod(Mod modInstance)
        {
            if (initialized) return;
            initialized = true;

            OwnedBridgePaths paths;
            if (!OwnedBridgePaths.TryResolve(out paths))
            {
                RuntimeLog.Write("POLICY_REJECTED");
                return;
            }
            resultWriter = new AtomicResultWriter(paths);

            if (!CompatibilityGuard.IsCompatible())
            {
                Project(null, "INCOMPATIBLE", "BUILD_MISMATCH", "NOT_APPLICABLE");
                return;
            }

            PolicyV1 policy;
            string policyReason;
            if (!PolicyV1Codec.TryRead(paths.PolicyPath, out policy, out policyReason))
            {
                Project(null, "REJECTED", policyReason, "NOT_APPLICABLE");
                return;
            }

            sessionPolicy = policy;
            if (sessionPolicy.IsRandom && !TryInstallIntroRoutePatch())
            {
                Project(sessionPolicy, "FAILED", "INTERNAL_FAILURE",
                    "NOT_APPLICABLE");
                return;
            }
            ModEvents.PlayerSpawnedInWorld.RegisterHandler(OnPlayerSpawned);
            if (sessionPolicy.IsRandom)
                ModEvents.GameUpdate.RegisterHandler(OnGameUpdate);
            RuntimeLog.Write("RUNTIME_READY");
        }

        private static void OnPlayerSpawned(
            ref ModEvents.SPlayerSpawnedInWorldData data)
        {
            EntityPlayer player = null;
            bool reserved = false;
            try
            {
                // One Random transaction owns the session result. Follow-up
                // callbacks caused by placement/restoration must not replace it.
                if (sessionAttemptConsumed) return;

                string denial = RuntimeEnvironmentGuard.DenialReason(sessionPolicy, data);
                if (denial != null)
                {
                    ProjectDenial(denial);
                    return;
                }

                if (data.RespawnType == RespawnType.LoadedGame)
                {
                    if (sessionPolicy.IsRandom) ObserveLoadedMarker(data.EntityId);
                    else Project(sessionPolicy, "REJECTED", "LIFECYCLE_REJECTED",
                        "NOT_APPLICABLE");
                    return;
                }

                if (data.RespawnType != RespawnType.NewGame)
                {
                    Project(sessionPolicy, "REJECTED", "LIFECYCLE_REJECTED",
                        "NOT_APPLICABLE");
                    return;
                }

                if (sessionPolicy.IsStandard)
                {
                    Project(sessionPolicy, "BYPASSED", "STANDARD_BYPASS",
                        "NOT_APPLICABLE");
                    return;
                }

                World world = GameManager.Instance.World;
                player = world.GetEntity(data.EntityId) as EntityPlayer;
                if (player == null)
                {
                    Project(sessionPolicy, "REJECTED", "ENTITY_UNRESOLVED",
                        "NOT_APPLICABLE");
                    return;
                }
                if (!MarkerStore.IsAvailable(player))
                {
                    Project(sessionPolicy, "REJECTED", "MARKER_API_UNAVAILABLE",
                        "NOT_APPLICABLE");
                    return;
                }

                MarkerState marker = MarkerStore.Read(player);
                if (marker == MarkerState.Reserved)
                {
                    Project(sessionPolicy, "FAILED", "MARKER_CONSUMED", "RESERVED");
                    return;
                }
                if (marker == MarkerState.Completed)
                {
                    Project(sessionPolicy, "COMPLETED", "RELOCATION_COMPLETED",
                        "COMPLETED");
                    return;
                }
                if (marker == MarkerState.Invalid)
                {
                    Project(sessionPolicy, "FAILED", "MARKER_INVALID", "INVALID");
                    return;
                }
                if (pending != null)
                {
                    Project(sessionPolicy, "REJECTED", "MARKER_CONSUMED", "ABSENT");
                    return;
                }

                if (!MarkerStore.TryReserve(player))
                {
                    ProjectReservationFailure(player);
                    return;
                }
                reserved = true;
                sessionAttemptConsumed = true;

                Vector3 candidatePosition;
                string curatedPointId;
                if (NavezganeStartCatalog.TrySelect(world, out candidatePosition,
                    out curatedPointId))
                {
                    RuntimeLog.Write(curatedPointId);
                }
                else
                {
                    SpawnPointList list = GameManager.Instance.GetSpawnPointList();
                    if (list == null)
                    {
                        Project(sessionPolicy, "FAILED", "SPAWN_LIST_UNAVAILABLE",
                            "RESERVED");
                        return;
                    }
                    SpawnPosition candidate = list.GetRandomSpawnPosition(world, null, 0, 0);
                    if (candidate.IsUndef())
                    {
                        Project(sessionPolicy, "FAILED", "CANDIDATE_UNDEFINED",
                            "RESERVED");
                        return;
                    }
                    if (candidate.bInvalid)
                    {
                        Project(sessionPolicy, "FAILED", "CANDIDATE_INVALID",
                            "RESERVED");
                        return;
                    }
                    candidatePosition = candidate.position;
                }
                if (!world.IsPositionInBounds(candidatePosition))
                {
                    Project(sessionPolicy, "FAILED", "CANDIDATE_OUT_OF_BOUNDS",
                        "RESERVED");
                    return;
                }
                string worldGuid = world.Guid;
                if (string.IsNullOrEmpty(worldGuid))
                {
                    Project(sessionPolicy, "FAILED", "INTERNAL_FAILURE", "RESERVED");
                    return;
                }

                pending = new PendingPlacement(worldGuid, data.EntityId,
                    candidatePosition, player.GetPosition(), curatedPointId);
                Project(sessionPolicy, "RESERVED", "PLACEMENT_DEFERRED", "RESERVED");
            }
            catch
            {
                Project(sessionPolicy, "FAILED", "INTERNAL_FAILURE",
                    reserved ? "RESERVED" : "NOT_APPLICABLE");
            }
        }

        private static void ObserveLoadedMarker(int entityId)
        {
            EntityPlayer player = GameManager.Instance.World.GetEntity(entityId)
                as EntityPlayer;
            if (player == null)
            {
                Project(sessionPolicy, "REJECTED", "ENTITY_UNRESOLVED",
                    "NOT_APPLICABLE");
                return;
            }
            if (!MarkerStore.IsAvailable(player))
            {
                Project(sessionPolicy, "REJECTED", "MARKER_API_UNAVAILABLE",
                    "NOT_APPLICABLE");
                return;
            }

            MarkerState state = MarkerStore.Read(player);
            if (state == MarkerState.Completed)
            {
                if (sessionPolicy.ProtectArrivalBiome &&
                    MarkerStore.ReadProtectionFamily(player) > 0)
                    protectedEntityId = entityId;
                TraderRouteState route = MarkerStore.ReadTraderRoute(player);
                if (route == TraderRouteState.Pending ||
                    route == TraderRouteState.Reserved)
                    AttachTraderRoute(player);
                Project(sessionPolicy, "COMPLETED", "RELOCATION_COMPLETED", "COMPLETED");
                return;
            }
            if (state == MarkerState.Reserved)
            {
                Project(sessionPolicy, "RESERVED", "PLACEMENT_DEFERRED", "RESERVED");
                return;
            }
            if (state == MarkerState.Invalid)
            {
                Project(sessionPolicy, "FAILED", "MARKER_INVALID", "INVALID");
                return;
            }
            Project(sessionPolicy, "REJECTED", "LIFECYCLE_REJECTED", "ABSENT");
        }

        private static void OnGameUpdate(ref ModEvents.SGameUpdateData data)
        {
            MaintainArrivalProtection();
            ObservePendingTraderRoute();
            PendingPlacement attempt = pending;
            if (attempt == null) return;
            try
            {
                if (!RuntimeEnvironmentGuard.IsStillApproved(sessionPolicy))
                {
                    FailPending("VERIFY_CONTEXT_FAILED");
                    return;
                }
                World world = GameManager.Instance.World;
                if (!string.Equals(world.Guid, attempt.WorldGuid,
                    StringComparison.Ordinal))
                {
                    FailPending("VERIFY_CONTEXT_FAILED");
                    return;
                }
                EntityPlayer player = world.GetEntity(attempt.EntityId) as EntityPlayer;
                if (player == null)
                {
                    FailPending("VERIFY_CONTEXT_FAILED");
                    return;
                }
                ChunkManager.ChunkObserver observer = player.ChunkObserver;
                if (observer == null)
                {
                    FailPending("OBSERVER_UNAVAILABLE");
                    return;
                }
                if (!attempt.PlacementCalled)
                {
                    try
                    {
                        SemanticSnapshot semanticBefore = SemanticSnapshot.Capture(player);
                        player.SetPosition(attempt.Candidate, true);
                        observer.SetPosition(attempt.Candidate);
                        RuntimeLog.Write("PLACEMENT_CALLED");
                        RuntimeLog.Write("CANDIDATE_LOAD_REQUESTED");
                        SemanticSnapshot semanticAfterPlacement =
                            SemanticSnapshot.Capture(player);
                        if (semanticAfterPlacement.Digest != semanticBefore.Digest)
                        {
                            FailPending("SEMANTIC_CHANGED");
                            return;
                        }
                        RuntimeLog.Write("SEMANTIC_UNCHANGED");
                        attempt.BeginPlacement(
                            Time.realtimeSinceStartup + VerificationWindowSeconds);
                    }
                    catch
                    {
                        FailPending("PLACEMENT_FAILED");
                    }
                    return;
                }

                attempt.Ticks++;
                if (attempt.Ticks < FirstVerificationTick) return;
                bool inBounds = world.IsPositionInBounds(attempt.Candidate);
                if (!inBounds)
                {
                    FailPending("VERIFY_CONTEXT_FAILED");
                    return;
                }
                bool containingChunkReady = world.GetChunkFromWorldPos(
                    World.worldToBlockPos(attempt.Candidate)) != null;
                if (!containingChunkReady)
                {
                    if (Time.realtimeSinceStartup < attempt.VerificationDeadline) return;
                    FailPending("VERIFY_CHUNK_TIMEOUT");
                    return;
                }
                if (!attempt.PrimeDelayStarted)
                {
                    attempt.BeginPrimeDelay(
                        Time.realtimeSinceStartup + PrimeDelaySeconds);
                    RuntimeLog.Write("CANDIDATE_PRIME_WAIT");
                    return;
                }
                if (Time.realtimeSinceStartup < attempt.PrimeDeadline) return;
                if (!attempt.LandingResolved)
                {
                    Vector3 safeLanding;
                    if (!NavezganeStartCatalog.TryFindSafeLanding(world,
                        attempt.Candidate, attempt.PointId,
                        NavezganeStartCatalog.GetSearchRadius(attempt.PointId),
                        out safeLanding))
                    {
                        FailPending("VERIFY_UNSAFE");
                        return;
                    }
                    safeLanding += Vector3.up * SecondLandingLift;
                    attempt.AdoptSafeCandidate(safeLanding);
                    player.SetPosition(safeLanding, true);
                    observer.SetPosition(safeLanding);
                    RuntimeLog.Write("CANDIDATE_ADJUSTED");
                    return;
                }
                Vector3 observedPosition = player.GetPosition();
                bool groundedAndWithinTolerance = player.onGround &&
                    HorizontalDistance(observedPosition, attempt.Candidate) <=
                    HorizontalPositionTolerance &&
                    Math.Abs(observedPosition.y - attempt.CatalogGroundY) <=
                    SettledHeightTolerance;
                if (!attempt.ObserveVerificationSample(groundedAndWithinTolerance,
                    RequiredStableVerificationSamples))
                {
                    if (Time.realtimeSinceStartup < attempt.VerificationDeadline) return;
                    FailPending("VERIFY_POSITION_MISMATCH");
                    return;
                }
                attempt.AdoptSettledPosition(observedPosition);
                RuntimeLog.Write("CANDIDATE_SURFACE_SETTLED");
                if (!MarkerStore.TryComplete(player))
                {
                    FailPending("COMPLETION_FAILED");
                    return;
                }
                int initialBiome;
                int protectionFamily;
                if (!TryResolveInitialBiome(world, observedPosition,
                    out initialBiome, out protectionFamily) ||
                    !MarkerStore.TrySetInitialBiome(player, initialBiome))
                {
                    RuntimeLog.Write("INITIAL_BIOME_FAILED");
                }
                else
                {
                    RuntimeLog.Write("INITIAL_BIOME_STORED");
                    if (sessionPolicy.ProtectArrivalBiome &&
                        protectionFamily > 0 && MarkerStore.TryEnableProtection(
                            player, initialBiome, protectionFamily))
                    {
                        protectedEntityId = attempt.EntityId;
                        RuntimeLog.Write("ARRIVAL_PROTECTION_ENABLED");
                    }
                }
                if (MarkerStore.TryBeginTraderRoute(player))
                    AttachTraderRoute(player);
                pending = null;
                Project(sessionPolicy, "COMPLETED", "RELOCATION_COMPLETED", "COMPLETED");
            }
            catch
            {
                FailPending("INTERNAL_FAILURE");
            }
        }

        private static float HorizontalDistance(Vector3 first, Vector3 second)
        {
            float dx = first.x - second.x;
            float dz = first.z - second.z;
            return (float)Math.Sqrt(dx * dx + dz * dz);
        }

        private static bool TryResolveInitialBiome(World world, Vector3 position,
            out int initialBiome, out int protectionFamily)
        {
            initialBiome = 0;
            protectionFamily = 0;
            if (world == null) return false;
            BiomeDefinition biome = world.GetBiome((int)Math.Floor(position.x),
                (int)Math.Floor(position.z));
            if (biome == null || string.IsNullOrEmpty(biome.m_sBiomeName))
                return false;
            string name = biome.m_sBiomeName;
            if (string.Equals(name, "pine_forest", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(name, "forest", StringComparison.OrdinalIgnoreCase))
            {
                initialBiome = 3;
                return true;
            }
            if (string.Equals(name, "snow", StringComparison.OrdinalIgnoreCase))
            {
                initialBiome = 1;
                protectionFamily = 8;
                return true;
            }
            if (string.Equals(name, "desert", StringComparison.OrdinalIgnoreCase))
            {
                initialBiome = 5;
                protectionFamily = 2;
                return true;
            }
            if (string.Equals(name, "burnt_forest", StringComparison.OrdinalIgnoreCase))
            {
                initialBiome = 9;
                protectionFamily = 1;
                return true;
            }
            if (string.Equals(name, "wasteland", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(name, "city_wasteland", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(name, "wasteland_hub", StringComparison.OrdinalIgnoreCase))
            {
                initialBiome = 8;
                protectionFamily = 4;
                return true;
            }
            return false;
        }

        private static void MaintainArrivalProtection()
        {
            if (!sessionPolicy.ProtectArrivalBiome || protectedEntityId < 0 ||
                GameManager.Instance == null || GameManager.Instance.World == null)
                return;
            EntityPlayer player = GameManager.Instance.World.GetEntity(protectedEntityId)
                as EntityPlayer;
            int family = MarkerStore.ReadProtectionFamily(player);
            string prefix;
            string timer;
            string timerMax;
            if (family == 1)
            {
                prefix = "Burnt";
                timer = "$BurntHazardTimer";
                timerMax = "$BurntHazardTimerMax";
            }
            else if (family == 2)
            {
                prefix = "Desert";
                timer = "$DesertHazardTimer";
                timerMax = "$DesertHazardTimerMax";
            }
            else if (family == 4)
            {
                prefix = "Wasteland";
                timer = "$WastelandHazardTimer";
                timerMax = "$WastelandHazardTimerMax";
            }
            else if (family == 8)
            {
                prefix = "Snow";
                timer = "$SnowHazardTimer";
                timerMax = "$SnowHazardTimerMax";
            }
            else return;
            string[] buffs = { "buff" + prefix + "_Hazard",
                "buff" + prefix + "_Hazard_Over",
                "buff" + prefix + "_Hazard_Recover",
                "buff" + prefix + "_Hazard01",
                "buff" + prefix + "_Hazard02" };
            for (int i = 0; i < buffs.Length; i++)
                if (player.Buffs.HasBuff(buffs[i]))
                    player.Buffs.RemoveBuff(buffs[i], -1, true);
            if (player.Buffs.HasCustomVar(timerMax))
                player.Buffs.AddCustomVar(timer,
                    player.Buffs.GetCustomVar(timerMax));
        }

        private static void AttachTraderRoute(EntityPlayer player)
        {
            if (player == null || traderRouteSubscribed) return;
            if (player.QuestJournal != null &&
                player.QuestJournal.OwnerPlayer != null)
                player = player.QuestJournal.OwnerPlayer;
            traderRoutePlayer = player;
            traderRouteEntityId = player.entityId;
            player.QuestAccepted += OnQuestAccepted;
            traderRouteSubscribed = true;
            traderRouteObserveTicks = 0;
            traderRouteJournalLogged = false;
            traderRouteQuestLogged = false;
            traderRouteWaitingLogged = false;
            RuntimeLog.Write("TRADER_ROUTE_READY");
            ObservePendingTraderRoute();
        }

        private static void ObservePendingTraderRoute()
        {
            if (!traderRouteSubscribed || traderRouteEntityId < 0) return;
            traderRouteObserveTicks++;
            if (traderRouteObserveTicks != 1 && traderRouteObserveTicks % 30 != 0)
                return;
            EntityPlayer player = traderRoutePlayer;
            TraderRouteState route = player == null ? TraderRouteState.Invalid :
                MarkerStore.ReadTraderRoute(player);
            if (player == null)
            {
                traderRouteSubscribed = false;
                return;
            }
            if (route != TraderRouteState.Pending &&
                route != TraderRouteState.Reserved)
            {
                traderRouteSubscribed = false;
                return;
            }
            if (player.QuestJournal == null) return;
            List<Quest> quests = player.QuestJournal.quests;
            if (quests == null || quests.Count > 64) return;
            if (quests.Count > 0 && !traderRouteJournalLogged)
            {
                traderRouteJournalLogged = true;
                RuntimeLog.Write("TRADER_ROUTE_JOURNAL_NONEMPTY");
            }
            for (int i = quests.Count - 1; i >= 0; i--)
            {
                Quest quest = quests[i];
                if (quest == null || !string.Equals(quest.ID,
                    "quest_whiteRiverCitizen1",
                    StringComparison.OrdinalIgnoreCase)) continue;
                if (!traderRouteQuestLogged)
                {
                    traderRouteQuestLogged = true;
                    RuntimeLog.Write("TRADER_ROUTE_QUEST_SEEN");
                }
                OnQuestAccepted(quest);
                if (MarkerStore.ReadTraderRoute(player) ==
                    TraderRouteState.Completed)
                    traderRouteSubscribed = false;
                return;
            }
        }

        private static void OnQuestAccepted(Quest quest)
        {
            try
            {
                if (quest == null || !sessionPolicy.IsRandom ||
                    !RuntimeEnvironmentGuard.IsStillApproved(sessionPolicy) ||
                    !string.Equals(quest.ID, "quest_whiteRiverCitizen1",
                        StringComparison.OrdinalIgnoreCase) || !quest.Active ||
                    quest.CurrentPhase != 1) return;
                EntityPlayer player = traderRoutePlayer;
                if (player == null || player.QuestJournal == null ||
                    MarkerStore.Read(player) != MarkerState.Completed ||
                    (MarkerStore.ReadTraderRoute(player) != TraderRouteState.Pending &&
                     MarkerStore.ReadTraderRoute(player) != TraderRouteState.Reserved))
                    return;

                ObjectiveGoto objective = null;
                for (int i = 0; i < quest.Objectives.Count; i++)
                {
                    ObjectiveGoto candidate = quest.Objectives[i] as ObjectiveGoto;
                    if (candidate != null && candidate.Phase == 1 &&
                        string.Equals(candidate.ID, "trader",
                            StringComparison.Ordinal))
                    {
                        objective = candidate;
                        break;
                    }
                }
                if (objective == null) return;
                Vector3 traderLocation;
                Vector3 traderSize;
                if (!TrySelectNavezganeTrader(player, out traderLocation,
                    out traderSize))
                {
                    if (!traderRouteWaitingLogged)
                    {
                        traderRouteWaitingLogged = true;
                        RuntimeLog.Write("TRADER_ROUTE_WAIT_TRADERS");
                    }
                    return;
                }
                TraderRouteState route = MarkerStore.ReadTraderRoute(player);
                if (route == TraderRouteState.Pending)
                {
                    if (!MarkerStore.TryReserveTraderRoute(player)) return;
                    RuntimeLog.Write("TRADER_ROUTE_RESERVED");
                }
                else if (route != TraderRouteState.Reserved) return;
                BiomeFilterTypes originalFilterType = objective.biomeFilterType;
                string originalFilter = objective.biomeFilter;
                bool originalPositionSet = objective.positionSet;
                objective.biomeFilterType = BiomeFilterTypes.AnyBiome;
                objective.biomeFilter = string.Empty;
                objective.positionSet = false;
                if (!objective.SetLocation(traderLocation, traderSize))
                {
                    objective.biomeFilterType = originalFilterType;
                    objective.biomeFilter = originalFilter;
                    objective.positionSet = originalPositionSet;
                    RuntimeLog.Write("TRADER_ROUTE_FALLBACK");
                    return;
                }
                RuntimeLog.Write("TRADER_ROUTE_SELECTED");
                player.QuestJournal.RefreshQuest(quest);
                if (!MarkerStore.TryCompleteTraderRoute(player))
                {
                    RuntimeLog.Write("TRADER_ROUTE_FALLBACK");
                    return;
                }
                RuntimeLog.Write("TRADER_ROUTE_COMPLETED");
            }
            catch
            {
                RuntimeLog.Write("TRADER_ROUTE_FALLBACK");
            }
        }

        private static bool TrySelectNavezganeTrader(EntityPlayer player,
            out Vector3 location, out Vector3 size)
        {
            location = Vector3.zero;
            size = Vector3.zero;
            if (player == null || GameManager.Instance == null ||
                GameManager.Instance.World == null ||
                !string.Equals(GamePrefs.GetString(EnumGamePrefs.GameWorld),
                    "Navezgane",
                    StringComparison.OrdinalIgnoreCase)) return false;
            Vector3[] locations =
            {
                new Vector3(941f, 66f, -1566f),
                new Vector3(-957f, 76f, 1717f),
                new Vector3(190f, 74f, -144f),
                new Vector3(-1586f, 66f, -1215f),
                new Vector3(428f, 61f, 644f)
            };
            Vector3[] sizes =
            {
                new Vector3(60f, 28f, 60f),
                new Vector3(60f, 21f, 60f),
                new Vector3(60f, 28f, 60f),
                new Vector3(60f, 48f, 60f),
                new Vector3(60f, 21f, 60f)
            };
            int[] biomes = { 5, 1, 9, 8, 3 };
            int initialBiome = MarkerStore.ReadInitialBiome(player);
            if (initialBiome <= 0) return false;
            Vector3 origin = player.GetPosition();
            double best = double.MaxValue;
            int bestIndex = -1;
            for (int i = 0; i < locations.Length; i++)
            {
                if (biomes[i] != initialBiome) continue;
                double dx = locations[i].x + sizes[i].x * 0.5 - origin.x;
                double dz = locations[i].z + sizes[i].z * 0.5 - origin.z;
                double distance = dx * dx + dz * dz;
                if (distance < best)
                {
                    best = distance;
                    bestIndex = i;
                }
            }
            if (bestIndex < 0) return false;
            location = locations[bestIndex];
            size = sizes[bestIndex];
            return true;
        }

        private static bool TryInstallIntroRoutePatch()
        {
            try
            {
                MethodInfo target = typeof(Quest).GetMethod(
                    "SetupPosition",
                    BindingFlags.Instance | BindingFlags.Public |
                        BindingFlags.NonPublic,
                    null,
                    new Type[]
                    {
                        typeof(EntityNPC),
                        typeof(EntityPlayer),
                        typeof(List<Vector2>),
                        typeof(int)
                    },
                    null);
                MethodInfo prefix = typeof(HistoricalRandomStartModApi).GetMethod(
                    "IntroRouteSetupPositionPrefix",
                    BindingFlags.Static | BindingFlags.NonPublic);
                if (target == null || prefix == null) return false;

                Harmony harmony =
                    new Harmony("bitwrecked.historicalrandomstart.intro-route");
                harmony.Patch(target, new HarmonyMethod(prefix), null, null, null, null);
                RuntimeLog.Write("INTRO_ROUTE_PATCH_READY");
                return true;
            }
            catch
            {
                RuntimeLog.Write("INTERNAL_FAILURE");
                return false;
            }
        }

        private static void IntroRouteSetupPositionPrefix(
            Quest __instance, EntityPlayer player)
        {
            try
            {
                if (sessionPolicy == null || !sessionPolicy.IsRandom ||
                    __instance == null || player == null ||
                    !string.Equals(__instance.ID, "intro_buried_supplies",
                        StringComparison.OrdinalIgnoreCase))
                    return;

                if (MarkerStore.Read(player) != MarkerState.Completed ||
                    MarkerStore.ReadTraderRoute(player) !=
                        TraderRouteState.Completed)
                    return;

                int initialBiome = MarkerStore.ReadInitialBiome(player);
                string biome;
                if (initialBiome == 1) biome = "snow";
                else if (initialBiome == 3) biome = "pine_forest";
                else if (initialBiome == 5) biome = "desert";
                else if (initialBiome == 8) biome = "wasteland";
                else if (initialBiome == 9) biome = "burnt_forest";
                else
                {
                    RuntimeLog.Write("INTRO_ROUTE_FALLBACK");
                    return;
                }

                if (__instance.Objectives == null ||
                    __instance.Objectives.Count < 1 ||
                    __instance.Objectives.Count > 32)
                {
                    RuntimeLog.Write("INTRO_ROUTE_FALLBACK");
                    return;
                }

                ObjectiveRandomGotoNPC target = null;
                int matches = 0;
                for (int i = 0; i < __instance.Objectives.Count; i++)
                {
                    ObjectiveRandomGotoNPC objective =
                        __instance.Objectives[i] as ObjectiveRandomGotoNPC;
                    if (objective == null || objective.Phase != 1) continue;
                    target = objective;
                    matches++;
                }

                if (matches != 1 || target == null ||
                    target.positionSet ||
                    target.biomeFilterType != BiomeFilterTypes.OnlyBiome ||
                    !string.Equals(target.biomeFilter, "pine_forest",
                        StringComparison.Ordinal))
                {
                    RuntimeLog.Write("INTRO_ROUTE_FALLBACK");
                    return;
                }

                target.biomeFilterType = BiomeFilterTypes.OnlyBiome;
                target.biomeFilter = biome;
                RuntimeLog.Write("INTRO_ROUTE_FILTER_APPLIED");
            }
            catch
            {
                RuntimeLog.Write("INTRO_ROUTE_FALLBACK");
            }
        }
        private static void ProjectDenial(string reason)
        {
            string outcome = string.Equals(reason, "BUILD_MISMATCH",
                StringComparison.Ordinal) || string.Equals(reason,
                "RUNTIME_LANE_UNCONFIRMED", StringComparison.Ordinal)
                ? "INCOMPATIBLE" : "REJECTED";
            Project(sessionPolicy, outcome, reason, "NOT_APPLICABLE");
        }

        private static void ProjectReservationFailure(EntityPlayer player)
        {
            MarkerState state = MarkerStore.Read(player);
            if (state == MarkerState.Completed)
            {
                Project(sessionPolicy, "COMPLETED", "RELOCATION_COMPLETED", "COMPLETED");
                return;
            }
            Project(sessionPolicy, "FAILED", "RESERVATION_FAILED",
                FailureMarker(state));
        }

        private static void FailPending(string reason)
        {
            PendingPlacement failed = pending;
            if (failed != null && failed.PlacementCalled)
            {
                try
                {
                    World world = GameManager.Instance.World;
                    EntityPlayer player = world.GetEntity(failed.EntityId)
                        as EntityPlayer;
                    ChunkManager.ChunkObserver observer = player == null
                        ? null : player.ChunkObserver;
                    if (observer != null)
                    {
                        player.SetPosition(failed.OriginalPosition, true);
                        observer.SetPosition(failed.OriginalPosition);
                        RuntimeLog.Write("CANDIDATE_LOAD_RESTORED");
                    }
                }
                catch
                {
                    reason = "VERIFY_CONTEXT_FAILED";
                }
            }
            pending = null;
            Project(sessionPolicy, "FAILED", reason, "RESERVED");
        }

        private static string FailureMarker(MarkerState state)
        {
            if (state == MarkerState.Reserved) return "RESERVED";
            if (state == MarkerState.Invalid) return "INVALID";
            return "NOT_APPLICABLE";
        }

        private static void Project(PolicyV1 policy, string outcome,
            string reason, string markerState)
        {
            ResultV1 result;
            if (!ResultV1.TryCreate(policy, outcome, reason, markerState, out result))
            {
                RuntimeLog.Write("INTERNAL_FAILURE");
                return;
            }
            if (resultWriter == null || !resultWriter.TryWrite(result))
                RuntimeLog.Write("RESULT_WRITE_FAILED");
            RuntimeLog.Write(reason);
        }
    }
}
