using System;
using System.Collections.Generic;

namespace AzureBay.Data
{
    public enum CharacterId
    {
        Xi = 0,
        Ning = 1
    }

    [Serializable]
    public class CharacterState
    {
        public CharacterId id;
        public int level = 1;
        public int exp;
        public int mood = 65;
        public long lastInteractUnix;
    }

    [Serializable]
    public class ResourceState
    {
        public int shell = 220;
        public int star = 5;
        public int wood = 30;
        public int fish = 12;

        public bool Has(int shellCost, int woodCost, int fishCost, int starCost = 0)
        {
            return shell >= shellCost && wood >= woodCost && fish >= fishCost && star >= starCost;
        }

        public void Spend(int shellCost, int woodCost, int fishCost, int starCost = 0)
        {
            shell -= shellCost;
            wood -= woodCost;
            fish -= fishCost;
            star -= starCost;
        }
    }

    [Serializable]
    public class BuildingState
    {
        public string id;
        public int level = 1;
        public float storedShell;
        public float storedWood;
        public float storedFish;
    }

    [Serializable]
    public class GameSaveData
    {
        public int version = 1;
        public CharacterId activeCharacter = CharacterId.Xi;
        public ResourceState resources = new ResourceState();
        public List<CharacterState> characters = new List<CharacterState>();
        public List<BuildingState> buildings = new List<BuildingState>();
        public long lastTickUnix;
        public long lastSaveUnix;

        public static GameSaveData CreateDefault(long nowUnix)
        {
            return new GameSaveData
            {
                activeCharacter = CharacterId.Xi,
                resources = new ResourceState(),
                characters = new List<CharacterState>
                {
                    new CharacterState { id = CharacterId.Xi, lastInteractUnix = nowUnix },
                    new CharacterState { id = CharacterId.Ning, lastInteractUnix = nowUnix }
                },
                buildings = new List<BuildingState>
                {
                    new BuildingState { id = "orchard", level = 1 },
                    new BuildingState { id = "fishery", level = 1 }
                },
                lastTickUnix = nowUnix,
                lastSaveUnix = nowUnix
            };
        }

        public CharacterState GetCharacter(CharacterId id)
        {
            var index = characters.FindIndex(c => c.id == id);
            return index >= 0 ? characters[index] : null;
        }

        public BuildingState GetBuilding(string id)
        {
            return buildings.Find(b => b.id == id);
        }
    }
}
