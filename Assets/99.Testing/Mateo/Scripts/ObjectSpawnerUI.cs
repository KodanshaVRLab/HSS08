using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace KVRL.HSS08.Testing
{
    public class ObjectSpawnerUI : MonoBehaviour
    {
        public ObjectSpawner spawner;

        [SerializeField] Button spawnButton;
        [SerializeField] Button clearButton;
        [SerializeField] TMP_Dropdown objectSelector;
        [SerializeField] Slider countSlider;
        [SerializeField] TMP_Text countLabel;
        [SerializeField] TMP_Text singleStats;
        [SerializeField] TMP_Text totalStats;

        ModelStats[] spawnerStats;
        int currentTemplate = 0;
        int spawnCount = 1;



        // Start is called before the first frame update
        void Start()
        {
            FetchTemplateData();
            PopulateDropdown();
            BindSpawningCallbacks();
        }

        // Update is called once per frame
        void Update()
        {

        }

        #region Setup

        void FetchTemplateData()
        {
            if(spawner != null)
            {
                spawnerStats = new ModelStats[spawner.TemplateCount];
                for (int i = 0; i < spawnerStats.Length; i++)
                {
                    spawnerStats[i] = spawner.GetTemplateStats(i);
                }
            }
        }

        void PopulateDropdown()
        {
            if (spawner != null && objectSelector != null)
            {
                objectSelector.ClearOptions();
                
                List<TMP_Dropdown.OptionData> options = new List<TMP_Dropdown.OptionData>();
                for (int i = 0; i < spawnerStats.Length;i++)
                {
                    options.Add(new TMP_Dropdown.OptionData(spawnerStats[i].name));
                }
                objectSelector.AddOptions(options);

                objectSelector.onValueChanged.AddListener(SwitchTargetTemplate);
            }
        }

        void BindSpawningCallbacks()
        {
            if (spawnButton != null)
            {
                spawnButton.onClick.AddListener(TriggerSpawn);
            }

            if (clearButton != null)
            {
                clearButton.onClick.AddListener(TriggerClear);
            }

            if (countSlider != null)
            {
                countSlider.wholeNumbers = true;
                countSlider.minValue = 1;
                countSlider.maxValue = 10;
                countSlider.value = spawnCount;
                countSlider.onValueChanged.AddListener(UpdateSpawnCount);

                UpdateSpawnCount(spawnCount);
            }

            UpdateSingleStats(currentTemplate);
            UpdateTotalStats();
        }

        #endregion

        #region Callbacks

        [Button]
        void TriggerSpawn()
        {
            if (spawner != null)
            {
                for (int i = 0; i < spawnCount; i++)
                {
                    spawner.Spawn(currentTemplate);
                }

                UpdateTotalStats();
            }
        }

        [Button]
        void TriggerClear()
        {
            if (spawner != null )
            {
                spawner.Clear();

                UpdateTotalStats();
            }
        }

        void SwitchTargetTemplate(int index)
        {
            UpdateSingleStats(index);
            currentTemplate = index;
        }

        void UpdateSingleStats(int index)
        {
            if (singleStats != null)
            {
                singleStats.text = spawnerStats[index].ToString();
            }
        }

        void UpdateTotalStats()
        {
            if (spawner != null && totalStats != null)
            {
                totalStats.text = spawner.TotalStats.ToString();
            }
        }

        void UpdateSpawnCount(float value)
        {
            spawnCount = (int)value;

            if (countLabel != null)
            {
                countLabel.text = spawnCount.ToString();
            }
        }

        #endregion
    }
}