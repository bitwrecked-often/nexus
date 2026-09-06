using System;
using UnityEngine;

namespace BitWrecked.HistoricalRandomStart
{
    internal sealed class CuratedStartPoint
    {
        internal readonly string Id;
        internal readonly string Experience;
        internal readonly int X;
        internal readonly int Y;
        internal readonly int Z;

        internal CuratedStartPoint(string id, string experience, int x, int y,
            int z)
        {
            Id = id;
            Experience = experience;
            X = x;
            Y = y;
            Z = z;
        }
    }

    internal static class NavezganeStartCatalog
    {
        private const string WorldName = "Navezgane";
        private const int CoordinateLimit = 2500;
        private const int LandingSearchRadius = 32;
        private const int LandingSearchStep = 4;
        private const int MaximumTerrainDelta = 24;
        // Release-approved pool: NG01 and NG02 only. The remaining entries are
        // survey data and cannot become selectable merely by extending Points.
        private static readonly int[] ApprovedPointIndices = { 0, 1 };
        // Mod-owned X/Z survey anchors. No vanilla world file is edited or
        // treated as storage. Terrain Y and final safety remain runtime facts.
        private static readonly CuratedStartPoint[] Points =
        {
            new CuratedStartPoint("NG01", "Perishton snow city", -1528, 80, 1700),
            new CuratedStartPoint("NG02", "Remote snow edge", -2100, 218, 2100),
            new CuratedStartPoint("NG03", "National Forest", -900, 95, 1100),
            new CuratedStartPoint("NG04", "Forest lake", -1450, 58, 650),
            new CuratedStartPoint("NG05", "Western lake island", -1400, 58, 600),
            new CuratedStartPoint("NG06", "Diersville outskirts", 1750, 54, 500),
            new CuratedStartPoint("NG07", "Wasteland army camp", 1500, 70, 50),
            new CuratedStartPoint("NG08", "Desert canyon", 650, 60, -1850),
            new CuratedStartPoint("NG09", "Departure", 1750, 62, -1800),
            new CuratedStartPoint("NG10", "Gravestown", -1750, 62, -1800),
            new CuratedStartPoint("NG11", "Far northeast snow", 2200, 143, 1550),
            new CuratedStartPoint("NG12", "Southern frontier", 0, 74, -2400)
        };

        internal static CuratedStartPoint[] GetSurveyPoints()
        {
            return (CuratedStartPoint[])Points.Clone();
        }

        internal static bool TryResolve(World world, int pointIndex,
            out Vector3 candidate, out string pointId)
        {
            candidate = Vector3.zero;
            pointId = null;
            if (world == null || pointIndex < 0 || pointIndex >= Points.Length)
                return false;
            if (!string.Equals(GamePrefs.GetString(EnumGamePrefs.GameWorld),
                WorldName, StringComparison.Ordinal)) return false;

            CuratedStartPoint point = Points[pointIndex];
            if (Math.Abs(point.X) > CoordinateLimit ||
                Math.Abs(point.Z) > CoordinateLimit) return false;

            Vector3 resolved = new Vector3(point.X, point.Y + 1f, point.Z);
            if (!world.IsPositionInBounds(resolved)) return false;

            candidate = resolved;
            pointId = point.Id;
            return true;
        }

        internal static bool TrySelect(World world, out Vector3 candidate,
            out string pointId)
        {
            candidate = Vector3.zero;
            pointId = null;
            if (world == null || !string.Equals(
                GamePrefs.GetString(EnumGamePrefs.GameWorld), WorldName,
                StringComparison.Ordinal)) return false;
            int approvedSlot = world.GetGameRandom().RandomRange(
                ApprovedPointIndices.Length);
            int pointIndex = ApprovedPointIndices[approvedSlot];
            return TryResolve(world, pointIndex, out candidate, out pointId);
        }

