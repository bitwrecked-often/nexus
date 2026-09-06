using System;
using UnityEngine;

namespace BitWrecked.HistoricalRandomStart
{
    public sealed class HistoricalRandomStartModApi : IModApi
    {
        private const int FirstVerificationTick = 2;
        private const int RequiredStableVerificationSamples = 2;
        private const float VerificationWindowSeconds = 30f;
        private const float PositionTolerance = 0.25f;
        private static readonly SanitizedRuntimeLog RuntimeLog =
            new SanitizedRuntimeLog();
        private static PolicyV1 sessionPolicy;
        private static AtomicResultWriter resultWriter;
        private static PendingPlacement pending;
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
                    Project(sessionPolicy, "FAILED", "CANDIDATE_UNDEFINED", "RESERVED");
                    return;
                }
                if (candidate.bInvalid)
                {
                    Project(sessionPolicy, "FAILED", "CANDIDATE_INVALID", "RESERVED");
                    return;
                }
                if (!world.IsPositionInBounds(candidate.position))
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
                    candidate.position);
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
                if (!attempt.PlacementCalled)
                {
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
                    try
                    {
                        SemanticSnapshot semanticBefore = SemanticSnapshot.Capture(player);
                        player.SetPosition(attempt.Candidate, true);
                        observer.SetPosition(attempt.Candidate);
                        RuntimeLog.Write("PLACEMENT_CALLED");
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
                if (player == null || !inBounds)
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
                if (!world.CanPlayersSpawnAtPos(attempt.Candidate, false))
                {
                    FailPending("VERIFY_UNSAFE");
                    return;
                }
                bool groundedAndWithinTolerance = player.onGround &&
                    Vector3.Distance(player.GetPosition(), attempt.Candidate) <=
                    PositionTolerance;
                if (!attempt.ObserveVerificationSample(groundedAndWithinTolerance,
                    RequiredStableVerificationSamples))
                {
                    if (Time.realtimeSinceStartup < attempt.VerificationDeadline) return;
                    FailPending("VERIFY_POSITION_MISMATCH");
                    return;
                }
                if (!MarkerStore.TryComplete(player))
                {
                    pending = null;
                    MarkerState state = MarkerStore.Read(player);
                    Project(sessionPolicy, "FAILED", "COMPLETION_FAILED",
                        FailureMarker(state));
                    return;
                }
                pending = null;
                Project(sessionPolicy, "COMPLETED", "RELOCATION_COMPLETED", "COMPLETED");
            }
            catch
            {
                FailPending("INTERNAL_FAILURE");
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
