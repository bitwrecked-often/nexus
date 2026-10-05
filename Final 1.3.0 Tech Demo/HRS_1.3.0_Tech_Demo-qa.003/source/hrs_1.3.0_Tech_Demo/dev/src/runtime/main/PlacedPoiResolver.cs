using System;
using System.Collections.Generic;
using UnityEngine;

namespace BitWrecked.HistoricalRandomStart
{
    // An eligible placed instance in the active world; historical Navezgane
    // coordinates are reference data and are never used for relocation.
    internal sealed class ResolvedPoi
    {
        internal readonly World WorldRef;
        internal readonly string WorldGuid;
        internal readonly int InstanceId;
        internal readonly string PrefabName;
        internal readonly Vector3i Origin;
        internal readonly Vector3i Size;
        internal readonly byte Rotation;
        internal readonly Bounds Bounds;
        internal readonly Vector3 Approach;
        internal readonly int BiomeId;

        internal ResolvedPoi(World world, PrefabInstance instance,
            Vector3 approach, int biomeId)
        {
            WorldRef = world;
            WorldGuid = world.Guid;
            InstanceId = instance.id;
            PrefabName = instance.prefab.PrefabName;
            Origin = instance.boundingBoxPosition;
            Size = instance.boundingBoxSize;
            Rotation = instance.rotation;
            Bounds = instance.GetAABB();
            Approach = approach;
            BiomeId = biomeId;
        }
    }

    internal sealed class PoiSelection
    {
        private readonly World world;
        private readonly Dictionary<string, List<ResolvedPoi>> remaining;
        internal readonly int TargetBiomeId;

        internal PoiSelection(World world,
            int targetBiomeId, Dictionary<string, List<ResolvedPoi>> index)
        {
            this.world = world;
            TargetBiomeId = targetBiomeId;
            remaining = new Dictionary<string, List<ResolvedPoi>>(
                StringComparer.Ordinal);
            foreach (KeyValuePair<string, List<ResolvedPoi>> group in index)
                remaining.Add(group.Key, new List<ResolvedPoi>(group.Value));
        }

        internal bool TryNext(out ResolvedPoi selected)
        {
            selected = null;
            if (GameManager.Instance == null ||
                !object.ReferenceEquals(GameManager.Instance.World, world))
                return false;
            while (remaining.Count > 0)
            {
                var names = new List<string>(remaining.Keys);
                string name = names[world.GetGameRandom().RandomRange(names.Count)];
                List<ResolvedPoi> instances = remaining[name];
                int slot = world.GetGameRandom().RandomRange(instances.Count);
                selected = instances[slot];
                instances.RemoveAt(slot);
                if (instances.Count == 0) remaining.Remove(name);
                return true;
            }
            return false;
        }
    }

    internal static class PlacedPoiResolver
    {
        private const int EdgeClearance = 6;
        private const int SearchRadius = 32;
        private const int SearchStep = 4;
        private const int MaximumTerrainDelta = 24;
        // The original 80 selected historical entries contain 79 distinct
        // prefab names: motel_02 occurs twice. Select by type, then by placed
        // instance, so that duplicate historical entry does not add weight.
        private static readonly HashSet<string> Names =
            new HashSet<string>(StringComparer.Ordinal)
            {
                "hospital_01", "hotel_01", "hotel_02", "hotel_04",
                "hotel_ostrich", "house_burnt_01", "house_burnt_05",
                "house_burnt_06", "house_construction_01",
                "house_construction_03", "house_country_01",
                "house_modern_02", "house_modern_05", "house_modern_12",
                "house_modern_17", "house_modern_26", "house_modern_31",
                "house_old_bungalow_02", "house_old_bungalow_03",
                "house_old_bungalow_12", "house_old_cottage_01",
                "house_old_gambrel_03", "house_old_mansard_02",
                "house_old_mansard_03", "house_old_mansard_04",
                "house_old_mansard_06", "house_old_mansard_07",
                "house_old_modular_03", "house_old_pyramid_03",
                "house_old_pyramid_04", "house_old_ranch_02",
                "house_old_ranch_03", "house_old_tudor_01",
                "house_old_tudor_02", "house_old_victorian_01",
                "house_old_victorian_03", "house_old_victorian_04",
                "house_old_victorian_05", "house_old_victorian_09",
                "house_old_victorian_12", "indian_burial_grounds_01",
                "industrial_business_08", "installation_red_mesa",
                "junkyard_01", "lodge_01", "lot_country_01",
                "lot_country_02", "lot_downtown_filler_01",
                "lot_industrial_01", "lot_industrial_03",
                "lot_industrial_04", "lot_industrial_05",
                "lot_industrial_06", "lot_industrial_08",
                "lot_industrial_09", "lot_industrial_10",
                "lot_industrial_11", "lot_industrial_14",
                "lot_vacant_02", "lot_vacant_07", "lot_vacant_08",
                "mine_01", "motel_02", "motel_05", "nursing_home_01",
                "office_02", "office_05", "oldwest_business_01",
                "oldwest_business_02", "oldwest_church",
                "oldwest_coal_factory", "oldwest_stables",
                "oldwest_strip_01", "park_01", "park_02", "park_03",
                "parking_garage_03", "parking_lot_02", "parking_lot_03"
            };
        private static World cachedWorld;
        private static string cachedWorldGuid;
        private static Dictionary<string, List<PrefabInstance>> cached;

