using System;

namespace BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe
{
    internal static class CompatibilityGuard
    {
        private static readonly Guid ExpectedMvid =
            new Guid("326ffd03-1d6d-4efb-a7dc-79201537b1c3");

        internal static bool IsCompatible()
        {
            return typeof(IModApi).Assembly.ManifestModule.ModuleVersionId == ExpectedMvid;
        }
    }
}
