using UnityEngine;

namespace BitWrecked.HistoricalRandomStart
{
    internal sealed class PendingPlacement
    {
        internal PendingPlacement(string worldGuid, int entityId, Vector3 candidate)
        {
            WorldGuid = worldGuid;
            EntityId = entityId;
            Candidate = candidate;
        }

        internal void BeginPlacement(float verificationDeadline)
        {
            VerificationDeadline = verificationDeadline;
            PlacementCalled = true;
        }

        internal string WorldGuid { get; private set; }
        internal int EntityId { get; private set; }
        internal Vector3 Candidate { get; private set; }
        internal float VerificationDeadline { get; private set; }
        internal bool PlacementCalled { get; private set; }
        internal int Ticks { get; set; }
    }
}
