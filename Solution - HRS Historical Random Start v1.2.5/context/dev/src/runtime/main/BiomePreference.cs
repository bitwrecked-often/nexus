using System;
using System.Collections.Generic;
using System.Globalization;

namespace BitWrecked.HistoricalRandomStart
{
    internal sealed class BiomePreference
    {
        // Stable policy order; these are application IDs, not game enum ordinals.
        internal static readonly int[] Ids = { 3, 9, 5, 1, 8 };
        internal readonly string Kind;
        internal readonly int Chosen;
        private readonly int[] weights;
        internal static BiomePreference Any { get { return new BiomePreference("Any", 0, new int[5]); } }

        internal BiomePreference(string kind, int chosen, int[] values)
        { Kind = kind; Chosen = chosen; weights = (int[])values.Clone(); }

        internal int Weight(int index) { return weights[index]; }
        internal bool IsValid(bool standard)
        {
            if (weights.Length != 5 || (Kind != "Any" && Kind != "Chosen" && Kind != "Weighted")) return false;
            if (standard && Kind != "Any") return false;
            if (Kind == "Chosen" ? Array.IndexOf(Ids, Chosen) < 0 : Chosen != 0) return false;
            int sum = 0;
            foreach (int w in weights) { if (w < 0 || w > 100) return false; sum += w; }
            return Kind == "Weighted" ? sum > 0 : sum == 0;
        }

        internal string DigestFields()
        {
            string result = Kind + "\n" + Chosen.ToString(CultureInfo.InvariantCulture);
            foreach (int w in weights) result += "\n" + w.ToString(CultureInfo.InvariantCulture);
            return result;
        }

        internal string JsonFields()
        {
            string[] names = { "forest", "burntForest", "desert", "snow", "wasteland" };
            string result = ",\"selection\":\"" + Kind + "\",\"chosenBiome\":" + Chosen.ToString(CultureInfo.InvariantCulture);
            for (int i = 0; i < 5; i++) result += ",\"" + names[i] + "\":" + weights[i].ToString(CultureInfo.InvariantCulture);
            return result;
        }

        internal string Diagnostic()
        { return DigestFields().Replace("\n", ":"); }

        internal bool TryDraw(ICollection<int> eligible, Func<int, int> draw,
            out int selected, out string reason)
        {
            selected = 0;
            reason = "POLICY_REJECTED";
            if (!IsValid(false)) return false;
            reason = "POI_POOL_EMPTY";
            if (eligible == null || eligible.Count == 0) return false;
            if (Kind == "Chosen")
            {
                reason = "REQUESTED_BIOME_ABSENT";
                if (!eligible.Contains(Chosen)) return false;
                selected = Chosen;
                reason = "BIOME_SELECTED";
                return true;
            }
            int total = 0;
            for (int i = 0; i < Ids.Length; i++)
                if (eligible.Contains(Ids[i])) total += Kind == "Any" ? 1 : weights[i];
            reason = "WEIGHTED_POOL_EMPTY";
            if (total == 0) return false;
            int ticket = draw(total);
            if (ticket < 0 || ticket >= total) throw new ArgumentOutOfRangeException("draw");
            for (int i = 0; i < Ids.Length; i++)
            {
                if (!eligible.Contains(Ids[i])) continue;
                ticket -= Kind == "Any" ? 1 : weights[i];
                if (ticket < 0) { selected = Ids[i]; reason = "BIOME_SELECTED"; return true; }
            }
            throw new InvalidOperationException("BIOME_DRAW_FAILED");
        }
    }
}
