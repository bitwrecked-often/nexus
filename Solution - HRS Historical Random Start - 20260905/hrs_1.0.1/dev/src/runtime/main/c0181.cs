namespace BitWrecked.HistoricalRandomStart
{
    internal enum MarkerState
    {
        Absent = 0,
        Reserved = 1,
        Completed = 2,
        Invalid = 3
    }

    internal enum TraderRouteState
    {
        Absent = 0,
        Pending = 1,
        Reserved = 2,
        Completed = 3,
        Invalid = 4
    }

    internal static class MarkerStore
    {
        internal const string Name = "bitwrecked_hrs_state_v1";
        internal const string BiomeName = "bitwrecked_hrs_biome_v1";
        internal const string TraderRouteName =
            "bitwrecked_hrs_starter_trader_route_v1";

        internal static bool IsAvailable(EntityPlayer player)
        {
            return player != null && player.Buffs != null;
        }

        internal static MarkerState Read(EntityPlayer player)
        {
            if (!IsAvailable(player)) return MarkerState.Invalid;
            if (!player.Buffs.HasCustomVar(Name)) return MarkerState.Absent;

            float value = player.Buffs.GetCustomVar(Name);
            if (value == 1f) return MarkerState.Reserved;
            if (value == 2f) return MarkerState.Completed;
            return MarkerState.Invalid;
        }

        internal static bool TryReserve(EntityPlayer player)
        {
            if (Read(player) != MarkerState.Absent) return false;
            player.Buffs.AddCustomVar(Name, 1f);
            return Read(player) == MarkerState.Reserved;
        }

        internal static bool TryComplete(EntityPlayer player)
        {
            if (Read(player) != MarkerState.Reserved) return false;
            player.Buffs.AddCustomVar(Name, 2f);
            return Read(player) == MarkerState.Completed;
        }

        internal static bool TryEnableSnowProtection(EntityPlayer player)
        {
            if (Read(player) != MarkerState.Completed) return false;
            player.Buffs.AddCustomVar(BiomeName, 8f);
            return ReadSnowProtection(player);
        }

        internal static bool ReadSnowProtection(EntityPlayer player)
        {
            return IsAvailable(player) && Read(player) == MarkerState.Completed &&
                player.Buffs.HasCustomVar(BiomeName) &&
                player.Buffs.GetCustomVar(BiomeName) == 8f;
        }

        internal static TraderRouteState ReadTraderRoute(EntityPlayer player)
        {
            if (!IsAvailable(player)) return TraderRouteState.Invalid;
            if (!player.Buffs.HasCustomVar(TraderRouteName))
                return TraderRouteState.Absent;
            float value = player.Buffs.GetCustomVar(TraderRouteName);
            if (value == 1f) return TraderRouteState.Pending;
            if (value == 2f) return TraderRouteState.Reserved;
            if (value == 3f) return TraderRouteState.Completed;
            return TraderRouteState.Invalid;
        }

        internal static bool TryBeginTraderRoute(EntityPlayer player)
        {
            if (Read(player) != MarkerState.Completed ||
                ReadTraderRoute(player) != TraderRouteState.Absent) return false;
            player.Buffs.AddCustomVar(TraderRouteName, 1f);
            return ReadTraderRoute(player) == TraderRouteState.Pending;
        }

        internal static bool TryReserveTraderRoute(EntityPlayer player)
        {
            if (Read(player) != MarkerState.Completed ||
                ReadTraderRoute(player) != TraderRouteState.Pending) return false;
            player.Buffs.AddCustomVar(TraderRouteName, 2f);
            return ReadTraderRoute(player) == TraderRouteState.Reserved;
        }

        internal static bool TryCompleteTraderRoute(EntityPlayer player)
        {
            if (Read(player) != MarkerState.Completed ||
                ReadTraderRoute(player) != TraderRouteState.Reserved) return false;
            player.Buffs.AddCustomVar(TraderRouteName, 3f);
            return ReadTraderRoute(player) == TraderRouteState.Completed;
        }
    }
}
