using System;
using System.IO;

namespace BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe
{
    internal static class TargetGuard
    {
        private const string GameRoot = @"C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die";
        private const string SaveRoot = @"C:\Users\mobil\AppData\Roaming\7DaysToDie\Saves";
        private const string WorldName = "Navezgane";
        private const string GameName = "HRS_Phase1A_Test_001";

        internal static bool IsApprovedEnvironment()
        {
            string runtimeRoot = Canonical(AppDomain.CurrentDomain.BaseDirectory);
            string saveRoot = Canonical(Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "7DaysToDie", "Saves"));

            return Exact(runtimeRoot, Canonical(GameRoot)) &&
                Exact(saveRoot, Canonical(SaveRoot)) &&
                Exact(GamePrefs.GetString(EnumGamePrefs.GameWorld), WorldName) &&
                Exact(GamePrefs.GetString(EnumGamePrefs.GameName), GameName) &&
                !GamePrefs.GetBool(EnumGamePrefs.EACEnabled) &&
                !GameManager.IsDedicatedServer &&
                ConnectionManager.Instance != null &&
                ConnectionManager.Instance.IsServer &&
                ConnectionManager.Instance.IsSinglePlayer &&
                GameManager.Instance != null && GameManager.Instance.World != null;
        }

        internal static bool IsApprovedNewGame(ModEvents.SPlayerSpawnedInWorldData data)
        {
            return data.IsLocalPlayer && data.RespawnType == RespawnType.NewGame &&
                IsApprovedEnvironment();
        }

        private static bool Exact(string left, string right)
        {
            return string.Equals(left, right, StringComparison.Ordinal);
        }

        private static string Canonical(string path)
        {
            return Path.GetFullPath(path).TrimEnd(
                Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        }
    }
}
