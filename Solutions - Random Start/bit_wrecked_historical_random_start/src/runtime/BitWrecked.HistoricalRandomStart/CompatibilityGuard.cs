using System;

namespace BitWrecked.HistoricalRandomStart
{
    internal static class CompatibilityGuard
    {
        private static readonly Guid ExpectedAssemblyCSharpMvid =
            new Guid("acb580d9-e1ab-497d-a8dc-47e47c1fc300");

        internal static bool IsCompatible()
        {
            return typeof(IModApi).Assembly.ManifestModule.ModuleVersionId ==
                ExpectedAssemblyCSharpMvid;
        }
    }
}
