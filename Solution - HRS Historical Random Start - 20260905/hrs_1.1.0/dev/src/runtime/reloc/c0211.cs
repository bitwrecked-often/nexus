using System;
using UnityEngine;

namespace BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe
{
    public sealed class RelocationModApi : IModApi
    {
        private const int FirstVerificationTick = 2;
        private const int RequiredStableVerificationSamples = 2;
        private const float VerificationWindowSeconds = 30f;
        private const float PositionTolerance = 0.25f;
        private static readonly SanitizedRelocationLog ProbeLog = new SanitizedRelocationLog();
        private static PendingPlacement pending;
        private static bool initialized;

        public void InitMod(Mod modInstance)
        {
            if (initialized) return;
            initialized = true;
            if (!CompatibilityGuard.IsCompatible())
            {
                ProbeLog.Write("RELOC_BUILD_MISMATCH");
                return;
            }
            ModEvents.PlayerSpawnedInWorld.RegisterHandler(OnPlayerSpawned);
            ModEvents.GameUpdate.RegisterHandler(OnGameUpdate);
            ProbeLog.Write("RELOC_READY");
        }

        private static void OnPlayerSpawned(ref ModEvents.SPlayerSpawnedInWorldData data)
        {
            try
            {
                if (!CompatibilityGuard.IsCompatible() || !TargetGuard.IsApprovedNewGame(data))
                {
                    ProbeLog.Write("RELOC_TARGET_REJECTED");
                    return;
                }
                World world = GameManager.Instance.World;
                EntityPlayer player = world.GetEntity(data.EntityId) as EntityPlayer;
                if (player == null) { ProbeLog.Write("RELOC_ENTITY_UNRESOLVED"); return; }
                if (pending != null || MarkerStore.Read(player) != MarkerState.Absent)
                {
                    ProbeLog.Write("RELOC_MARKER_CONSUMED");
                    return;
                }
                if (!MarkerStore.TryReserve(player))
                {
                    ProbeLog.Write("RELOC_RESERVATION_FAILED");
                    return;
                }

                SpawnPointList list = GameManager.Instance.GetSpawnPointList();
                if (list == null) { ProbeLog.Write("RELOC_LIST_UNAVAILABLE"); return; }
                SpawnPosition candidate = list.GetRandomSpawnPosition(world, null, 0, 0);
                if (candidate.IsUndef()) { ProbeLog.Write("RELOC_CANDIDATE_UNDEFINED"); return; }
                if (candidate.bInvalid) { ProbeLog.Write("RELOC_CANDIDATE_INVALID"); return; }
                if (!world.IsPositionInBounds(candidate.position)) { ProbeLog.Write("RELOC_CANDIDATE_BOUNDS"); return; }
                string worldGuid = world.Guid;
                if (string.IsNullOrEmpty(worldGuid)) { ProbeLog.Write("RELOC_INTERNAL_FAILURE"); return; }
                pending = new PendingPlacement(worldGuid, data.EntityId, candidate.position);
                ProbeLog.Write("RELOC_PLACEMENT_DEFERRED");
            }
            catch
            {
                ProbeLog.Write("RELOC_PLACEMENT_FAILED");
            }
        }

        private static void OnGameUpdate(ref ModEvents.SGameUpdateData data)
        {
            PendingPlacement attempt = pending;
            if (attempt == null) return;
            try
            {
                if (!CompatibilityGuard.IsCompatible() || !TargetGuard.IsApprovedEnvironment())
                {
                    FailVerification("RELOC_VERIFY_CONTEXT_FAILED");
                    return;
                }
                World world = GameManager.Instance.World;
                if (!string.Equals(world.Guid, attempt.WorldGuid, StringComparison.Ordinal))
                {
                    FailVerification("RELOC_VERIFY_CONTEXT_FAILED");
                    return;
                }
                EntityPlayer player = world.GetEntity(attempt.EntityId) as EntityPlayer;
                if (!attempt.PlacementCalled)
                {
                    if (player == null)
                    {
                        FailVerification("RELOC_VERIFY_CONTEXT_FAILED");
                        return;
                    }
                    ChunkManager.ChunkObserver observer = player.ChunkObserver;
                    if (observer == null)
                    {
                        pending = null;
                        ProbeLog.Write("RELOC_OBSERVER_UNAVAILABLE");
                        return;
                    }
                    try
                    {
                        SemanticSnapshot semanticBefore = SemanticSnapshot.Capture(player);
                        player.SetPosition(attempt.Candidate, true);
                        observer.SetPosition(attempt.Candidate);
                        ProbeLog.Write("RELOC_PLACEMENT_CALLED");
                        SemanticSnapshot semanticAfterPlacement = SemanticSnapshot.Capture(player);
                        if (semanticAfterPlacement.Digest != semanticBefore.Digest)
                        {
                            pending = null;
                            ProbeLog.Write("RELOC_SEMANTIC_CHANGED");
                            return;
                        }
                        ProbeLog.Write("RELOC_SEMANTIC_UNCHANGED");
                        attempt.BeginPlacement(
                            Time.realtimeSinceStartup + VerificationWindowSeconds);
                    }
                    catch
                    {
                        pending = null;
                        ProbeLog.Write("RELOC_PLACEMENT_FAILED");
                    }
                    return;
                }
                attempt.Ticks++;
                if (attempt.Ticks < FirstVerificationTick) return;
                bool inBounds = world.IsPositionInBounds(attempt.Candidate);
                if (player == null || !inBounds)
                {
                    FailVerification("RELOC_VERIFY_CONTEXT_FAILED");
                    return;
                }
                bool containingChunkReady = world.GetChunkFromWorldPos(
                    World.worldToBlockPos(attempt.Candidate)) != null;
                if (!containingChunkReady)
                {
                    if (Time.realtimeSinceStartup < attempt.VerificationDeadline) return;
                    FailVerification("RELOC_VERIFY_CHUNK_TIMEOUT");
                    return;
                }
                if (!world.CanPlayersSpawnAtPos(attempt.Candidate, false))
                {
                    FailVerification("RELOC_VERIFY_UNSAFE");
                    return;
                }
                bool groundedAndWithinTolerance = player.onGround &&
                    Vector3.Distance(player.GetPosition(), attempt.Candidate) <= PositionTolerance;
                if (!attempt.ObserveVerificationSample(groundedAndWithinTolerance,
                    RequiredStableVerificationSamples))
                {
                    if (Time.realtimeSinceStartup < attempt.VerificationDeadline) return;
                    FailVerification("RELOC_VERIFY_POSITION_MISMATCH");
                    return;
                }
                if (!MarkerStore.TryComplete(player))
                {
                    pending = null;
                    ProbeLog.Write("RELOC_COMPLETION_FAILED");
                    return;
                }
                pending = null;
                ProbeLog.Write("RELOC_COMPLETED");
            }
            catch
            {
                FailVerification("RELOC_INTERNAL_FAILURE");
            }
        }

        private static void FailVerification(string reason)
        {
            pending = null;
            ProbeLog.Write(reason);
        }
    }
}
