using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

namespace BitWrecked.HistoricalRandomStart
{
    internal static class CompatibilityGuard
    {
        private static readonly Guid ExpectedAssemblyCSharpMvid =
            new Guid("8576eaa1-7f2c-44dc-ba1b-e8b275a8aa62");

        internal static bool IsKnownBuild()
        {
            return typeof(IModApi).Assembly.ManifestModule.ModuleVersionId ==
                ExpectedAssemblyCSharpMvid;
        }

        internal static bool IsCompatible()
        {
            if (IsKnownBuild()) return true;

            // An unverified build may still expose the intro hook we need.
            // The actual spawn and placement callbacks remain live test gates.
            try
            {
                return typeof(Quest).GetMethod("SetupPosition",
                    BindingFlags.Instance | BindingFlags.Public |
                        BindingFlags.NonPublic,
                    null,
                    new Type[] { typeof(EntityNPC), typeof(EntityPlayer),
                        typeof(List<Vector2>), typeof(int) }, null) != null;
            }
            catch
            {
                return false;
            }
        }
    }
}
