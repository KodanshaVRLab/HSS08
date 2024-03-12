using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    [ExecuteAlways]
    public class PanelTransitionManager : MonoBehaviour
    {
        static readonly string TRANSITION_PROP = "KVRL_PanelTransition";
        static int TRANSITION_ID = -1;
        static readonly string TRANSITION_SPHERE = "KVRL_TransitionSphere";
        static int SPHERE_ID = -1;

        static readonly string KEYWORD_PASSTHROUGH = "_KVRL_PASSTHROUGH_ON";

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

        static int SphereId
        {
            get
            {
                if (SPHERE_ID == -1)
                {
                    SPHERE_ID = Shader.PropertyToID(TRANSITION_SPHERE);
                }
                return SPHERE_ID;
            }
        }

        public bool applyInEditor = true;
        [Range(0, 1)]
        public float transitionBlend = 0;
        public Vector3 transitionCenter = Vector3.zero;
        [Min(0f)]
        public float transitionRadius = 5f;

        [Header("Demo Test")]
        public bool autoTest = false;
        public bool testInEditor = false;
        [Min(0f)]
        public float hold = 1f;
        public float period = 5f;

        // Start is called before the first frame update
        void Start()
        {

        }

        private void OnEnable()
        {
            if (Application.isPlaying)
            {
                Shader.EnableKeyword(KEYWORD_PASSTHROUGH);
            } else
            {
                Shader.DisableKeyword(KEYWORD_PASSTHROUGH);
            }
        }

        // Update is called once per frame
        void Update()
        {
            if (autoTest && (Application.isPlaying || testInEditor))
            {
               transitionBlend = TestWaveValue();
            }

            if (applyInEditor)
            {
                SetTransitionBlend(transitionBlend);
                SetTransitionSphere(transitionCenter, transitionRadius);
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

        void SetTransitionSphere(Vector3 center, float radius)
        {
            Vector4 sphere = new Vector4();
            sphere.x = center.x;
            sphere.y = center.y;
            sphere.z = center.z;
            sphere.w = radius;

            Shader.SetGlobalVector(SphereId, sphere);
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.color = Color.yellow;
            Gizmos.DrawSphere(transitionCenter, 0.05f);
            //Gizmos.DrawWireSphere(transitionCenter, transitionRadius);
        }
    }
}
