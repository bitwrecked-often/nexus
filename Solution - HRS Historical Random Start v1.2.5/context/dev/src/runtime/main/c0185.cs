using UnityEngine;

namespace BitWrecked.HistoricalRandomStart
{
    internal sealed class PendingPlacement
    {
        private const int MaximumPoiAttempts = 5;
        internal PendingPlacement(string worldGuid, int entityId, Vector3 candidate,
            Vector3 originalPosition, PoiSelection selection, ResolvedPoi poi)
        {
            WorldGuid = worldGuid;
            EntityId = entityId;
            Candidate = candidate;
            ResolvedGroundY = candidate.y - 1f;
            OriginalPosition = originalPosition;
            Selection = selection;
            Poi = poi;
            PoiAttempts = 1;
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
            ResolvedGroundY = candidate.y - 1f;
            LandingResolved = true;
            Ticks = 0;
        }

        internal void AdoptSettledPosition(Vector3 position)
        {
            Candidate = position;
        }

        internal bool TryNextPoi(out ResolvedPoi next)
        {
            next = null;
            if (PoiAttempts >= MaximumPoiAttempts || Selection == null)
                return false;
            return Selection.TryNext(out next);
        }

        internal void AdoptNextPoi(ResolvedPoi next, float nextPlacementNotBefore)
        {
            Poi = next;
            PoiAttempts++;
            NextPlacementNotBefore = nextPlacementNotBefore;
            Candidate = next.Approach;
            ResolvedGroundY = Candidate.y - 1f;
            PlacementCalled = false;
            PrimeDelayStarted = false;
            LandingResolved = false;
            StableVerificationSamples = 0;
            Ticks = 0;
        }

        internal string WorldGuid { get; private set; }
        internal int EntityId { get; private set; }
        internal Vector3 Candidate { get; private set; }
        internal float ResolvedGroundY { get; private set; }
        internal Vector3 OriginalPosition { get; private set; }
        internal ResolvedPoi Poi { get; private set; }
        internal PoiSelection Selection { get; private set; }
        internal int PoiAttempts { get; private set; }
        internal float NextPlacementNotBefore { get; private set; }
        internal bool CanStartPlacement(float now)
        {
            return now >= NextPlacementNotBefore;
        }
        internal float VerificationDeadline { get; private set; }
        internal bool PlacementCalled { get; private set; }
        internal bool PrimeDelayStarted { get; private set; }
        internal float PrimeDeadline { get; private set; }
        internal bool LandingResolved { get; private set; }
        internal int StableVerificationSamples { get; private set; }
        internal int Ticks { get; set; }
    }
}
