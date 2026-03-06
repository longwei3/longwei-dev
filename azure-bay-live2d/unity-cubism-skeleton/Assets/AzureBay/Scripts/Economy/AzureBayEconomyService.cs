using System;
using AzureBay.Data;

namespace AzureBay.Economy
{
    public static class AzureBayEconomyService
    {
        public static float OrchardShellPerHour(int level) => 24f + (level - 1) * 12f;
        public static float OrchardWoodPerHour(int level) => 2f + (level - 1) * 0.8f;
        public static float FisheryShellPerHour(int level) => 18f + (level - 1) * 10f;
        public static float FisheryFishPerHour(int level) => 3f + (level - 1) * 1.2f;

        public static void TickProduction(GameSaveData data, float deltaSeconds)
        {
            if (data == null || deltaSeconds <= 0f) return;

            var hours = deltaSeconds / 3600f;
            var orchard = data.GetBuilding("orchard");
            var fishery = data.GetBuilding("fishery");
            if (orchard == null || fishery == null) return;

            orchard.storedShell += OrchardShellPerHour(orchard.level) * hours;
            orchard.storedWood += OrchardWoodPerHour(orchard.level) * hours;

            fishery.storedShell += FisheryShellPerHour(fishery.level) * hours;
            fishery.storedFish += FisheryFishPerHour(fishery.level) * hours;
        }

        public static void SettleOffline(GameSaveData data, long nowUnix, float capHours = 8f)
        {
            if (data == null) return;
            var elapsedSeconds = Math.Max(0f, nowUnix - data.lastTickUnix);
            var cappedSeconds = Math.Min(elapsedSeconds, capHours * 3600f);
            TickProduction(data, cappedSeconds);
            data.lastTickUnix = nowUnix;
        }

        public static int CollectBuilding(GameSaveData data, string buildingId)
        {
            var b = data?.GetBuilding(buildingId);
            if (b == null) return 0;

            var shell = (int)MathF.Floor(b.storedShell);
            var wood = (int)MathF.Floor(b.storedWood);
            var fish = (int)MathF.Floor(b.storedFish);

            b.storedShell -= shell;
            b.storedWood -= wood;
            b.storedFish -= fish;

            data.resources.shell += shell;
            data.resources.wood += wood;
            data.resources.fish += fish;

            return shell + wood + fish;
        }

        public static bool UpgradeOrchard(GameSaveData data)
        {
            var b = data?.GetBuilding("orchard");
            if (b == null || b.level >= 5) return false;

            var shellCost = 120 * b.level;
            var woodCost = 14 * b.level;
            if (!data.resources.Has(shellCost, woodCost, 0)) return false;

            data.resources.Spend(shellCost, woodCost, 0);
            b.level += 1;
            return true;
        }

        public static bool UpgradeFishery(GameSaveData data)
        {
            var b = data?.GetBuilding("fishery");
            if (b == null || b.level >= 5) return false;

            var shellCost = 140 * b.level;
            var fishCost = 8 * b.level;
            if (!data.resources.Has(shellCost, 0, fishCost)) return false;

            data.resources.Spend(shellCost, 0, fishCost);
            b.level += 1;
            return true;
        }
    }
}
