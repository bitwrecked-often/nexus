using System;
using System.Collections.Generic;

namespace reloc
{
    internal sealed class SanitizedRelocationLog
    {
        private const int Limit = 24;
        private int entries;
        private static readonly HashSet<string> Allowed = new HashSet<string>(StringComparer.Ordinal)
        {
            "RELOC_READY", "RELOC_BUILD_MISMATCH", "RELOC_TARGET_REJECTED",
            "RELOC_ENTITY_UNRESOLVED", "RELOC_MARKER_CONSUMED",
            "RELOC_RESERVATION_FAILED", "RELOC_LIST_UNAVAILABLE",
            "RELOC_CANDIDATE_UNDEFINED", "RELOC_CANDIDATE_INVALID",
            "RELOC_CANDIDATE_BOUNDS", "RELOC_OBSERVER_UNAVAILABLE",
            "RELOC_PLACEMENT_DEFERRED", "RELOC_PLACEMENT_CALLED",
            "RELOC_PLACEMENT_FAILED", "RELOC_VERIFY_CONTEXT_FAILED",
            "RELOC_VERIFY_CHUNK_TIMEOUT", "RELOC_VERIFY_UNSAFE",
            "RELOC_VERIFY_POSITION_MISMATCH",
            "RELOC_SEMANTIC_UNCHANGED", "RELOC_SEMANTIC_CHANGED",
            "RELOC_COMPLETION_FAILED", "RELOC_COMPLETED", "RELOC_INTERNAL_FAILURE"
        };

        internal void Write(string reason)
        {
            if (entries >= Limit) return;
            if (!Allowed.Contains(reason)) reason = "RELOC_INTERNAL_FAILURE";
            entries++;
            Log.Out("[HRS-P1A-RELOC] v=0.0.1 build=b14 reason=" + reason);
        }
    }
}
