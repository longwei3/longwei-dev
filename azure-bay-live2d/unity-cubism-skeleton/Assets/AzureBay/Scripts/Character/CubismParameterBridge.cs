using AzureBay.Data;
using UnityEngine;

namespace AzureBay.Character
{
    public class CubismParameterBridge : MonoBehaviour
    {
        [SerializeField] private CharacterId characterId = CharacterId.Xi;
        [SerializeField] private float smooth = 6f;

        private float _happy;
        private float _tired;
        private float _angry;

        public void ApplyMood(int mood)
        {
            _happy = 0f;
            _tired = 0f;
            _angry = 0f;

            if (mood >= 80) _happy = 1f;
            else if (mood < 45 && mood >= 25) _tired = 1f;
            else if (mood < 25) _angry = 1f;
        }

        private void Update()
        {
#if CUBISM_SDK_IMPORTED
            // Map mood weights to Cubism parameters here when Cubism SDK is present.
            // Example:
            // happyParam.Value = Mathf.Lerp(happyParam.Value, _happy, Time.deltaTime * smooth);
            // tiredParam.Value = Mathf.Lerp(tiredParam.Value, _tired, Time.deltaTime * smooth);
            // angryParam.Value = Mathf.Lerp(angryParam.Value, _angry, Time.deltaTime * smooth);
#endif
        }
    }
}
