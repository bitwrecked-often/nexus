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
        // Release-approved pool: balanced 80-point certified NVG production set.
        // Full 171-point certified NVG library remains below as reserve/evidence.
        // NG01-NG12 remain survey/reference data and are not selectable.
        private static readonly int[] ApprovedPointIndices =
        {
            12, 13, 14, 16, 17, 18, 22, 23, 24, 25, 26, 28, 31, 38, 41, 46,
            48, 50, 51, 60, 61, 64, 66, 67, 68, 70, 71, 74, 82, 83, 85, 86,
            95, 96, 99, 101, 102, 103, 107, 110, 111, 112, 113, 114, 115, 116, 117, 118,
            119, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 132, 133, 134, 135, 136,
            137, 138, 139, 140, 141, 142, 154, 155, 158, 159, 164, 165, 166, 168, 170, 171
        };
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
            new CuratedStartPoint("NG12", "Southern frontier", 0, 74, -2400),
            new CuratedStartPoint("NVG-0281", "hospital_01", 1101, 61, 587),
            new CuratedStartPoint("NVG-0282", "hotel_01", 541, 61, -1434),
            new CuratedStartPoint("NVG-0283", "hotel_02", -1569, 203, 2069),
            new CuratedStartPoint("NVG-0284", "hotel_03", 1732, 61, -1945),
            new CuratedStartPoint("NVG-0285", "hotel_04", 1828, 61, -747),
            new CuratedStartPoint("NVG-0286", "hotel_ostrich", -1923, 61, -1912),
            new CuratedStartPoint("NVG-0287", "house_burnt_01", 522, 61, 194),
            new CuratedStartPoint("NVG-0288", "house_burnt_02", 648, 61, 104),
            new CuratedStartPoint("NVG-0289", "house_burnt_03", 479, 61, 148),
            new CuratedStartPoint("NVG-0290", "house_burnt_04", 622, 61, 155),
            new CuratedStartPoint("NVG-0291", "house_burnt_05", 523, 61, 52),
            new CuratedStartPoint("NVG-0292", "house_burnt_06", 576, 61, 150),
            new CuratedStartPoint("NVG-0293", "house_construction_01", 155, 61, 1340),
            new CuratedStartPoint("NVG-0294", "house_construction_03", 981, 61, 699),
            new CuratedStartPoint("NVG-0295", "house_country_01", 2322, 70, -1243),
            new CuratedStartPoint("NVG-0296", "house_modern_01", 331, 61, 1304),
            new CuratedStartPoint("NVG-0297", "house_modern_02", 367, 61, 1355),
            new CuratedStartPoint("NVG-0298", "house_modern_03", 2154, 70, -1243),
            new CuratedStartPoint("NVG-0299", "house_modern_04", 2235, 70, -1243),
            new CuratedStartPoint("NVG-0300", "house_modern_05", 145, 62, -1653),
            new CuratedStartPoint("NVG-0301", "house_modern_06", 43, 115, 2041),
            new CuratedStartPoint("NVG-0302", "house_modern_07", 2197, 70, -1294),
            new CuratedStartPoint("NVG-0303", "house_modern_08", 43, 115, 2133),
            new CuratedStartPoint("NVG-0304", "house_modern_09", 92, 115, 2085),
            new CuratedStartPoint("NVG-0305", "house_modern_10", 2280, 70, -1293),
            new CuratedStartPoint("NVG-0306", "house_modern_11", 92, 115, 2178),
            new CuratedStartPoint("NVG-0307", "house_modern_12", -1322, 66, -1115),
            new CuratedStartPoint("NVG-0308", "house_modern_15", 132, 62, -1714),
            new CuratedStartPoint("NVG-0309", "house_modern_16", 235, 91, -1252),
            new CuratedStartPoint("NVG-0310", "house_modern_17", 161, 62, -1806),
            new CuratedStartPoint("NVG-0311", "house_modern_18", 2369, 70, -1278),
            new CuratedStartPoint("NVG-0312", "house_modern_20", -441, 71, -1148),
            new CuratedStartPoint("NVG-0313", "house_modern_22", 195, 62, -1764),
            new CuratedStartPoint("NVG-0314", "house_modern_23", 1465, 68, -1284),
            new CuratedStartPoint("NVG-0315", "house_modern_26", -1390, 66, -1115),
            new CuratedStartPoint("NVG-0316", "house_modern_29", 1533, 68, -1284),
            new CuratedStartPoint("NVG-0317", "house_modern_31", -991, 92, 451),
            new CuratedStartPoint("NVG-0318", "house_old_bungalow_01", -1746, 81, 1729),
            new CuratedStartPoint("NVG-0319", "house_old_bungalow_02", 1168, 61, 699),
            new CuratedStartPoint("NVG-0320", "house_old_bungalow_03", -229, 63, -2091),
            new CuratedStartPoint("NVG-0321", "house_old_bungalow_04", -301, 63, -2091),
            new CuratedStartPoint("NVG-0322", "house_old_bungalow_05", -1693, 81, 1728),
            new CuratedStartPoint("NVG-0323", "house_old_bungalow_06", -265, 63, -2140),
            new CuratedStartPoint("NVG-0324", "house_old_bungalow_07", -281, 76, 1275),
            new CuratedStartPoint("NVG-0325", "house_old_bungalow_08", -2195, 75, 41),
            new CuratedStartPoint("NVG-0326", "house_old_bungalow_09", 570, 59, -8),
            new CuratedStartPoint("NVG-0327", "house_old_bungalow_10", 950, 77, -2299),
            new CuratedStartPoint("NVG-0328", "house_old_bungalow_11", 980, 70, -955),
            new CuratedStartPoint("NVG-0329", "house_old_bungalow_12", -227, 76, 1380),
            new CuratedStartPoint("NVG-0330", "house_old_cottage_01", 1024, 61, 699),
            new CuratedStartPoint("NVG-0331", "house_old_gambrel_01", 1168, 61, 768),
            new CuratedStartPoint("NVG-0332", "house_old_gambrel_02", 2299, 90, 835),
            new CuratedStartPoint("NVG-0333", "house_old_gambrel_03", -352, 61, 646),
            new CuratedStartPoint("NVG-0334", "house_old_mansard_01", 137, 76, 1713),
            new CuratedStartPoint("NVG-0335", "house_old_mansard_02", 1399, 71, 1081),
            new CuratedStartPoint("NVG-0336", "house_old_mansard_03", 939, 61, 699),
            new CuratedStartPoint("NVG-0337", "house_old_mansard_04", 1284, 61, 285),
            new CuratedStartPoint("NVG-0338", "house_old_mansard_05", -1870, 84, 1703),
            new CuratedStartPoint("NVG-0339", "house_old_mansard_06", 1301, 61, -1136),
            new CuratedStartPoint("NVG-0340", "house_old_mansard_07", 747, 161, 1570),
            new CuratedStartPoint("NVG-0341", "house_old_modular_01", 638, 54, -662),
            new CuratedStartPoint("NVG-0342", "house_old_modular_02", 586, 54, -535),
            new CuratedStartPoint("NVG-0343", "house_old_modular_03", 638, 54, -576),
            new CuratedStartPoint("NVG-0344", "house_old_modular_04", 586, 54, -620),
            new CuratedStartPoint("NVG-0345", "house_old_modular_05", 638, 54, -618),
            new CuratedStartPoint("NVG-0346", "house_old_modular_06", 586, 54, -578),
            new CuratedStartPoint("NVG-0347", "house_old_modular_07", 638, 54, -534),
            new CuratedStartPoint("NVG-0348", "house_old_modular_08", 586, 54, -664),
            new CuratedStartPoint("NVG-0349", "house_old_pyramid_01", 983, 61, 575),
            new CuratedStartPoint("NVG-0350", "house_old_pyramid_02", -2154, 75, -8),
            new CuratedStartPoint("NVG-0351", "house_old_pyramid_03", 1140, 54, -400),
            new CuratedStartPoint("NVG-0352", "house_old_pyramid_04", 981, 61, 768),
            new CuratedStartPoint("NVG-0353", "house_old_pyramid_05", -340, 63, -2140),
            new CuratedStartPoint("NVG-0354", "house_old_ranch_02", 291, 61, 1355),
            new CuratedStartPoint("NVG-0355", "house_old_ranch_03", -226, 61, 950),
            new CuratedStartPoint("NVG-0356", "house_old_ranch_05", -299, 61, 874),
            new CuratedStartPoint("NVG-0357", "house_old_ranch_06", -299, 61, 811),
            new CuratedStartPoint("NVG-0358", "house_old_ranch_07", 216, 61, 1355),
            new CuratedStartPoint("NVG-0359", "house_old_ranch_08", 252, 61, 1286),
            new CuratedStartPoint("NVG-0360", "house_old_ranch_09", -226, 61, 847),
            new CuratedStartPoint("NVG-0361", "house_old_ranch_10", -299, 61, 993),
            new CuratedStartPoint("NVG-0362", "house_old_ranch_12", 780, 76, -1019),
            new CuratedStartPoint("NVG-0363", "house_old_ranch_13", -25, 97, -1254),
            new CuratedStartPoint("NVG-0364", "house_old_tudor_01", -2084, 75, -8),
            new CuratedStartPoint("NVG-0365", "house_old_tudor_02", -1524, 81, 1673),
            new CuratedStartPoint("NVG-0366", "house_old_tudor_05", -1745, 81, 1798),
            new CuratedStartPoint("NVG-0367", "house_old_tudor_06", 939, 61, 644),
            new CuratedStartPoint("NVG-0368", "house_old_victorian_01", 919, 67, -1155),
            new CuratedStartPoint("NVG-0369", "house_old_victorian_02", 1083, 61, 699),
            new CuratedStartPoint("NVG-0370", "house_old_victorian_03", -298, 76, 1332),
            new CuratedStartPoint("NVG-0371", "house_old_victorian_04", 1126, 61, 768),
            new CuratedStartPoint("NVG-0372", "house_old_victorian_05", 480, 61, 94),
            new CuratedStartPoint("NVG-0373", "house_old_victorian_06", -2229, 75, -8),
            new CuratedStartPoint("NVG-0374", "house_old_victorian_07", -281, 76, 1392),
            new CuratedStartPoint("NVG-0375", "house_old_victorian_08", -1746, 81, 1855),
            new CuratedStartPoint("NVG-0376", "house_old_victorian_09", 1025, 61, 633),
            new CuratedStartPoint("NVG-0377", "house_old_victorian_10", 2123, 73, 24),
            new CuratedStartPoint("NVG-0378", "house_old_victorian_11", -38, 61, -182),
            new CuratedStartPoint("NVG-0379", "house_old_victorian_12", -1581, 81, 1672),
            new CuratedStartPoint("NVG-0380", "indian_burial_grounds_01", 1450, 86, -1007),
            new CuratedStartPoint("NVG-0381", "industrial_business_08", -227, 76, 1329),
            new CuratedStartPoint("NVG-0382", "installation_red_mesa", -1312, 74, -2206),
            new CuratedStartPoint("NVG-0383", "junkyard_01", 1316, 61, -745),
            new CuratedStartPoint("NVG-0384", "lodge_01", -2108, 219, 2108),
            new CuratedStartPoint("NVG-0385", "lot_country_01", 343, 76, 998),
            new CuratedStartPoint("NVG-0386", "lot_country_02", -190, 63, -2138),
            new CuratedStartPoint("NVG-0387", "lot_downtown_filler_01", 1919, 61, -1946),
            new CuratedStartPoint("NVG-0388", "lot_industrial_01", 1806, 61, -1663),
            new CuratedStartPoint("NVG-0389", "lot_industrial_02", 1872, 61, -1947),
            new CuratedStartPoint("NVG-0390", "lot_industrial_03", -1756, 54, -605),
            new CuratedStartPoint("NVG-0391", "lot_industrial_04", -1756, 54, -664),
            new CuratedStartPoint("NVG-0392", "lot_industrial_05", -1756, 54, -692),
            new CuratedStartPoint("NVG-0393", "lot_industrial_06", -1756, 54, -635),
            new CuratedStartPoint("NVG-0394", "lot_industrial_08", -1697, 54, -814),
            new CuratedStartPoint("NVG-0395", "lot_industrial_09", -1667, 54, -814),
            new CuratedStartPoint("NVG-0396", "lot_industrial_10", -1689, 54, -902),
            new CuratedStartPoint("NVG-0397", "lot_industrial_11", -1702, 54, -675),
            new CuratedStartPoint("NVG-0398", "lot_industrial_14", -1756, 54, -902),
            new CuratedStartPoint("NVG-0399", "lot_vacant_02", 1685, 61, -1611),
            new CuratedStartPoint("NVG-0400", "lot_vacant_04", 1619, 61, -1930),
            new CuratedStartPoint("NVG-0401", "lot_vacant_07", -595, 61, 573),
            new CuratedStartPoint("NVG-0402", "lot_vacant_08", 634, 58, -1052),
            new CuratedStartPoint("NVG-0403", "mine_01", 1371, 63, -477),
            new CuratedStartPoint("NVG-0404", "motel_02", -1736, 90, -2205),
            new CuratedStartPoint("NVG-0405", "motel_02", 1379, 76, 697),
            new CuratedStartPoint("NVG-0406", "motel_05", 892, 61, -1888),
            new CuratedStartPoint("NVG-0407", "nursing_home_01", -2084, 77, -1540),
            new CuratedStartPoint("NVG-0408", "office_02", -534, 76, 1910),
            new CuratedStartPoint("NVG-0409", "office_05", -1961, 87, 1854),
            new CuratedStartPoint("NVG-0410", "oldwest_business_01", 417, 69, -2198),
            new CuratedStartPoint("NVG-0411", "oldwest_business_02", 1768, 61, -444),
            new CuratedStartPoint("NVG-0412", "oldwest_business_03", 285, 76, -2322),
            new CuratedStartPoint("NVG-0413", "oldwest_business_04", 1673, 61, -445),
            new CuratedStartPoint("NVG-0414", "oldwest_business_05", 1765, 61, -415),
            new CuratedStartPoint("NVG-0415", "oldwest_business_06", 1673, 61, -470),
            new CuratedStartPoint("NVG-0417", "oldwest_business_08", 405, 69, -2232),
            new CuratedStartPoint("NVG-0418", "oldwest_business_09", 1681, 61, -420),
            new CuratedStartPoint("NVG-0419", "oldwest_business_10", 323, 71, -2256),
            new CuratedStartPoint("NVG-0420", "oldwest_business_11", 301, 76, -2289),
            new CuratedStartPoint("NVG-0421", "oldwest_business_12", 369, 75, -2265),
            new CuratedStartPoint("NVG-0422", "oldwest_business_13", 417, 69, -2169),
            new CuratedStartPoint("NVG-0423", "oldwest_business_14", 387, 69, -2199),
            new CuratedStartPoint("NVG-0424", "oldwest_church", 1720, 61, -319),
            new CuratedStartPoint("NVG-0425", "oldwest_coal_factory", 423, 69, -2137),
            new CuratedStartPoint("NVG-0426", "oldwest_gallows", 1706, 61, -365),
            new CuratedStartPoint("NVG-0427", "oldwest_jail", 1737, 61, -366),
            new CuratedStartPoint("NVG-0428", "oldwest_stables", 1737, 61, -493),
            new CuratedStartPoint("NVG-0429", "oldwest_strip_01", 1737, 61, -416),
            new CuratedStartPoint("NVG-0430", "oldwest_strip_02", 1706, 61, -470),
            new CuratedStartPoint("NVG-0431", "oldwest_strip_03", 1706, 61, -415),
            new CuratedStartPoint("NVG-0432", "oldwest_strip_04", 1737, 61, -468),
            new CuratedStartPoint("NVG-0433", "oldwest_watertower", 1762, 61, -389),
            new CuratedStartPoint("NVG-0434", "park_01", 983, 61, 636),
            new CuratedStartPoint("NVG-0435", "park_02", -1583, 81, 1729),
            new CuratedStartPoint("NVG-0436", "park_03", -1625, 81, 1729),
            new CuratedStartPoint("NVG-0438", "parking_garage_02", 1733, 61, -1657),
            new CuratedStartPoint("NVG-0439", "parking_garage_03", -384, 61, -564),
            new CuratedStartPoint("NVG-0440", "parking_lot_01", 1681, 61, -1720),
            new CuratedStartPoint("NVG-0441", "parking_lot_02", -547, 61, -417),
            new CuratedStartPoint("NVG-0442", "parking_lot_03", -1757, 54, -566),
            new CuratedStartPoint("NVG-0443", "perishton_bridge", -1405, 81, 1778),
            new CuratedStartPoint("NVG-0446", "perishton_city_blk_02", -1647, 80, 1796),
            new CuratedStartPoint("NVG-0447", "perishton_city_blk_03", -1761, 81, 1659),
            new CuratedStartPoint("NVG-0448", "perishton_city_blk_04", -1526, 81, 1796),
            new CuratedStartPoint("NVG-0449", "perishton_city_blk_05", -1761, 81, 1796),
            new CuratedStartPoint("NVG-0450", "perishton_city_blk_06", -1970, 82, 1789),
            new CuratedStartPoint("NVG-0451", "perishton_city_blk_plaza", -1647, 81, 1659),
            new CuratedStartPoint("NVG-0452", "perishton_fence", -1878, 84, 1689),
            new CuratedStartPoint("NVG-0453", "perishton_median_01", -1750, 81, 1773),
            new CuratedStartPoint("NVG-0454", "perishton_median_03", -1638, 81, 1773),
            new CuratedStartPoint("NVG-0455", "perishton_median_03", -1526, 81, 1773),
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
