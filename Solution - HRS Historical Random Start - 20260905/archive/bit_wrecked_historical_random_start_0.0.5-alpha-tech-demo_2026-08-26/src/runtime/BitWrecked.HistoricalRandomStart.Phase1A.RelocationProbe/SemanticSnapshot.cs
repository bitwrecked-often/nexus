using System;
using System.Collections.Generic;

namespace BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe
{
    internal struct SemanticSnapshot
    {
        private const ulong Offset = 14695981039346656037UL;
        private const ulong Prime = 1099511628211UL;

        internal SemanticSnapshot(ulong digest) { Digest = digest; }
        internal ulong Digest { get; private set; }

        internal static SemanticSnapshot Capture(EntityPlayer player)
        {
            ulong hash = Offset;
            Add(ref hash, player.Health);
            Add(ref hash, player.gameStage);

            EntityStats stats = player.Stats;
            Add(ref hash, stats == null ? 0f : stats.Health.Value);
            Add(ref hash, stats == null ? 0f : stats.Stamina.Value);
            Add(ref hash, stats == null ? 0f : stats.Food.Value);
            Add(ref hash, stats == null ? 0f : stats.Water.Value);

            Progression progression = player.Progression;
            Add(ref hash, progression == null ? -1 : progression.Level);
            Add(ref hash, progression == null ? -1 : progression.ExpToNextLevel);
            Add(ref hash, progression == null ? -1 : progression.ExpDeficit);
            Add(ref hash, progression == null ? -1 : progression.SkillPoints);
            Add(ref hash, progression == null ? 0f : Progression.XPGain);

            AddItems(ref hash, player.inventory == null ? null : player.inventory.GetSlots());
            AddItems(ref hash, player.bag == null ? null : player.bag.GetSlots());
            AddQuests(ref hash, player.QuestJournal);
            AddBuffs(ref hash, player.Buffs);
            return new SemanticSnapshot(hash);
        }

        private static void AddItems(ref ulong hash, ItemStack[] items)
        {
            if (items == null) { Add(ref hash, -1); return; }
            Add(ref hash, items.Length);
            for (int i = 0; i < items.Length; i++)
            {
                Add(ref hash, i);
                Add(ref hash, items[i].count);
                AddItemValue(ref hash, items[i].itemValue, 0);
            }
        }

        private static void AddItemValue(ref ulong hash, ItemValue value, int depth)
        {
            Add(ref hash, value.type);
            Add(ref hash, value.Meta);
            Add(ref hash, value.Quality);
            Add(ref hash, value.UseTimes);
            Add(ref hash, value.Activated ? 1 : 0);
            Add(ref hash, value.SelectedAmmoTypeIndex);
            if (depth >= 2) return;
            AddItemValues(ref hash, value.Modifications, depth + 1);
            AddItemValues(ref hash, value.CosmeticMods, depth + 1);
        }

        private static void AddItemValues(ref ulong hash, ItemValue[] values, int depth)
        {
            if (values == null) { Add(ref hash, -1); return; }
            Add(ref hash, values.Length);
            for (int i = 0; i < values.Length; i++) AddItemValue(ref hash, values[i], depth);
        }

        private static void AddQuests(ref ulong hash, QuestJournal journal)
        {
            if (journal == null || journal.quests == null) { Add(ref hash, -1); return; }
            Add(ref hash, journal.quests.Count);
            for (int i = 0; i < journal.quests.Count; i++)
            {
                Quest quest = journal.quests[i];
                if (quest == null) { Add(ref hash, -1); continue; }
                Add(ref hash, quest.ID);
                Add(ref hash, (int)quest.CurrentState);
                Add(ref hash, quest.CurrentPhase);
                Add(ref hash, quest.ActiveObjectives);
                Add(ref hash, quest.OptionalComplete ? 1 : 0);
            }
        }

        private static void AddBuffs(ref ulong hash, EntityBuffs buffs)
        {
            if (buffs == null || buffs.ActiveBuffs == null) { Add(ref hash, -1); return; }
            List<BuffValue> values = new List<BuffValue>(buffs.ActiveBuffs);
            values.Sort(delegate(BuffValue left, BuffValue right)
            {
                return string.CompareOrdinal(left == null ? null : left.buffName,
                    right == null ? null : right.buffName);
            });
            Add(ref hash, values.Count);
            for (int i = 0; i < values.Count; i++)
            {
                BuffValue value = values[i];
                if (value == null) { Add(ref hash, -1); continue; }
                Add(ref hash, value.buffName);
                Add(ref hash, value.stackEffectMultiplier);
                Add(ref hash, (int)value.buffFlags);
            }
        }

        private static void Add(ref ulong hash, string value)
        {
            if (value == null) { Add(ref hash, -1); return; }
            unchecked
            {
                Add(ref hash, value.Length);
                for (int i = 0; i < value.Length; i++)
                {
                    hash ^= value[i];
                    hash *= Prime;
                }
            }
        }

        private static void Add(ref ulong hash, float value)
        {
            unchecked
            {
                byte[] bytes = BitConverter.GetBytes(value);
                for (int i = 0; i < bytes.Length; i++)
                {
                    hash ^= bytes[i];
                    hash *= Prime;
                }
            }
        }

        private static void Add(ref ulong hash, int value)
        {
            unchecked
            {
                for (int i = 0; i < 4; i++)
                {
                    hash ^= (byte)(value >> (i * 8));
                    hash *= Prime;
                }
            }
        }
    }
}
