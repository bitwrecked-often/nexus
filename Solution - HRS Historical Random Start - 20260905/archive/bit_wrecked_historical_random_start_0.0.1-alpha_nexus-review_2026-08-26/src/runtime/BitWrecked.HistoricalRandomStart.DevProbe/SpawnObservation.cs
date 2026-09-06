namespace BitWrecked.HistoricalRandomStart.DevProbe
{
    internal sealed class ObservationResult
    {
        internal ObservationResult(string reasonCode, string lifecycle)
        {
            ReasonCode = reasonCode;
            Lifecycle = lifecycle;
        }

        internal string ReasonCode { get; private set; }
        internal string Lifecycle { get; private set; }
    }

    internal static class SpawnObservation
    {
        internal static ObservationResult Classify(RespawnType respawnType)
        {
            string lifecycle = respawnType.ToString();
            if (respawnType == RespawnType.NewGame || respawnType == RespawnType.EnterMultiplayer)
            {
                return new ObservationResult("OBS_ELIGIBLE_NEW_CHARACTER", lifecycle);
            }

            return new ObservationResult("OBS_LIFECYCLE_REJECTED", lifecycle);
        }
    }
}
