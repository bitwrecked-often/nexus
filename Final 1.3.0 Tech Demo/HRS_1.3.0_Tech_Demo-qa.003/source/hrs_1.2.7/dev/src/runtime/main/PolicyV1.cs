using System;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace BitWrecked.HistoricalRandomStart
{
    internal sealed class PolicyV1
    {
        internal const string SchemaName = "hrs-policy/v1";

        internal PolicyV1(ulong revision, string gameName, string mode,
            bool enabled, string writtenUtc, string policyDigest)
        {
            Revision = revision;
            GameName = gameName;
            Mode = mode;
            Enabled = enabled;
            WrittenUtc = writtenUtc;
            PolicyDigest = policyDigest;
        }

        internal ulong Revision { get; private set; }
        internal string GameName { get; private set; }
        internal string Mode { get; private set; }
        internal bool Enabled { get; private set; }
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

    internal static class ExactGameName
    {
        private const int MaximumLength = 64;

        internal static bool IsValid(string value)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(value) || value.Length > MaximumLength)
                    return false;
                if (!string.Equals(value, value.Trim(), StringComparison.Ordinal))
                    return false;
                if (string.Equals(value, ".", StringComparison.Ordinal) ||
                    string.Equals(value, "..", StringComparison.Ordinal) ||
                    value.EndsWith(".", StringComparison.Ordinal))
                    return false;

                int dot = value.IndexOf('.');
                string stem = dot < 0 ? value : value.Substring(0, dot);
                if (IsReservedDeviceStem(stem)) return false;

                char[] invalid = Path.GetInvalidFileNameChars();
                for (int i = 0; i < value.Length; i++)
                {
                    char current = value[i];
                    if (char.IsControl(current) || Contains(invalid, current)) return false;
                }

                string normalized = value.Normalize(NormalizationForm.FormC);
                return string.Equals(normalized, value, StringComparison.Ordinal);
            }
            catch
            {
                return false;
            }
        }

        private static bool IsReservedDeviceStem(string value)
        {
            if (string.Equals(value, "CON", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(value, "PRN", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(value, "AUX", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(value, "NUL", StringComparison.OrdinalIgnoreCase))
                return true;

            if (value.Length == 4 &&
                (value.StartsWith("COM", StringComparison.OrdinalIgnoreCase) ||
                 value.StartsWith("LPT", StringComparison.OrdinalIgnoreCase)))
                return value[3] >= '1' && value[3] <= '9';

            return false;
        }

        private static bool Contains(char[] values, char candidate)
        {
            for (int i = 0; i < values.Length; i++)
                if (values[i] == candidate) return true;
            return false;
        }
    }

    internal static class PolicyV1Codec
    {
        internal const int MaximumBytes = 4096;
        private static readonly UTF8Encoding StrictUtf8 = new UTF8Encoding(false, true);
        private static readonly Regex CanonicalShape = new Regex(
            @"^\{""schema"":""(?<schema>[^""\\]*)"",""revision"":(?<revision>[0-9]+),""gameName"":""(?<gameName>[^""\\]*)"",""mode"":""(?<mode>[^""\\]*)"",""enabled"":(?<enabled>true|false),""writtenUtc"":""(?<writtenUtc>[^""\\]*)"",""policyDigest"":""(?<policyDigest>[0-9A-Fa-f]{64})""\}$",
            RegexOptions.CultureInvariant);

        internal static bool TryRead(string path, out PolicyV1 policy, out string reason)
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

                if (!string.Equals(schema, PolicyV1.SchemaName, StringComparison.Ordinal))
                    return false;
                if (!ExactGameName.IsValid(gameName)) return false;
                if (!string.Equals(mode, "Standard", StringComparison.Ordinal) &&
                    !string.Equals(mode, "Random", StringComparison.Ordinal) &&
                    !string.Equals(mode, "RandomSafe", StringComparison.Ordinal)) return false;
                if ((!string.Equals(mode, "Standard", StringComparison.Ordinal)) != enabled)
                    return false;

                DateTime timestamp;
                if (!DateTime.TryParseExact(writtenUtc, "yyyy-MM-ddTHH:mm:ss.fffZ",
                    CultureInfo.InvariantCulture,
                    DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal,
                    out timestamp)) return false;
                if (!string.Equals(timestamp.ToUniversalTime().ToString(
                    "yyyy-MM-ddTHH:mm:ss.fffZ", CultureInfo.InvariantCulture),
                    writtenUtc, StringComparison.Ordinal)) return false;

                string expectedDigest = ComputeDigest(revision, gameName, mode,
                    enabled, writtenUtc);
                if (!string.Equals(expectedDigest, digest, StringComparison.Ordinal))
                    return false;

                PolicyV1 candidate = new PolicyV1(revision, gameName, mode,
                    enabled, writtenUtc, digest);
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

        internal static string Serialize(PolicyV1 policy)
        {
            return "{\"schema\":\"" + PolicyV1.SchemaName +
                "\",\"revision\":" + policy.Revision.ToString(CultureInfo.InvariantCulture) +
                ",\"gameName\":\"" + policy.GameName +
                "\",\"mode\":\"" + policy.Mode +
                "\",\"enabled\":" + (policy.Enabled ? "true" : "false") +
                ",\"writtenUtc\":\"" + policy.WrittenUtc +
                "\",\"policyDigest\":\"" + policy.PolicyDigest + "\"}";
        }

        internal static string ComputeDigest(ulong revision, string gameName,
            string mode, bool enabled, string writtenUtc)
        {
            string preimage = PolicyV1.SchemaName + "\n" +
                revision.ToString(CultureInfo.InvariantCulture) + "\n" +
                gameName + "\n" + mode + "\n" +
                (enabled ? "true" : "false") + "\n" + writtenUtc;
            byte[] bytes = StrictUtf8.GetBytes(preimage);
            using (SHA256 sha = SHA256.Create())
            {
                return BitConverter.ToString(sha.ComputeHash(bytes)).Replace("-", "");
            }
        }
    }
}
