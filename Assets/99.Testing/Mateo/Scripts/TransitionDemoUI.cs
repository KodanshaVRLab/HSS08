using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace KVRL.HSS08.Testing
{
    public class TransitionDemoUI : MonoBehaviour
    {
        [SerializeField] PanelTransitionManager transition;

        [SerializeField] Slider durationSlider;
        [SerializeField] TMP_Text durationCounter;
        public float maxDuration = 10f;

        [SerializeField] Button swapButton;
        [SerializeField] Button passthroughButton;
        [SerializeField] Button virtualButton;

        [SerializeField] Toggle autoToggle;

        float Duration
        {
            get
            {
                if (durationSlider != null)
                {
                    return durationSlider.value;
                }

                return 1f;
            }
        }

        private void OnValidate()
        {
            if (transition == null)
            {
                transition = FindAnyObjectByType<PanelTransitionManager>();
            }
        }

        private void Awake()
        {
            if (durationSlider != null)
            {
                durationSlider.maxValue = maxDuration;
                durationSlider.onValueChanged.AddListener(OnChangeDuration);
                durationSlider.value = 1f;
            }

            if (autoToggle != null)
            {
                autoToggle.onValueChanged.AddListener(OnToggleAuto);
            }

            if (swapButton != null)
            {
                swapButton.onClick.AddListener(OnTriggerSwap);
            }

            if (passthroughButton != null)
            {
                passthroughButton.onClick.AddListener(OnTriggerPassthrough);
            }

            if (virtualButton != null)
            {
                virtualButton.onClick.AddListener(OnTriggerVirtual);
            }
        }

        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {

        }

        void OnChangeDuration(float value)
        {
            if (transition != null)
            {
                //transition.period = value;
                //transition.hold = 
            }

            if (durationCounter != null)
            {
                durationCounter.text = value.ToString("F2");
            }
        }

        void OnToggleAuto(bool state)
        {
            if (transition != null)
            {
                transition.autoTest = state;
            }
        }

        void OnTriggerSwap()
        {
            if (transition != null)
            {
                transition.SwapState(Duration);
            }
        }

        void OnTriggerPassthrough()
        {
            if(transition != null)
            {
                transition.SwapToPassthrough(Duration);
            }
        }

        void OnTriggerVirtual()
        {
            if (transition != null)
            {
                transition.SwapToVirtual(Duration);
            }
        }
    }
}
