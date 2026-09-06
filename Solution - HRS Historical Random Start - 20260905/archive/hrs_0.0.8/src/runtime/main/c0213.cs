using System;

namespace main
{
    internal static class RuntimeEnvironmentGuard
    {
        internal static string DenialReason(PolicyV1 policy,
            ModEvents.SPlayerSpawnedInWorldData data)
        {
            if (policy == null) return "POLICY_REJECTED";
            if (!CompatibilityGuard.IsCompatible()) return "BUILD_MISMATCH";
            if (GamePrefs.GetBool(EnumGamePrefs.EACEnabled))
                return "RUNTIME_LANE_UNCONFIRMED";
            if (!data.IsLocalPlayer) return "EXECUTION_REJECTED";
            if (GameManager.IsDedicatedServer) return "EXECUTION_REJECTED";
            if (ConnectionManager.Instance == null) return "EXECUTION_REJECTED";
            if (!ConnectionManager.Instance.IsServer) return "NOT_SERVER";
            if (!ConnectionManager.Instance.IsSinglePlayer) return "EXECUTION_REJECTED";
            if (GameManager.Instance == null || GameManager.Instance.World == null)
                return "EXECUTION_REJECTED";
            if (!string.Equals(GamePrefs.GetString(EnumGamePrefs.GameName),
                policy.GameName, StringComparison.Ordinal)) return "GAME_NAME_MISMATCH";
            return null;
        }

        internal static bool IsStillApproved(PolicyV1 policy)
        {
            return policy != null && CompatibilityGuard.IsCompatible() &&
                !GamePrefs.GetBool(EnumGamePrefs.EACEnabled) &&
                !GameManager.IsDedicatedServer &&
                ConnectionManager.Instance != null &&
                ConnectionManager.Instance.IsServer &&
                ConnectionManager.Instance.IsSinglePlayer &&
                GameManager.Instance != null && GameManager.Instance.World != null &&
                string.Equals(GamePrefs.GetString(EnumGamePrefs.GameName),
                    policy.GameName, StringComparison.Ordinal);
        }
    }
}
