using System;
using System.IO;

namespace BitWrecked.HistoricalRandomStart
{
    internal sealed class OwnedBridgePaths
    {
        internal const string ReleaseFolderName = "BitWrecked_HistoricalRandomStart";
        internal const string ReleaseAssemblyName = "HistoricalRandomStart.dll";

        private OwnedBridgePaths(string gameRoot, string releaseRoot,
            string bridgeRoot, string policyPath, string resultPath)
        {
            GameRoot = gameRoot;
            ReleaseRoot = releaseRoot;
            BridgeRoot = bridgeRoot;
            PolicyPath = policyPath;
            ResultPath = resultPath;
        }

        internal string GameRoot { get; private set; }
        internal string ReleaseRoot { get; private set; }
        internal string BridgeRoot { get; private set; }
        internal string PolicyPath { get; private set; }
        internal string ResultPath { get; private set; }

        internal static bool TryResolve(out OwnedBridgePaths paths)
        {
            paths = null;
            try
            {
                string gameRoot = Canonical(AppDomain.CurrentDomain.BaseDirectory);
                string assemblyPath = Path.GetFullPath(
                    typeof(HistoricalRandomStartModApi).Assembly.Location);
                string releaseRoot = Canonical(Path.GetDirectoryName(assemblyPath));
                string expectedReleaseRoot = Canonical(Path.Combine(gameRoot,
                    "Mods", ReleaseFolderName));
                string bridgeRoot = Canonical(Path.Combine(releaseRoot, "Bridge"));
                string policyPath = Path.GetFullPath(Path.Combine(bridgeRoot,
                    "policy.v1.json"));
                string resultPath = Path.GetFullPath(Path.Combine(bridgeRoot,
                    "result.v1.json"));

                if (!ExactPath(releaseRoot, expectedReleaseRoot)) return false;
                if (!string.Equals(new DirectoryInfo(releaseRoot).Name,
                    ReleaseFolderName, StringComparison.Ordinal)) return false;
                if (!string.Equals(new DirectoryInfo(bridgeRoot).Name,
                    "Bridge", StringComparison.Ordinal)) return false;
                if (!string.Equals(Path.GetFileName(assemblyPath),
                    ReleaseAssemblyName, StringComparison.OrdinalIgnoreCase)) return false;
                if (!Contained(gameRoot, releaseRoot) ||
                    !Contained(releaseRoot, bridgeRoot)) return false;
                if (!Directory.Exists(gameRoot) || !Directory.Exists(releaseRoot) ||
                    !Directory.Exists(bridgeRoot) || !File.Exists(assemblyPath)) return false;
                if (HasReparsePoint(gameRoot) || HasReparsePoint(releaseRoot) ||
                    HasReparsePoint(bridgeRoot) || HasReparsePoint(assemblyPath)) return false;
                if (!BridgeEntriesAreOwned(bridgeRoot, policyPath, resultPath)) return false;

                paths = new OwnedBridgePaths(gameRoot, releaseRoot, bridgeRoot,
                    policyPath, resultPath);
                return true;
            }
            catch
            {
                paths = null;
                return false;
            }
        }

        internal bool RevalidateForResultWrite()
        {
            try
            {
                if (!Directory.Exists(GameRoot) || !Directory.Exists(ReleaseRoot) ||
                    !Directory.Exists(BridgeRoot)) return false;
                if (!string.Equals(new DirectoryInfo(ReleaseRoot).Name,
                    ReleaseFolderName, StringComparison.Ordinal) ||
                    !string.Equals(new DirectoryInfo(BridgeRoot).Name,
                    "Bridge", StringComparison.Ordinal)) return false;
                if (!ExactPath(ReleaseRoot, Canonical(Path.Combine(GameRoot,
                    "Mods", ReleaseFolderName)))) return false;
                if (!Contained(GameRoot, ReleaseRoot) ||
                    !Contained(ReleaseRoot, BridgeRoot)) return false;
                if (HasReparsePoint(GameRoot) || HasReparsePoint(ReleaseRoot) ||
                    HasReparsePoint(BridgeRoot)) return false;
                return BridgeEntriesAreOwned(BridgeRoot, PolicyPath, ResultPath);
            }
            catch
            {
                return false;
            }
        }

        private static bool BridgeEntriesAreOwned(string bridgeRoot,
            string policyPath, string resultPath)
        {
            foreach (string entry in Directory.EnumerateFileSystemEntries(bridgeRoot))
            {
                string leaf = Path.GetFileName(entry);
                if (!string.Equals(leaf, "policy.v1.json", StringComparison.Ordinal) &&
                    !string.Equals(leaf, "result.v1.json", StringComparison.Ordinal))
                    return false;
                if (!File.Exists(entry) || Directory.Exists(entry) || HasReparsePoint(entry))
                    return false;
            }

            if ((File.Exists(policyPath) && HasReparsePoint(policyPath)) ||
                (File.Exists(resultPath) && HasReparsePoint(resultPath))) return false;
            return true;
        }

        private static bool HasReparsePoint(string path)
        {
            string current = Canonical(path);
            while (!string.IsNullOrEmpty(current))
            {
                if (Directory.Exists(current) || File.Exists(current))
                {
                    FileAttributes attributes = File.GetAttributes(current);
                    if ((attributes & FileAttributes.ReparsePoint) != 0) return true;
                }

                string parent = Path.GetDirectoryName(current);
                if (string.IsNullOrEmpty(parent) ||
                    string.Equals(parent, current, StringComparison.OrdinalIgnoreCase)) break;
                current = parent;
            }
            return false;
        }

        private static bool Contained(string parent, string child)
        {
            string prefix = Canonical(parent) + Path.DirectorySeparatorChar;
            return Canonical(child).StartsWith(prefix,
                StringComparison.OrdinalIgnoreCase);
        }

        private static bool ExactPath(string left, string right)
        {
            return string.Equals(Canonical(left), Canonical(right),
                StringComparison.OrdinalIgnoreCase);
        }

        private static string Canonical(string path)
        {
            string full = Path.GetFullPath(path);
            string root = Path.GetPathRoot(full);
            if (string.Equals(full, root, StringComparison.OrdinalIgnoreCase)) return full;
            return full.TrimEnd(Path.DirectorySeparatorChar,
                Path.AltDirectorySeparatorChar);
        }
    }
}
