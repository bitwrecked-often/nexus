using System;
using System.Diagnostics;

namespace BitWrecked.HistoricalRandomStart.DevProbe
{
    public sealed class ProbeModApi : IModApi
    {
        private static readonly DuplicateObservationGate DuplicateGate = new DuplicateObservationGate();
        private static readonly SanitizedGameLog ProbeLog = new SanitizedGameLog();
        private static bool initialized;

        public void InitMod(Mod modInstance)
        {
            if (initialized) return;
            initialized = true;

            if (!CompatibilityGuard.IsCompatible())
            {
                ProbeLog.Write("OBS_BUILD_MISMATCH", "unknown", "unknown", "init", false, 0, 0);
                return;
            }

            ModEvents.PlayerSpawnedInWorld.RegisterHandler(OnPlayerSpawnedInWorld);
            ProbeLog.Write("OBS_READY", "pending", "pending", "init", false, 0, 0);
        }

        private static void OnPlayerSpawnedInWorld(ref ModEvents.SPlayerSpawnedInWorldData data)
        {
            Stopwatch timer = Stopwatch.StartNew();
            try
            {
                if (!ProbeLog.HasCapacity) return;
                if (!CompatibilityGuard.IsCompatible())
                {
                    ProbeLog.Write("OBS_BUILD_MISMATCH", "unknown", "unknown", "unknown", false, 0, timer.ElapsedMilliseconds);
                    return;
                }
                if (GamePrefs.GetBool(EnumGamePrefs.EACEnabled))
                {
                    ProbeLog.Write("OBS_EAC_NOT_DISABLED", "unknown", data.IsLocalPlayer ? "local" : "remote", data.RespawnType.ToString(), false, 0, timer.ElapsedMilliseconds);
                    return;
                }
                if (!TargetGuard.IsApprovedCurrentTarget())
                {
                    ProbeLog.Write("OBS_TARGET_MISMATCH", "unknown", data.IsLocalPlayer ? "local" : "remote", data.RespawnType.ToString(), false, 0, timer.ElapsedMilliseconds);
                    return;
                }
                if (ConnectionManager.Instance == null || !ConnectionManager.Instance.IsServer)
                {
                    ProbeLog.Write("OBS_NOT_SERVER", "client", data.IsLocalPlayer ? "local" : "remote", data.RespawnType.ToString(), false, 0, timer.ElapsedMilliseconds);
                    return;
                }

                ObservationResult result = SpawnObservation.Classify(data.RespawnType);
                Entity entity = GameManager.Instance.World.GetEntity(data.EntityId);
                EntityPlayer player = entity as EntityPlayer;
                if (player == null)
                {
                    ProbeLog.Write("OBS_ENTITY_UNRESOLVED", "server", data.IsLocalPlayer ? "local" : "remote", result.Lifecycle, false, 0, timer.ElapsedMilliseconds);
                    return;
                }

                DuplicateDecision duplicate = DuplicateGate.TryAccept(TargetGuard.CurrentWorldKey(), data.EntityId, data.RespawnType);
                if (duplicate == DuplicateDecision.Duplicate)
                {
                    ProbeLog.Write("OBS_DUPLICATE_SUPPRESSED", "server", data.IsLocalPlayer ? "local" : "remote", result.Lifecycle, true, DuplicateGate.Count, timer.ElapsedMilliseconds);
                    return;
                }
                if (duplicate == DuplicateDecision.Capacity)
                {
                    ProbeLog.Write("OBS_DUPLICATE_CAPACITY", "server", data.IsLocalPlayer ? "local" : "remote", result.Lifecycle, true, DuplicateGate.Count, timer.ElapsedMilliseconds);
                    return;
                }

                ProbeLog.Write(result.ReasonCode, "server", data.IsLocalPlayer ? "local" : "remote", result.Lifecycle, true, DuplicateGate.Count, timer.ElapsedMilliseconds);
            }
            catch
            {
                ProbeLog.Write("OBS_INTERNAL_FAILURE", "unknown", "unknown", "unknown", false, 0, timer.ElapsedMilliseconds);
            }
        }
    }
}
