using UnityEngine;

namespace BitWrecked.HistoricalRandomStart
{
    internal sealed class PendingPlacement
    {
        internal PendingPlacement(string worldGuid, int entityId, Vector3 candidate,
            Vector3 originalPosition, string pointId)
        {
            WorldGuid = worldGuid;
            EntityId = entityId;
            Candidate = candidate;
            CatalogGroundY = candidate.y - 1f;
            OriginalPosition = originalPosition;
            PointId = pointId;
        }

        internal void BeginPlacement(float verificationDeadline)
        {
            VerificationDeadline = verificationDeadline;
            PlacementCalled = true;
        }

        internal bool ObserveVerificationSample(bool isStable, int requiredStableSamples)
        {
            if (!isStable)
            {
                StableVerificationSamples = 0;
                return false;
            }
            StableVerificationSamples++;
            return StableVerificationSamples >= requiredStableSamples;
        }

        internal void BeginPrimeDelay(float primeDeadline)
        {
            PrimeDeadline = primeDeadline;
            PrimeDelayStarted = true;
        }

        internal void AdoptSafeCandidate(Vector3 candidate)
        {
            Candidate = candidate;
            LandingResolved = true;
            Ticks = 0;
        }

        internal void AdoptSettledPosition(Vector3 position)
        {
            Candidate = position;
        }

        internal string WorldGuid { get; private set; }
        internal int EntityId { get; private set; }
        internal Vector3 Candidate { get; private set; }
        internal float CatalogGroundY { get; private set; }
        internal Vector3 OriginalPosition { get; private set; }
        internal string PointId { get; private set; }
        internal float VerificationDeadline { get; private set; }
        internal bool PlacementCalled { get; private set; }
        internal bool PrimeDelayStarted { get; private set; }
        internal float PrimeDeadline { get; private set; }
        internal bool LandingResolved { get; private set; }
        internal int StableVerificationSamples { get; private set; }
        internal int Ticks { get; set; }
    }
}
