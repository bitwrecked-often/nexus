using System;
using System.Collections.Generic;
using UnityEngine;

namespace BitWrecked.HistoricalRandomStart
{
    internal enum TraderIndexStatus
    {
        Unavailable,
        Empty,
        Ready
    }

    internal sealed class PlacedTrader
    {
        internal readonly int InstanceId;
        internal readonly int BiomeId;
        internal readonly Vector3 Location;
        internal readonly Vector3 Size;

        internal PlacedTrader(PrefabInstance instance, int biomeId)
        {
            InstanceId = instance.id;
            BiomeId = biomeId;
            Vector3i origin = instance.boundingBoxPosition;
            Vector3i bounds = instance.boundingBoxSize;
            Location = new Vector3(origin.x, origin.y, origin.z);
            Size = new Vector3(bounds.x, bounds.y, bounds.z);
        }

        internal double DistanceSquared(Vector3 position)
        {
            double dx = Location.x + Size.x * 0.5 - position.x;
            double dz = Location.z + Size.z * 0.5 - position.z;
            return dx * dx + dz * dz;
        }
    }

    internal static class PlacedTraderResolver
    {
        private static World cachedWorld;
        private static string cachedWorldGuid;
        private static List<PlacedTrader> cachedTraders;
        private static TraderIndexStatus cachedStatus;

        internal static TraderIndexStatus GetStatus(World world)
        {
            if (world == null || string.IsNullOrEmpty(world.Guid) ||
                GameManager.Instance == null ||
                !object.ReferenceEquals(GameManager.Instance.World, world))
                return TraderIndexStatus.Unavailable;
            if (object.ReferenceEquals(cachedWorld, world) &&
                string.Equals(cachedWorldGuid, world.Guid,
                    StringComparison.Ordinal) && cachedTraders != null)
                return cachedStatus;

            DynamicPrefabDecorator decorator =
                GameManager.Instance.GetDynamicPrefabDecorator();
            if (decorator == null) return TraderIndexStatus.Unavailable;
            var placed = new List<PrefabInstance>();
            try { decorator.GetWorldPrefabs(placed); }
            catch { return TraderIndexStatus.Unavailable; }
            if (placed.Count == 0) return TraderIndexStatus.Unavailable;

            var traders = new List<PlacedTrader>();
            int tagged = 0;
            var seen = new HashSet<string>(StringComparer.Ordinal);
            foreach (PrefabInstance instance in placed)
            {
                if (instance == null || instance.prefab == null ||
                    !instance.prefab.bTraderArea) continue;
                tagged++;
                Vector3i origin = instance.boundingBoxPosition;
                Vector3i size = instance.boundingBoxSize;
                if (instance.rotation > 3 || size.x <= 0 || size.y <= 0 ||
                    size.z <= 0) continue;
                string key = instance.id + ":" + origin + ":" +
                    instance.rotation;
                if (!seen.Add(key)) continue;
                Vector3 center = new Vector3(origin.x + size.x * 0.5f,
                    origin.y + 1f, origin.z + size.z * 0.5f);
                if (!world.IsPositionInBounds(center)) continue;
                int biomeId;
                int family;
                if (!PlacedPoiResolver.TryResolveBiome(world, center,
                    out biomeId, out family)) continue;
                traders.Add(new PlacedTrader(instance, biomeId));
            }

            cachedWorld = world;
            cachedWorldGuid = world.Guid;
            cachedTraders = traders;
            cachedStatus = traders.Count > 0 ? TraderIndexStatus.Ready :
                tagged == 0 ? TraderIndexStatus.Empty :
                    TraderIndexStatus.Unavailable;
            // Incomplete metadata may become usable later; do not freeze it.
            if (cachedStatus == TraderIndexStatus.Unavailable)
                cachedTraders = null;
            return cachedStatus;
        }

        internal static bool TrySelect(World world, Vector3 position,
            int startingBiome, out PlacedTrader selected,
            out bool crossedBiome)
        {
            selected = null;
            crossedBiome = false;
            if (startingBiome <= 0 || GetStatus(world) != TraderIndexStatus.Ready)
                return false;
            double best = double.MaxValue;
            bool sameFound = false;
            foreach (PlacedTrader candidate in cachedTraders)
            {
                bool same = candidate.BiomeId == startingBiome;
                if (sameFound && !same) continue;
                double distance = candidate.DistanceSquared(position);
                if (selected == null || (same && !sameFound) ||
                    (same == sameFound && distance < best))
                {
                    selected = candidate;
                    best = distance;
                    sameFound = same;
                }
            }
            crossedBiome = selected != null && !sameFound;
            return selected != null;
        }
    }
}
