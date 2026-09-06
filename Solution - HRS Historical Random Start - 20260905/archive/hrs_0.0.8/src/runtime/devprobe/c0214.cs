using System;
using System.Collections.Generic;

namespace devprobe
{
    internal sealed class SanitizedGameLog
    {
        private const int EntryLimit = 64;
        private const int CharacterLimit = 256;
        private int entries;
        private bool limitReported;

        private static readonly HashSet<string> AllowedReasons = new HashSet<string>(StringComparer.Ordinal)
        {
            "OBS_READY", "OBS_BUILD_MISMATCH", "OBS_TARGET_MISMATCH",
            "OBS_EAC_NOT_DISABLED", "OBS_NOT_SERVER", "OBS_LIFECYCLE_REJECTED",
            "OBS_ENTITY_UNRESOLVED", "OBS_ELIGIBLE_NEW_CHARACTER",
            "OBS_DUPLICATE_SUPPRESSED", "OBS_DUPLICATE_CAPACITY",
            "OBS_LIMIT_REACHED", "OBS_INTERNAL_FAILURE"
        };

        internal bool HasCapacity { get { return entries < EntryLimit; } }

        internal void Write(string reason, string authority, string locality,
            string lifecycle, bool entityResolved, int suppressedCount, long elapsedMilliseconds)
        {
            if (!AllowedReasons.Contains(reason))
            {
                reason = "OBS_INTERNAL_FAILURE";
            }

            if (entries >= EntryLimit)
            {
                if (!limitReported)
                {
                    limitReported = true;
                    Log.Warning("[HRS-P1] v=0.0.1 build=b14 reason=OBS_LIMIT_REACHED");
                }
                return;
            }

            int boundedCount = Math.Max(0, Math.Min(128, suppressedCount));
            long boundedElapsed = Math.Max(0L, Math.Min(5000L, elapsedMilliseconds));
            string line = string.Format(
                "[HRS-P1] v=0.0.1 build=b14 authority={0} locality={1} lifecycle={2} entity={3} count={4} elapsedMs={5} reason={6}",
                Token(authority), Token(locality), Token(lifecycle), entityResolved ? "true" : "false",
                boundedCount, boundedElapsed, reason);
            if (line.Length > CharacterLimit)
            {
                line = line.Substring(0, CharacterLimit);
            }

            entries++;
            if (reason == "OBS_BUILD_MISMATCH" || reason == "OBS_INTERNAL_FAILURE")
            {
                Log.Error(line);
            }
            else if (reason == "OBS_TARGET_MISMATCH" || reason == "OBS_NOT_SERVER")
            {
                Log.Warning(line);
            }
            else
            {
                Log.Out(line);
            }
        }

        private static string Token(string value)
        {
            if (string.IsNullOrEmpty(value)) return "none";
            for (int i = 0; i < value.Length; i++)
            {
                char c = value[i];
                if (!(char.IsLetterOrDigit(c) || c == '_' || c == '-')) return "invalid";
            }
            return value.Length <= 32 ? value : value.Substring(0, 32);
        }
    }
}