        internal static bool IsAllowedName(string name)
        {
            return name != null && Names.Contains(name);
        }

        internal static bool TrySelect(World world, out PoiSelection selection,
            out ResolvedPoi selected)
        {
            string reason, eligible;
            return TrySelect(world, BiomePreference.Any, out selection, out selected, out reason, out eligible);
        }

        internal static bool TrySelect(World world, BiomePreference preference,
            out PoiSelection selection, out ResolvedPoi selected, out string reason,
            out string eligible)
        {
            selection = null;
            selected = null;
            reason = "POI_POOL_EMPTY";
            eligible = "none";
            if (world == null || string.IsNullOrEmpty(world.Guid) ||
                GameManager.Instance == null) return false;
            if (!object.ReferenceEquals(cachedWorld, world) ||
                !string.Equals(cachedWorldGuid, world.Guid,
                StringComparison.Ordinal) || cached == null)
            {
                cached = BuildIndex(GameManager.Instance.GetDynamicPrefabDecorator());
                cachedWorld = world;
                cachedWorldGuid = world.Guid;
            }
            // Choose one eligible biome before any placed instance. Every
            // later draw stays in that biome, without repeating an instance.
            var byBiome = new Dictionary<int,
                Dictionary<string, List<ResolvedPoi>>>();
            foreach (KeyValuePair<string, List<PrefabInstance>> group in cached)
            {
                foreach (PrefabInstance instance in group.Value)
                {
                    ResolvedPoi poi;
                    if (!TryResolve(world, instance, out poi)) continue;
                    Dictionary<string, List<ResolvedPoi>> biomeGroup;
                    if (!byBiome.TryGetValue(poi.BiomeId, out biomeGroup))
                    {
                        biomeGroup = new Dictionary<string, List<ResolvedPoi>>(
                            StringComparer.Ordinal);
                        byBiome.Add(poi.BiomeId, biomeGroup);
                    }
                    List<ResolvedPoi> instances;
                    if (!biomeGroup.TryGetValue(group.Key, out instances))
                    {
                        instances = new List<ResolvedPoi>();
                        biomeGroup.Add(group.Key, instances);
                    }
                    instances.Add(poi);
                }
            }
            var biomeIds = new List<int>(byBiome.Keys);
            biomeIds.Sort();
            if (biomeIds.Count > 0) eligible = string.Join(",", biomeIds.ConvertAll(id => id.ToString(System.Globalization.CultureInfo.InvariantCulture)).ToArray());
            int targetBiomeId;
            if (!preference.TryDraw(biomeIds, n => world.GetGameRandom().RandomRange(n),
                out targetBiomeId, out reason)) return false;
            selection = new PoiSelection(world, targetBiomeId,
                byBiome[targetBiomeId]);
            return selection.TryNext(out selected);
        }

        private static Dictionary<string, List<PrefabInstance>> BuildIndex(
            DynamicPrefabDecorator decorator)
        {
            var index = new Dictionary<string, List<PrefabInstance>>(
                StringComparer.Ordinal);
            if (decorator == null) return index;
            var placed = new List<PrefabInstance>();
            decorator.GetWorldPrefabs(placed);
            var seen = new HashSet<string>(StringComparer.Ordinal);
            foreach (PrefabInstance instance in placed)
            {
                if (instance == null || instance.prefab == null ||
                    instance.boundingBoxSize.x <= 0 ||
                    instance.boundingBoxSize.y <= 0 ||
                    instance.boundingBoxSize.z <= 0) continue;
                string name = instance.prefab.PrefabName;
                if (!IsAllowedName(name)) continue;
                string key = instance.id + ":" + name + ":" +
                    instance.boundingBoxPosition + ":" + instance.rotation;
                if (!seen.Add(key)) continue;
                List<PrefabInstance> group;
                if (!index.TryGetValue(name, out group))
                {
                    group = new List<PrefabInstance>();
                    index.Add(name, group);
                }
                group.Add(instance);
            }
            return index;
        }

