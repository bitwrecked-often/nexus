using System;

namespace BitWrecked.HistoricalRandomStart
{
    internal static class CompatibilityGuard
    {
        private static readonly Guid ExpectedAssemblyCSharpMvid =
            new Guid("229796d0-95ca-4662-b426-1a6f1f1596ed");

        internal static bool IsCompatible()
        {
            return typeof(IModApi).Assembly.ManifestModule.ModuleVersionId ==
                ExpectedAssemblyCSharpMvid;
        }
    }
}
