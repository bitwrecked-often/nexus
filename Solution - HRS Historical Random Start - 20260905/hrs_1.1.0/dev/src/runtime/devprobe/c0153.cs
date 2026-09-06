using System;
using System.Collections.Generic;

namespace BitWrecked.HistoricalRandomStart.DevProbe
{
    internal enum DuplicateDecision
    {
        Accepted,
        Duplicate,
        Capacity
    }

    internal sealed class DuplicateObservationGate
    {
        private const int Capacity = 128;
        private readonly HashSet<string> keys = new HashSet<string>(StringComparer.Ordinal);

        internal DuplicateDecision TryAccept(string worldKey, int entityId, RespawnType respawnType)
        {
            string key = worldKey + "|" + entityId.ToString() + "|" + ((int)respawnType).ToString();
            if (keys.Contains(key))
            {
                return DuplicateDecision.Duplicate;
            }

            if (keys.Count >= Capacity)
            {
                return DuplicateDecision.Capacity;
            }

            keys.Add(key);
            return DuplicateDecision.Accepted;
        }

        internal int Count { get { return keys.Count; } }
    }
}
