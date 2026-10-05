using System;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace BitWrecked.HistoricalRandomStart
{
    internal sealed class PolicyV2
    {
        internal const string SchemaName = "hrs-policy/v2";

        internal PolicyV2(ulong revision, string gameName, string mode,
            bool enabled, BiomePreference preference, string writtenUtc, string policyDigest)
        {
            Revision = revision;
            GameName = gameName;
            Mode = mode;
            Enabled = enabled;
            Preference = preference;
            WrittenUtc = writtenUtc;
            PolicyDigest = policyDigest;
        }

        internal ulong Revision { get; private set; }
        internal string GameName { get; private set; }
        internal string Mode { get; private set; }
        internal bool Enabled { get; private set; }
        internal BiomePreference Preference { get; private set; }
        internal string WrittenUtc { get; private set; }
        internal string PolicyDigest { get; private set; }

        internal bool IsStandard
        {
            get { return string.Equals(Mode, "Standard", StringComparison.Ordinal); }
        }

        internal bool IsRandom
        {
            get { return string.Equals(Mode, "Random", StringComparison.Ordinal) ||
                string.Equals(Mode, "RandomSafe", StringComparison.Ordinal); }
        }

        internal bool ProtectArrivalBiome
        {
            get { return string.Equals(Mode, "RandomSafe", StringComparison.Ordinal); }
        }
    }

    internal static class PolicyV2Codec
    {
        internal const int MaximumBytes = 4096;
        private static readonly UTF8Encoding StrictUtf8 = new UTF8Encoding(false, true);
        private static readonly Regex CanonicalShape = new Regex(
            @"^\{""schema"":""(?<schema>[^""\\]*)"",""revision"":(?<revision>[0-9]+),""gameName"":""(?<gameName>[^""\\]*)"",""mode"":""(?<mode>[^""\\]*)"",""enabled"":(?<enabled>true|false),""selection"":""(?<selection>[^""\\]*)"",""chosenBiome"":(?<chosenBiome>[0-9]+),""forest"":(?<forest>[0-9]+),""burntForest"":(?<burntForest>[0-9]+),""desert"":(?<desert>[0-9]+),""snow"":(?<snow>[0-9]+),""wasteland"":(?<wasteland>[0-9]+),""writtenUtc"":""(?<writtenUtc>[^""\\]*)"",""policyDigest"":""(?<policyDigest>[0-9A-Fa-f]{64})""\}$",
            RegexOptions.CultureInvariant);

        internal static bool TryRead(string path, out PolicyV2 policy, out string reason)
        {
            policy = null;
            reason = "POLICY_REJECTED";
            try
            {
                if (!File.Exists(path))
                {
                    reason = "POLICY_MISSING";
                    return false;
                }

                FileInfo info = new FileInfo(path);
                if (info.Length < 1 || info.Length > MaximumBytes) return false;
                byte[] bytes = File.ReadAllBytes(info.FullName);
                if (bytes.Length < 1 || bytes.Length > MaximumBytes) return false;
                if (bytes.Length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB &&
                    bytes[2] == 0xBF) return false;

                string json = StrictUtf8.GetString(bytes);
                Match match = CanonicalShape.Match(json);
                if (!match.Success) return false;

                ulong revision;
                if (!ulong.TryParse(match.Groups["revision"].Value,
                    NumberStyles.None, CultureInfo.InvariantCulture, out revision) ||
                    revision < 1UL) return false;

                string schema = match.Groups["schema"].Value;
                string gameName = match.Groups["gameName"].Value;
                string mode = match.Groups["mode"].Value;
                bool enabled = string.Equals(match.Groups["enabled"].Value,
                    "true", StringComparison.Ordinal);
                string writtenUtc = match.Groups["writtenUtc"].Value;
                string digest = match.Groups["policyDigest"].Value.ToUpperInvariant();

                if (!string.Equals(schema, PolicyV2.SchemaName, StringComparison.Ordinal))
                    return false;
                if (!ExactGameName.IsValid(gameName)) return false;
                if (!string.Equals(mode, "Standard", StringComparison.Ordinal) &&
                    !string.Equals(mode, "Random", StringComparison.Ordinal) &&
                    !string.Equals(mode, "RandomSafe", StringComparison.Ordinal)) return false;
                if ((!string.Equals(mode, "Standard", StringComparison.Ordinal)) != enabled)
                    return false;

                int chosen;
                if (!int.TryParse(match.Groups["chosenBiome"].Value, out chosen)) return false;
                string[] names = { "forest", "burntForest", "desert", "snow", "wasteland" };
                int[] weights = new int[5];
                for (int i = 0; i < 5; i++)
                    if (!int.TryParse(match.Groups[names[i]].Value, out weights[i])) return false;
                var preference = new BiomePreference(match.Groups["selection"].Value, chosen, weights);
                if (!preference.IsValid(mode == "Standard")) return false;

                DateTime timestamp;
                if (!DateTime.TryParseExact(writtenUtc, "yyyy-MM-ddTHH:mm:ss.fffZ",
                    CultureInfo.InvariantCulture,
                    DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal,
                    out timestamp)) return false;
                if (!string.Equals(timestamp.ToUniversalTime().ToString(
                    "yyyy-MM-ddTHH:mm:ss.fffZ", CultureInfo.InvariantCulture),
                    writtenUtc, StringComparison.Ordinal)) return false;

                string expectedDigest = ComputeDigest(revision, gameName, mode,
                    enabled, preference, writtenUtc);
                if (!string.Equals(expectedDigest, digest, StringComparison.Ordinal))
                    return false;

                PolicyV2 candidate = new PolicyV2(revision, gameName, mode,
                    enabled, preference, writtenUtc, digest);
                if (!string.Equals(Serialize(candidate), json, StringComparison.Ordinal))
                    return false;

                policy = candidate;
                reason = "POLICY_VALID";
                return true;
            }
            catch
            {
                policy = null;
                reason = "POLICY_REJECTED";
                return false;
            }
        }

        internal static string Serialize(PolicyV2 policy)
        {
            return "{\"schema\":\"" + PolicyV2.SchemaName +
                "\",\"revision\":" + policy.Revision.ToString(CultureInfo.InvariantCulture) +
                ",\"gameName\":\"" + policy.GameName +
                "\",\"mode\":\"" + policy.Mode +
                "\",\"enabled\":" + (policy.Enabled ? "true" : "false") +
                policy.Preference.JsonFields() + ",\"writtenUtc\":\"" + policy.WrittenUtc +
                "\",\"policyDigest\":\"" + policy.PolicyDigest + "\"}";
        }

        internal static string ComputeDigest(ulong revision, string gameName,
            string mode, bool enabled, BiomePreference preference, string writtenUtc)
        {
            string preimage = PolicyV2.SchemaName + "\n" +
                revision.ToString(CultureInfo.InvariantCulture) + "\n" +
                gameName + "\n" + mode + "\n" +
                (enabled ? "true" : "false") + "\n" + preference.DigestFields() + "\n" + writtenUtc;
            byte[] bytes = StrictUtf8.GetBytes(preimage);
            using (SHA256 sha = SHA256.Create())
            {
                return BitConverter.ToString(sha.ComputeHash(bytes)).Replace("-", "");
            }
        }
    }
}
