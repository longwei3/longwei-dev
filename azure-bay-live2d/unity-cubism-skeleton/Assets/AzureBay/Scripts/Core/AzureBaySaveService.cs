using System;
using System.IO;
using AzureBay.Data;
using UnityEngine;

namespace AzureBay.Core
{
    public static class AzureBaySaveService
    {
        private const string SaveFileName = "azure_bay_save.json";

        private static string SavePath => Path.Combine(Application.persistentDataPath, SaveFileName);

        public static GameSaveData LoadOrCreateDefault()
        {
            var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            if (!File.Exists(SavePath))
            {
                return GameSaveData.CreateDefault(now);
            }

            try
            {
                var json = File.ReadAllText(SavePath);
                var data = JsonUtility.FromJson<GameSaveData>(json);
                return data ?? GameSaveData.CreateDefault(now);
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"[AzureBay] Load failed, using defaults: {ex.Message}");
                return GameSaveData.CreateDefault(now);
            }
        }

        public static void Save(GameSaveData data)
        {
            try
            {
                data.lastSaveUnix = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                var json = JsonUtility.ToJson(data, true);
                File.WriteAllText(SavePath, json);
            }
            catch (Exception ex)
            {
                Debug.LogError($"[AzureBay] Save failed: {ex.Message}");
            }
        }
    }
}
