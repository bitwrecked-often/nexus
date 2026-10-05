using System;
using System.Collections.Generic;
using System.Globalization;
using UnityEngine;

namespace BitWrecked.HistoricalRandomStart
{
    internal sealed class SanitizedRuntimeLog
    {
        private const int Limit = 64;
        private readonly object sync = new object();
        private int entries;
        private static readonly HashSet<string> Allowed =
            new HashSet<string>(StringComparer.Ordinal)
            {
                "RUNTIME_READY", "RESULT_WRITE_FAILED", "PLACEMENT_CALLED",
                "SEMANTIC_UNCHANGED", "STANDARD_BYPASS", "PLACEMENT_DEFERRED",
                "RELOCATION_COMPLETED", "BUILD_MISMATCH", "BUILD_UNVERIFIED",
                "RUNTIME_LANE_UNCONFIRMED", "POLICY_MISSING", "POLICY_REJECTED",
                "GAME_NAME_MISMATCH", "NOT_SERVER", "EXECUTION_REJECTED",
                "LIFECYCLE_REJECTED", "ENTITY_UNRESOLVED", "MARKER_API_UNAVAILABLE",
                "MARKER_CONSUMED", "MARKER_INVALID", "RESERVATION_FAILED",
                "SPAWN_LIST_UNAVAILABLE", "CANDIDATE_UNDEFINED", "CANDIDATE_INVALID",
                "CANDIDATE_OUT_OF_BOUNDS", "POI_POOL_EMPTY", "OBSERVER_UNAVAILABLE", "PLACEMENT_FAILED",
                "SEMANTIC_CHANGED", "VERIFY_CONTEXT_FAILED", "VERIFY_CHUNK_TIMEOUT",
                "VERIFY_UNSAFE", "VERIFY_POSITION_MISMATCH", "COMPLETION_FAILED",
                "INTERNAL_FAILURE", "NG01", "NG02", "NG03", "NG04", "NG05",
                "NG06", "NG07", "NG08", "NG09", "NG10", "NG11", "NG12",
                "CANDIDATE_LOAD_REQUESTED", "CANDIDATE_LOAD_RESTORED",
                "CANDIDATE_PRIME_WAIT", "CANDIDATE_ADJUSTED",
                "POI_RETRY",
                "CANDIDATE_SURFACE_SETTLED", "INITIAL_BIOME_STORED",
                "INITIAL_BIOME_FAILED", "ARRIVAL_PROTECTION_ENABLED"
                , "TRADER_ROUTE_READY", "TRADER_ROUTE_RESERVED",
                "TRADER_ROUTE_SELECTED", "TRADER_ROUTE_COMPLETED",
                "TRADER_ROUTE_FALLBACK", "TRADER_ROUTE_SAME_BIOME",
                "TRADER_ROUTE_CROSS_BIOME", "TRADER_POOL_EMPTY",
                "TRADER_METADATA_UNAVAILABLE", "TRADER_METADATA_WAIT",
                "TRADER_METADATA_READY", "TRADER_ROUTE_JOURNAL_NONEMPTY",
                "TRADER_ROUTE_QUEST_SEEN", "TRADER_ROUTE_WAIT_TRADERS",
                "INTRO_ROUTE_PATCH_READY", "INTRO_ROUTE_FILTER_APPLIED",
                "INTRO_ROUTE_FALLBACK", "REQUESTED_BIOME_ABSENT",
                "WEIGHTED_POOL_EMPTY", "POI_SAFETY_EXHAUSTED"
            };

        internal void Write(string reason)
        {
            lock (sync)
            {
                if (entries >= Limit) return;
                if (!Allowed.Contains(reason)) reason = "INTERNAL_FAILURE";
                entries++;
                Log.Out("[HRS] v=1.2.7 build=r127 reason=" + reason);
            }
        }

        internal void WriteTraderSelection(PlacedTrader trader,
            bool crossedBiome)
        {
            if (trader == null) return;
            lock (sync)
            {
                if (entries >= Limit) return;
                entries++;
                Log.Out(string.Format(CultureInfo.InvariantCulture,
                    "[HRS] v=1.2.7 build=r127 reason=TRADER_ROUTE_SELECTED placedId={0} biome={1} crossBiome={2} origin={3},{4},{5} size={6},{7},{8}",
                    trader.InstanceId, trader.BiomeId,
                    crossedBiome ? 1 : 0,
                    trader.Location.x, trader.Location.y, trader.Location.z,
                    trader.Size.x, trader.Size.y, trader.Size.z));
            }
        }

        internal void WriteBiomeSelection(BiomePreference preference, string eligible,
            int selected, string reason)
        {
            lock (sync)
            {
                if (entries >= Limit || !preference.IsValid(false)) return;
                entries++;
                Log.Out("[HRS] v=1.2.7 build=r127 reason=" + reason +
                    " requested=" + preference.Diagnostic() + " eligible=" + eligible +
                    " selected=" + selected.ToString(System.Globalization.CultureInfo.InvariantCulture));
            }
        }

        internal void WritePoiAttempt(ResolvedPoi poi, int attempt)
        {
            if (poi == null) return;
            lock (sync)
            {
                if (entries >= Limit) return;
                entries++;
                Log.Out(string.Format(CultureInfo.InvariantCulture,
                    "[HRS] v=1.2.7 build=r127 reason=POI_ATTEMPT_SELECTED attempt={0} prefab={1} placedId={2} biome={3} origin={4},{5},{6} size={7},{8},{9} rotation={10}",
                    attempt, poi.PrefabName, poi.InstanceId, poi.BiomeId,
                    poi.Origin.x, poi.Origin.y, poi.Origin.z,
                    poi.Size.x, poi.Size.y, poi.Size.z, poi.Rotation));
            }
        }

        internal void WritePoiCompleted(ResolvedPoi poi, int attempt,
            Vector3 landing)
        {
            if (poi == null) return;
            lock (sync)
            {
                if (entries >= Limit) return;
                entries++;
                Log.Out(string.Format(CultureInfo.InvariantCulture,
                    "[HRS] v=1.2.7 build=r127 reason=POI_LANDING_COMPLETED attempt={0} prefab={1} placedId={2} biome={3} position={4:F1},{5:F1},{6:F1}",
                    attempt, poi.PrefabName, poi.InstanceId, poi.BiomeId,
                    landing.x, landing.y, landing.z));
            }
        }
    }
}