        internal static bool TryResolve(World world, PrefabInstance instance,
            out ResolvedPoi resolved)
        {
            resolved = null;
            Vector3i origin = instance.boundingBoxPosition;
            Vector3i size = instance.boundingBoxSize;
            if (instance.rotation > 3) return false;
            // The engine already rotates the instance's AABB. Choose the
            // outward face for this rotation, then round-trip the world point
            // through the engine's inverse/forward POI transform.
            int x = origin.x + size.x / 2;
            int z = origin.z + size.z / 2;
            if (instance.rotation == 0) z = origin.z - EdgeClearance;
            else if (instance.rotation == 1) x = origin.x + size.x + EdgeClearance;
            else if (instance.rotation == 2) z = origin.z + size.z + EdgeClearance;
            else x = origin.x - EdgeClearance;
            Vector3i worldPoint = new Vector3i(x, origin.y, z);
            Vector3i local = instance.GetPositionRelativeToPoi(worldPoint);
            Vector3i checkedPoint = instance.GetWorldPositionOfPoiOffset(local);
            if (checkedPoint.x != x || checkedPoint.z != z) return false;
            Vector3 approach = new Vector3(x, origin.y + 1f, z);
            if (!world.IsPositionInBounds(approach) ||
                InsideFootprint(instance.GetAABB(), approach.x, approach.z, 2f))
                return false;
            int biomeId;
            int protectionFamily;
            if (!TryResolveBiome(world, approach, out biomeId,
                out protectionFamily)) return false;
            resolved = new ResolvedPoi(world, instance, approach, biomeId);
            return true;
        }

        internal static bool TryResolveBiome(World world, Vector3 position,
            out int biomeId, out int protectionFamily)
        {
            biomeId = 0;
            protectionFamily = 0;
            if (world == null) return false;
            int x = (int)Math.Floor(position.x);
            int z = (int)Math.Floor(position.z);
            // GetBiome only sees loaded chunks. The world's biome provider
            // can classify distant placed instances before chunk travel.
            BiomeDefinition biome = world.GetBiome(x, z) ??
                world.GetBiomeInWorld(x, z);
            if (biome == null || string.IsNullOrEmpty(biome.m_sBiomeName))
                return false;
            string name = biome.m_sBiomeName;
            if (string.Equals(name, "pine_forest", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(name, "forest", StringComparison.OrdinalIgnoreCase))
                biomeId = 3;
            else if (string.Equals(name, "snow", StringComparison.OrdinalIgnoreCase))
            { biomeId = 1; protectionFamily = 8; }
            else if (string.Equals(name, "desert", StringComparison.OrdinalIgnoreCase))
            { biomeId = 5; protectionFamily = 2; }
            else if (string.Equals(name, "burnt_forest", StringComparison.OrdinalIgnoreCase))
            { biomeId = 9; protectionFamily = 1; }
            else if (string.Equals(name, "wasteland", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(name, "city_wasteland", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(name, "wasteland_hub", StringComparison.OrdinalIgnoreCase))
            { biomeId = 8; protectionFamily = 4; }
            return biomeId != 0;
        }

        internal static bool TryFindSafeLanding(World world, ResolvedPoi poi,
            out Vector3 landing)
        {
            landing = Vector3.zero;
            if (world == null || poi == null ||
                !object.ReferenceEquals(world, poi.WorldRef) ||
                !string.Equals(world.Guid, poi.WorldGuid,
                    StringComparison.Ordinal)) return false;
            for (int radius = 0; radius <= SearchRadius; radius += SearchStep)
            {
                if (radius == 0)
                {
                    if (TrySafeOffset(world, poi, 0, 0, out landing)) return true;
                    continue;
                }
                for (int delta = -radius; delta <= radius; delta += SearchStep)
                {
                    if (TrySafeOffset(world, poi, delta, -radius, out landing) ||
                        TrySafeOffset(world, poi, delta, radius, out landing)) return true;
                }
                for (int delta = -radius + SearchStep;
                    delta <= radius - SearchStep; delta += SearchStep)
                {
                    if (TrySafeOffset(world, poi, -radius, delta, out landing) ||
                        TrySafeOffset(world, poi, radius, delta, out landing)) return true;
                }
            }
            return false;
        }

        private static bool TrySafeOffset(World world, ResolvedPoi poi,
            int dx, int dz, out Vector3 landing)
        {
            int x = (int)poi.Approach.x + dx;
            int z = (int)poi.Approach.z + dz;
            landing = Vector3.zero;
            if (InsideFootprint(poi.Bounds, x, z, 2f) ||
                !world.IsPositionInBounds(new Vector3(x, poi.Origin.y + 1f, z)))
                return false;
            float terrainY = world.GetTerrainHeight(x, z);
            landing = new Vector3(x, terrainY + 1f, z);
            if (Math.Abs(terrainY - poi.Origin.y) > MaximumTerrainDelta ||
                !world.IsPositionInBounds(landing) ||
                world.GetChunkFromWorldPos(World.worldToBlockPos(landing)) == null)
                return false;
            int landingBiome;
            int family;
            if (!TryResolveBiome(world, landing, out landingBiome, out family) ||
                landingBiome != poi.BiomeId) return false;
            return world.CanPlayersSpawnAtPos(landing, false);
        }

        private static bool InsideFootprint(Bounds bounds, float x, float z,
            float margin)
        {
            return x >= bounds.min.x - margin && x <= bounds.max.x + margin &&
                z >= bounds.min.z - margin && z <= bounds.max.z + margin;
        }
    }
}
