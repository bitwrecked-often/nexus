using System;
using System.IO;

namespace BitWrecked.HistoricalRandomStart.Phase1A.MarkerProbe
{
    internal static class TargetGuard
    {
        private const string ApprovedGameRoot = @"C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die";
        private const string ApprovedSaveRoot = @"C:\Users\mobil\AppData\Roaming\7DaysToDie\Saves";
        private const string ApprovedWorld = "Navezgane";
        private const string ApprovedGame = "HRS_Phase1A_Test_001";

        internal static bool IsApprovedLocalTarget(ModEvents.SPlayerSpawnedInWorldData data)
        {
            if (!data.IsLocalPlayer)
            {
                return false;
            }

            string runtimeRoot = Canonical(AppDomain.CurrentDomain.BaseDirectory);
            string saveRoot = Canonical(Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "7DaysToDie", "Saves"));

            if (!Exact(runtimeRoot, Canonical(ApprovedGameRoot)) ||
                !Exact(saveRoot, Canonical(ApprovedSaveRoot)) ||
                !Exact(GamePrefs.GetString(EnumGamePrefs.GameWorld), ApprovedWorld) ||
                !Exact(GamePrefs.GetString(EnumGamePrefs.GameName), ApprovedGame))
            {
                return false;
            }

            return !GamePrefs.GetBool(EnumGamePrefs.EACEnabled) &&
                !GameManager.IsDedicatedServer &&
                ConnectionManager.Instance != null &&
                ConnectionManager.Instance.IsServer &&
                ConnectionManager.Instance.IsSinglePlayer &&
                GameManager.Instance != null &&
                GameManager.Instance.World != null;
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
