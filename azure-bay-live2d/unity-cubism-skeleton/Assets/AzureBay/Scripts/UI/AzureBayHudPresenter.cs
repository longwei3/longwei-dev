using AzureBay.Data;
using TMPro;
using UnityEngine;

namespace AzureBay.UI
{
    public class AzureBayHudPresenter : MonoBehaviour
    {
        [Header("Resource")]
        [SerializeField] private TMP_Text shellText;
        [SerializeField] private TMP_Text starText;
        [SerializeField] private TMP_Text woodText;
        [SerializeField] private TMP_Text fishText;

        [Header("Character")]
        [SerializeField] private TMP_Text activeCharacterText;
        [SerializeField] private TMP_Text levelText;
        [SerializeField] private TMP_Text moodText;

        [Header("Buildings")]
        [SerializeField] private TMP_Text orchardText;
        [SerializeField] private TMP_Text fisheryText;

        public void Render(GameSaveData data)
        {
            if (data == null) return;

            if (shellText != null) shellText.text = data.resources.shell.ToString();
            if (starText != null) starText.text = data.resources.star.ToString();
            if (woodText != null) woodText.text = data.resources.wood.ToString();
            if (fishText != null) fishText.text = data.resources.fish.ToString();

            var active = data.GetCharacter(data.activeCharacter);
            if (active != null)
            {
                if (activeCharacterText != null) activeCharacterText.text = data.activeCharacter.ToString();
                if (levelText != null) levelText.text = $"Lv.{active.level} ({active.exp}/{80 + active.level * 35})";
                if (moodText != null) moodText.text = active.mood.ToString();
            }

            var orchard = data.GetBuilding("orchard");
            if (orchardText != null && orchard != null)
            {
                orchardText.text = $"Lv.{orchard.level}  S:{Mathf.FloorToInt(orchard.storedShell)} W:{Mathf.FloorToInt(orchard.storedWood)}";
            }

            var fishery = data.GetBuilding("fishery");
            if (fisheryText != null && fishery != null)
            {
                fisheryText.text = $"Lv.{fishery.level}  S:{Mathf.FloorToInt(fishery.storedShell)} F:{Mathf.FloorToInt(fishery.storedFish)}";
            }
        }
    }
}
