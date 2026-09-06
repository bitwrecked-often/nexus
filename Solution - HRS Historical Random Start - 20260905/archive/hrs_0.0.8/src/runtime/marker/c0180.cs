namespace marker
{
    public sealed class MarkerProbeModApi : IModApi
    {
        private static readonly SanitizedMarkerLog ProbeLog = new SanitizedMarkerLog();
        private static bool initialized;

        public void InitMod(Mod modInstance)
        {
            if (initialized) return;
            initialized = true;

            if (!CompatibilityGuard.IsCompatible())
            {
                ProbeLog.Write("MARKER_BUILD_MISMATCH");
                return;
            }

            ModEvents.PlayerSpawnedInWorld.RegisterHandler(OnPlayerSpawnedInWorld);
            ProbeLog.Write("MARKER_READY");
        }

        private static void OnPlayerSpawnedInWorld(ref ModEvents.SPlayerSpawnedInWorldData data)
        {
            try
            {
                if (!CompatibilityGuard.IsCompatible())
                {
                    ProbeLog.Write("MARKER_BUILD_MISMATCH");
                    return;
                }
                if (!TargetGuard.IsApprovedLocalTarget(data))
                {
                    ProbeLog.Write("MARKER_TARGET_REJECTED");
                    return;
                }

                EntityPlayer player = GameManager.Instance.World.GetEntity(data.EntityId) as EntityPlayer;
                if (player == null)
                {
                    ProbeLog.Write("MARKER_ENTITY_UNRESOLVED");
                    return;
                }

                if (data.RespawnType == RespawnType.LoadedGame)
                {
                    ProbeLog.Write(ReloadReason(MarkerStateStore.Read(player)));
                    return;
                }
                if (data.RespawnType != RespawnType.NewGame)
                {
                    ProbeLog.Write("MARKER_LIFECYCLE_REJECTED");
                    return;
                }

                if (MarkerStateStore.Read(player) != MarkerState.Absent)
                {
                    ProbeLog.Write("MARKER_ALREADY_CONSUMED");
                    return;
                }

                ProbeLog.Write(MarkerStateStore.TryReserveAndReadBack(player)
                    ? "MARKER_RESERVED_VERIFIED"
                    : "MARKER_RESERVATION_FAILED");
            }
            catch
            {
                ProbeLog.Write("MARKER_INTERNAL_FAILURE");
            }
        }

        private static string ReloadReason(MarkerState state)
        {
            if (state == MarkerState.Reserved) return "MARKER_RELOAD_RESERVED";
            if (state == MarkerState.Completed) return "MARKER_RELOAD_COMPLETED";
            if (state == MarkerState.Absent) return "MARKER_RELOAD_ABSENT";
            return "MARKER_RELOAD_INVALID";
        }
    }
}
