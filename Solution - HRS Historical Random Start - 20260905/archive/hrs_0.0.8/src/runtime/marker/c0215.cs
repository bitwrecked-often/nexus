using System;
using System.Collections.Generic;

namespace marker
{
    internal sealed class SanitizedMarkerLog
    {
        private const int EntryLimit = 16;
        private int entries;

        private static readonly HashSet<string> Allowed = new HashSet<string>(StringComparer.Ordinal)
        {
            "MARKER_READY", "MARKER_BUILD_MISMATCH", "MARKER_TARGET_REJECTED",
            "MARKER_ENTITY_UNRESOLVED", "MARKER_ALREADY_CONSUMED",
            "MARKER_RESERVED_VERIFIED", "MARKER_RESERVATION_FAILED",
            "MARKER_RELOAD_RESERVED", "MARKER_RELOAD_COMPLETED",
            "MARKER_RELOAD_ABSENT", "MARKER_RELOAD_INVALID",
            "MARKER_LIFECYCLE_REJECTED",
            "MARKER_INTERNAL_FAILURE"
        };

        internal void Write(string reason)
        {
            if (entries >= EntryLimit) return;
            if (!Allowed.Contains(reason)) reason = "MARKER_INTERNAL_FAILURE";
            entries++;
            Log.Out("[HRS-P1A-MARKER] v=0.0.1 build=b14 reason=" + reason);
        }
    }
}
