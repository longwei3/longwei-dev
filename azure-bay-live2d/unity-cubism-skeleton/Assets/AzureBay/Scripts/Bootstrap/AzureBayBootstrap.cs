using System;
using AzureBay.Core;
using AzureBay.Data;
using AzureBay.Economy;
using AzureBay.UI;
using UnityEngine;

namespace AzureBay.Bootstrap
{
    public class AzureBayBootstrap : MonoBehaviour
    {
        [SerializeField] private AzureBayHudPresenter hudPresenter;
        [SerializeField] private float autosaveIntervalSeconds = 8f;

        private GameSaveData _data;
        private float _autosaveTimer;

        public GameSaveData Data => _data;

        private void Awake()
        {
            _data = AzureBaySaveService.LoadOrCreateDefault();
            var nowUnix = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            AzureBayEconomyService.SettleOffline(_data, nowUnix);
        }

        private void Start()
        {
            RefreshHud();
        }

        private void Update()
        {
            AzureBayEconomyService.TickProduction(_data, Time.deltaTime);
            _data.lastTickUnix = DateTimeOffset.UtcNow.ToUnixTimeSeconds();

            _autosaveTimer += Time.deltaTime;
            if (_autosaveTimer >= autosaveIntervalSeconds)
            {
                _autosaveTimer = 0f;
                AzureBaySaveService.Save(_data);
            }

            RefreshHud();
        }

        public void CollectAll()
        {
            AzureBayEconomyService.CollectBuilding(_data, "orchard");
            AzureBayEconomyService.CollectBuilding(_data, "fishery");
            RefreshHud();
        }

        public void UpgradeOrchard()
        {
            AzureBayEconomyService.UpgradeOrchard(_data);
            RefreshHud();
        }

        public void UpgradeFishery()
        {
            AzureBayEconomyService.UpgradeFishery(_data);
            RefreshHud();
        }

        private void OnApplicationPause(bool pauseStatus)
        {
            if (pauseStatus)
            {
                AzureBaySaveService.Save(_data);
            }
        }

        private void OnApplicationQuit()
        {
            AzureBaySaveService.Save(_data);
        }

        private void RefreshHud()
        {
            if (hudPresenter != null)
            {
                hudPresenter.Render(_data);
            }
        }
    }
}
