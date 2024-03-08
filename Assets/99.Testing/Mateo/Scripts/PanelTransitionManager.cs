using Steamworks.Data;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    public class PanelTransitionManager : MonoBehaviour
    {
        static readonly string TRANSITION_PROP = "KVRL_PanelTransition";
        static int TRANSITION_ID = -1;

        static int TransitionId
        {
            get
            {
                if (TRANSITION_ID == -1)
                {
                    TRANSITION_ID = Shader.PropertyToID(TRANSITION_PROP);
                }
                return TRANSITION_ID;
            }
        }


        [Header("Demo Test")]
        public bool autoTest = false;
        [Min(0f)]
        public float hold = 1f;
        public float period = 5f;

        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {
            if (autoTest)
            {
                SetTransitionBlend(TestWaveValue());
            }
        }

        float TestWaveValue()
        {
            float theta = Mathf.PI * 2f* Time.time / period;
            float rawWave = -Mathf.Cos(theta) * (1 + hold);
            float mappedWave = Mathf.InverseLerp(-1f, 1f, rawWave);

            return Mathf.Clamp01(mappedWave);
        }

        void SetTransitionBlend(float f)
        {
            Shader.SetGlobalFloat(TransitionId, f);
        }
    }
}
