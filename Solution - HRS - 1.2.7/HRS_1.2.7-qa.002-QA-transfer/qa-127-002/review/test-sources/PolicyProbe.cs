using System;
using BitWrecked.HistoricalRandomStart;

public static class PolicyProbe
{
    public static string ReadV2(string path)
    {
        PolicyV2 p; string reason;
        return PolicyV2Codec.TryRead(path, out p, out reason) ? PolicyV2Codec.Serialize(p) : reason;
    }
    public static bool AcceptsV1(string path)
    { PolicyV1 p; string reason; return PolicyV1Codec.TryRead(path, out p, out reason); }
    public static int Draw(string kind, int chosen, int[] weights, int[] eligible, int ticket)
    {
        var p = new BiomePreference(kind, chosen, weights);
        int selected; string reason;
        if (!p.TryDraw(eligible, n => { if (ticket >= n) throw new Exception("BOUND"); return ticket; }, out selected, out reason))
            throw new Exception(reason);
        return selected;
    }
}
