using System;
using System.Collections.Generic;

namespace BitWrecked.HistoricalRandomStart
{
    internal sealed class SanitizedRuntimeLog
    {
        private const int Limit = 32;
        private readonly object sync = new object();
        private int entries;
        private static readonly HashSet<string> Allowed =
            new HashSet<string>(StringComparer.Ordinal)
            {
                "RUNTIME_READY", "RESULT_WRITE_FAILED", "PLACEMENT_CALLED",
                "SEMANTIC_UNCHANGED", "STANDARD_BYPASS", "PLACEMENT_DEFERRED",
                "RELOCATION_COMPLETED", "BUILD_MISMATCH",
                "RUNTIME_LANE_UNCONFIRMED", "POLICY_MISSING", "POLICY_REJECTED",
                "GAME_NAME_MISMATCH", "NOT_SERVER", "EXECUTION_REJECTED",
                "LIFECYCLE_REJECTED", "ENTITY_UNRESOLVED", "MARKER_API_UNAVAILABLE",
                "MARKER_CONSUMED", "MARKER_INVALID", "RESERVATION_FAILED",
                "SPAWN_LIST_UNAVAILABLE", "CANDIDATE_UNDEFINED", "CANDIDATE_INVALID",
                "CANDIDATE_OUT_OF_BOUNDS", "OBSERVER_UNAVAILABLE", "PLACEMENT_FAILED",
                "SEMANTIC_CHANGED", "VERIFY_CONTEXT_FAILED", "VERIFY_CHUNK_TIMEOUT",
                "VERIFY_UNSAFE", "VERIFY_POSITION_MISMATCH", "COMPLETION_FAILED",
                "INTERNAL_FAILURE", "NG01", "NG02", "NG03", "NG04", "NG05",
                "NG06", "NG07", "NG08", "NG09", "NG10", "NG11", "NG12",
                "CANDIDATE_LOAD_REQUESTED", "CANDIDATE_LOAD_RESTORED",
                "CANDIDATE_PRIME_WAIT", "CANDIDATE_ADJUSTED",
                "CANDIDATE_SURFACE_SETTLED"
                , "TRADER_ROUTE_READY", "TRADER_ROUTE_RESERVED",
                "TRADER_ROUTE_SELECTED", "TRADER_ROUTE_COMPLETED",
                "TRADER_ROUTE_FALLBACK", "TRADER_ROUTE_JOURNAL_NONEMPTY",
                "TRADER_ROUTE_QUEST_SEEN", "TRADER_ROUTE_WAIT_TRADERS"
            };

        internal void Write(string reason)
        {
            lock (sync)
            {
                if (entries >= Limit) return;
                if (!Allowed.Contains(reason)) reason = "INTERNAL_FAILURE";
                entries++;
                Log.Out("[HRS] v=1.1.0 build=r110 reason=" + reason);
            }
        }
    }
}
