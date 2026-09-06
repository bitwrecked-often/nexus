namespace reloc
{
    internal enum MarkerState { Absent = 0, Reserved = 1, Completed = 2, Invalid = 3 }

    internal static class MarkerStore
    {
        internal const string Name = "bitwrecked_hrs_state_v1";

        internal static MarkerState Read(EntityPlayer player)
        {
            if (player == null || player.Buffs == null || !player.Buffs.HasCustomVar(Name))
                return MarkerState.Absent;
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
    }
}
