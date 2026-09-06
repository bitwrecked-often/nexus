using System;
using System.IO;

namespace BitWrecked.HistoricalRandomStart.DevProbe
{
    internal static class TargetGuard
    {
        private const string ApprovedGameRoot = @"C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die";
        private const string ApprovedBuildStage = @"C:\BitWreckedDisposable\HRS_Phase1\BuildStage";
        private const string ApprovedSaveRoot = @"C:\Users\mobil\AppData\Roaming\7DaysToDie\Saves";
        private const string ApprovedWorld = "Navezgane";
        private const string ApprovedGame = "HRS_Phase1_Test_001";

        internal static bool IsApprovedCurrentTarget()
        {
            string runtimeRoot = Canonical(AppDomain.CurrentDomain.BaseDirectory);
            string saveRoot = Canonical(Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "7DaysToDie", "Saves"));

            if (!Exact(runtimeRoot, Canonical(ApprovedGameRoot)) ||
                !Exact(saveRoot, Canonical(ApprovedSaveRoot)) ||
                !IsExternalStageValid())
            {
                return false;
            }

            if (!Exact(GamePrefs.GetString(EnumGamePrefs.GameWorld), ApprovedWorld) ||
                !Exact(GamePrefs.GetString(EnumGamePrefs.GameName), ApprovedGame))
            {
                return false;
            }

            if (GamePrefs.GetBool(EnumGamePrefs.EACEnabled) ||
                GameManager.IsDedicatedServer ||
                ConnectionManager.Instance == null ||
                !ConnectionManager.Instance.IsSinglePlayer)
            {
                return false;
            }

            return GameManager.Instance != null && GameManager.Instance.World != null;
        }

        internal static string CurrentWorldKey()
        {
            World world = GameManager.Instance == null ? null : GameManager.Instance.World;
            return world == null || string.IsNullOrEmpty(world.Guid) ? "NO_WORLD" : world.Guid;
        }

        private static bool IsExternalStageValid()
        {
            string stage = Canonical(ApprovedBuildStage);
            string game = Canonical(ApprovedGameRoot);
            string saves = Canonical(ApprovedSaveRoot);
            string mods = Canonical(Path.Combine(ApprovedGameRoot, "Mods"));
            return !Within(stage, game) && !Within(stage, saves) && !Within(stage, mods);
        }

        private static bool Within(string candidate, string root)
        {
            string prefix = root.TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            return Exact(candidate, root) || candidate.StartsWith(prefix, StringComparison.OrdinalIgnoreCase);
        }

        private static bool Exact(string left, string right)
        {
            return string.Equals(left, right, StringComparison.Ordinal);
        }

        private static string Canonical(string path)
        {
            return Path.GetFullPath(path).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        }
    }
}
