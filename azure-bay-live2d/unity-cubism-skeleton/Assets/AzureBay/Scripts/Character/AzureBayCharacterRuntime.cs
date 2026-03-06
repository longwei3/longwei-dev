using System;
using AzureBay.Data;

namespace AzureBay.Character
{
    public static class AzureBayCharacterRuntime
    {
        public static int ExpNeed(int level)
        {
            return 80 + level * 35;
        }

        public static void GainAffection(CharacterState state, int amount)
        {
            if (state == null || amount <= 0) return;

            var nextExp = state.exp + amount;
            while (nextExp >= ExpNeed(state.level))
            {
                nextExp -= ExpNeed(state.level);
                state.level += 1;
            }

            state.exp = nextExp;
        }

        public static void AddMood(CharacterState state, int amount)
        {
            if (state == null) return;
            state.mood = Math.Clamp(state.mood + amount, 0, 100);
            state.lastInteractUnix = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        }

        public static string MoodState(int mood)
        {
            if (mood >= 80) return "happy";
            if (mood >= 45) return "calm";
            if (mood >= 25) return "tired";
            return "angry";
        }
    }
}
