using System;
using System.Collections.Generic;
using System.Globalization;

namespace main
{
    internal sealed class ResultV1
    {
        internal const string SchemaName = "hrs-result/v1";
        internal const string ZeroDigest =
            "0000000000000000000000000000000000000000000000000000000000000000";

        private ResultV1(ulong policyRevision, string policyDigest,
            string outcome, string reason, string markerState, string observedUtc)
        {
            PolicyRevision = policyRevision;
            PolicyDigest = policyDigest;
            Outcome = outcome;
            Reason = reason;
            MarkerState = markerState;
            ObservedUtc = observedUtc;
        }

        internal ulong PolicyRevision { get; private set; }
        internal string PolicyDigest { get; private set; }
        internal string Outcome { get; private set; }
        internal string Reason { get; private set; }
        internal string MarkerState { get; private set; }
        internal string ObservedUtc { get; private set; }

        internal static bool TryCreate(PolicyV1 policy, string outcome,
            string reason, string markerState, out ResultV1 result)
        {
            ulong revision = policy == null ? 0UL : policy.Revision;
            string digest = policy == null ? ZeroDigest : policy.PolicyDigest;
            if (!ResultContract.IsValid(outcome, reason, markerState))
            {
                result = null;
                return false;
            }

            result = new ResultV1(revision, digest, outcome, reason, markerState,
                DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ",
                    CultureInfo.InvariantCulture));
            return true;
        }
    }

    internal static class ResultContract
    {
        private static readonly HashSet<string> AllowedReasons =
            new HashSet<string>(StringComparer.Ordinal)
            {
                "STANDARD_BYPASS", "PLACEMENT_DEFERRED", "RELOCATION_COMPLETED",
                "BUILD_MISMATCH", "RUNTIME_LANE_UNCONFIRMED", "POLICY_MISSING",
                "POLICY_REJECTED", "GAME_NAME_MISMATCH", "NOT_SERVER",
                "EXECUTION_REJECTED", "LIFECYCLE_REJECTED", "ENTITY_UNRESOLVED",
                "MARKER_API_UNAVAILABLE", "MARKER_CONSUMED", "MARKER_INVALID",
                "RESERVATION_FAILED", "SPAWN_LIST_UNAVAILABLE", "CANDIDATE_UNDEFINED",
                "CANDIDATE_INVALID", "CANDIDATE_OUT_OF_BOUNDS", "OBSERVER_UNAVAILABLE",
                "PLACEMENT_FAILED", "SEMANTIC_CHANGED", "VERIFY_CONTEXT_FAILED",
                "VERIFY_CHUNK_TIMEOUT", "VERIFY_UNSAFE", "VERIFY_POSITION_MISMATCH",
                "COMPLETION_FAILED", "INTERNAL_FAILURE"
            };

        internal static bool IsValid(string outcome, string reason, string markerState)
        {
            if (!AllowedReasons.Contains(reason)) return false;
            if (string.Equals(outcome, "BYPASSED", StringComparison.Ordinal))
                return string.Equals(reason, "STANDARD_BYPASS", StringComparison.Ordinal) &&
                    string.Equals(markerState, "NOT_APPLICABLE", StringComparison.Ordinal);
            if (string.Equals(outcome, "RESERVED", StringComparison.Ordinal))
                return string.Equals(reason, "PLACEMENT_DEFERRED", StringComparison.Ordinal) &&
                    string.Equals(markerState, "RESERVED", StringComparison.Ordinal);
            if (string.Equals(outcome, "COMPLETED", StringComparison.Ordinal))
                return string.Equals(reason, "RELOCATION_COMPLETED", StringComparison.Ordinal) &&
                    string.Equals(markerState, "COMPLETED", StringComparison.Ordinal);
            if (string.Equals(outcome, "INCOMPATIBLE", StringComparison.Ordinal))
                return (string.Equals(reason, "BUILD_MISMATCH", StringComparison.Ordinal) ||
                    string.Equals(reason, "RUNTIME_LANE_UNCONFIRMED", StringComparison.Ordinal)) &&
                    string.Equals(markerState, "NOT_APPLICABLE", StringComparison.Ordinal);
            if (string.Equals(outcome, "REJECTED", StringComparison.Ordinal))
                return string.Equals(markerState, "ABSENT", StringComparison.Ordinal) ||
                    string.Equals(markerState, "INVALID", StringComparison.Ordinal) ||
                    string.Equals(markerState, "NOT_APPLICABLE", StringComparison.Ordinal);
            if (string.Equals(outcome, "FAILED", StringComparison.Ordinal))
                return string.Equals(markerState, "RESERVED", StringComparison.Ordinal) ||
                    string.Equals(markerState, "INVALID", StringComparison.Ordinal) ||
                    string.Equals(markerState, "NOT_APPLICABLE", StringComparison.Ordinal);
            return false;
        }

        internal static string Serialize(ResultV1 result)
        {
            return "{\"schema\":\"" + ResultV1.SchemaName +
                "\",\"policyRevision\":" + result.PolicyRevision.ToString(
                    CultureInfo.InvariantCulture) +
                ",\"policyDigest\":\"" + result.PolicyDigest +
                "\",\"outcome\":\"" + result.Outcome +
                "\",\"reason\":\"" + result.Reason +
                "\",\"markerState\":\"" + result.MarkerState +
                "\",\"observedUtc\":\"" + result.ObservedUtc + "\"}";
        }
    }
}