        internal static bool TryFindSafeLanding(World world, Vector3 anchor,
            string pointId, int searchRadius, out Vector3 landing)
        {
            landing = Vector3.zero;
            CuratedStartPoint point;
            if (world == null || !TryGetPoint(pointId, out point) || searchRadius < 0 ||
                searchRadius > LandingSearchRadius) return false;
            for (int radius = 0; radius <= searchRadius;
                radius += LandingSearchStep)
            {
                if (radius == 0)
                {
                    if (TrySafeOffset(world, point, anchor, 0, 0, out landing)) return true;
                    continue;
                }
                for (int delta = -radius; delta <= radius;
                    delta += LandingSearchStep)
                {
                    if (TrySafeOffset(world, point, anchor, delta, -radius, out landing))
                        return true;
                    if (TrySafeOffset(world, point, anchor, delta, radius, out landing))
                        return true;
                }
                for (int delta = -radius + LandingSearchStep;
                    delta <= radius - LandingSearchStep;
                    delta += LandingSearchStep)
                {
                    if (TrySafeOffset(world, point, anchor, -radius, delta, out landing))
                        return true;
                    if (TrySafeOffset(world, point, anchor, radius, delta, out landing))
                        return true;
                }
            }
            return false;
        }

        internal static int GetSearchRadius(string pointId)
        {
            // Reviewed urban street anchors stay on their road corridor.
            if (string.Equals(pointId, "NG01", StringComparison.Ordinal)) return 8;
            return LandingSearchRadius;
        }

        private static bool TryGetPoint(string pointId, out CuratedStartPoint point)
        {
            point = null;
            for (int i = 0; i < Points.Length; i++)
            {
                if (!string.Equals(Points[i].Id, pointId,
                    StringComparison.Ordinal)) continue;
                point = Points[i];
                return true;
            }
            return false;
        }

        private static bool TrySafeOffset(World world, CuratedStartPoint point,
            Vector3 anchor,
            int offsetX, int offsetZ, out Vector3 candidate)
        {
            int x = (int)anchor.x + offsetX;
            int z = (int)anchor.z + offsetZ;
            float terrainY = world.GetTerrainHeight(x, z);
            candidate = new Vector3(x, terrainY + 1f, z);
            if (Math.Abs(terrainY - point.Y) > MaximumTerrainDelta) return false;
            if (!world.IsPositionInBounds(candidate)) return false;
            if (world.GetChunkFromWorldPos(World.worldToBlockPos(candidate)) == null)
                return false;
            return world.CanPlayersSpawnAtPos(candidate, false);
        }
    }

    internal static class RuntimeEnvironmentGuard
    {
        internal static string DenialReason(PolicyV1 policy,
            ModEvents.SPlayerSpawnedInWorldData data)
        {
            if (policy == null) return "POLICY_REJECTED";
            if (!CompatibilityGuard.IsCompatible()) return "BUILD_MISMATCH";
            if (GamePrefs.GetBool(EnumGamePrefs.EACEnabled))
                return "RUNTIME_LANE_UNCONFIRMED";
            if (!data.IsLocalPlayer) return "EXECUTION_REJECTED";
            if (GameManager.IsDedicatedServer) return "EXECUTION_REJECTED";
            if (ConnectionManager.Instance == null) return "EXECUTION_REJECTED";
            if (!ConnectionManager.Instance.IsServer) return "NOT_SERVER";
            if (!ConnectionManager.Instance.IsSinglePlayer) return "EXECUTION_REJECTED";
            if (GameManager.Instance == null || GameManager.Instance.World == null)
                return "EXECUTION_REJECTED";
            if (!string.Equals(GamePrefs.GetString(EnumGamePrefs.GameName),
                policy.GameName, StringComparison.Ordinal)) return "GAME_NAME_MISMATCH";
            return null;
        }

        internal static bool IsStillApproved(PolicyV1 policy)
        {
            return policy != null && CompatibilityGuard.IsCompatible() &&
                !GamePrefs.GetBool(EnumGamePrefs.EACEnabled) &&
                !GameManager.IsDedicatedServer &&
                ConnectionManager.Instance != null &&
                ConnectionManager.Instance.IsServer &&
                ConnectionManager.Instance.IsSinglePlayer &&
                GameManager.Instance != null && GameManager.Instance.World != null &&
                string.Equals(GamePrefs.GetString(EnumGamePrefs.GameName),
                    policy.GameName, StringComparison.Ordinal);
        }
    }
}
