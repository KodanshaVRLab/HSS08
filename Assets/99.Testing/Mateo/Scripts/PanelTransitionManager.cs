using KVRL.KVRLENGINE.Graphics;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

namespace KVRL.HSS08.Testing
{
    [ExecuteAlways]
    public class PanelTransitionManager : MonoBehaviour
    {
        static ShaderPropertyID TRANSITION_PROP = new ShaderPropertyID("KVRL_PanelTransition");
        static ShaderPropertyID TRANSITION_SPHERE = new ShaderPropertyID("KVRL_TransitionSphere");
        static ShaderPropertyID TRANSITION_FUZZ = new ShaderPropertyID("KVRL_TransitionFuzz");

        static readonly string KEYWORD_PASSTHROUGH = "_KVRL_PASSTHROUGH_ON";

        public bool applyInEditor = true;
        [Range(0, 1)]
        public float transitionBlend = 0;
        private float lastBlend = -0;
        public Vector3 transitionCenter = Vector3.zero;
        [Min(0f)]
        public float transitionRadius = 5f;
        [Min(0.001f)]
        public float transitionFuzz = 1f;

        public RoomTransitionEvent onTransitionStart;
        public RoomTransitionEvent onTransitionEnd;
        public RoomTransitionEvent onLeaveStateZero;
        public RoomTransitionEvent onReachStateZero;
        public RoomTransitionEvent onLeaveStateOne;
        public RoomTransitionEvent onReachStateOne;

        [Header("Demo Test")]
        public bool autoTest = false;
        public bool testInEditor = false;
        [Min(0f)]
        public float hold = 1f;
        public float period = 5f;


        private Coroutine blendCoroutine = null;

        // Start is called before the first frame update
        void Start()
        {

        }

        private void OnEnable()
        {
            if (Application.isPlaying)
            {
                Shader.EnableKeyword(KEYWORD_PASSTHROUGH);
            }
            else
            {
                Shader.DisableKeyword(KEYWORD_PASSTHROUGH);
                // Undo play mode changes on global properties
                SetTransitionBlend(transitionBlend);
                SetTransitionSphere(transitionCenter, transitionRadius, transitionFuzz);
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
                SetTransitionSphere(transitionCenter, transitionRadius, transitionFuzz);
            }
        }

        public void SwapState(float duration = 1f)
        {
            /// TODO:
            /// Implement public state change call
            /// Implement event callbacks
            /// Set up demo scene with relevant callbacks (ie toggle passthrough off/on on Reach/LeaveStateOne
            /// 

            float targetVal = 1 - Mathf.Round(transitionBlend);
            DoStateSwap(targetVal, duration);
        }

        public void SwapToPassthrough(float duration = 1f)
        {
            DoStateSwap(0f, duration);
        }

        public void SwapToVirtual(float duration = 1f)
        {
            DoStateSwap(1f, duration);
        }

        void DoStateSwap(float target, float duration = 1f)
        {
            if (blendCoroutine != null)
            {
                // Block any swaps if a blend is running
                return;
            }

            // Fade over duration
            if (duration > 0f)
            {
                blendCoroutine = StartCoroutine(FadeToState(target, duration));
            }
            else // Instant change
            {
                transitionBlend = target;
            }
        }

        IEnumerator FadeToState(float target, float duration)
        {
            float startTime = Time.time;
            float endTime = startTime + duration;
            float from = transitionBlend;

            if (onTransitionStart != null)
            {
                onTransitionStart.Invoke();
            }

            while (Time.time < endTime)
            {
                float t = Mathf.Clamp01(Mathf.InverseLerp(startTime, endTime, Time.time));
                float val = Mathf.Lerp(from, target, t);

                transitionBlend = val;

                yield return null;
            }

            transitionBlend = target;

            if (onTransitionEnd != null)
            {
                onTransitionEnd.Invoke();
            }

            blendCoroutine = null;
        }

        float TestWaveValue()
        {
            float theta = Mathf.PI * 2f * Time.time / period;
            float rawWave = -Mathf.Cos(theta) * (1 + hold);
            float mappedWave = Mathf.InverseLerp(-1f, 1f, rawWave);

            return Mathf.Clamp01(mappedWave);
        }

        void SetTransitionBlend(float f)
        {
            if (f != lastBlend)
            {
                if (lastBlend == 0 && f > lastBlend && onLeaveStateZero != null)
                {
                    onLeaveStateZero.Invoke();
                }
                else if (lastBlend == 1 && f < lastBlend && onLeaveStateOne != null)
                {
                    onLeaveStateOne.Invoke();
                }
                else if (f == 0 && onReachStateZero != null)
                {
                    onReachStateZero.Invoke();
                }
                else if (f == 1 && onReachStateOne != null)
                {
                    onReachStateOne.Invoke();
                }

                Shader.SetGlobalFloat(TRANSITION_PROP.Id, f);

                lastBlend = f;
            }
        }

        void SetTransitionSphere(Vector3 center, float radius, float fuzz = 0.5f)
        {
            Vector4 sphere = new Vector4();
            sphere.x = center.x;
            sphere.y = center.y;
            sphere.z = center.z;
            sphere.w = radius;

            Shader.SetGlobalVector(TRANSITION_SPHERE.Id, sphere);
            Shader.SetGlobalFloat(TRANSITION_FUZZ.Id, fuzz);
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.color = Color.yellow;
            Gizmos.DrawSphere(transitionCenter, 0.05f);
            //Gizmos.DrawWireSphere(transitionCenter, transitionRadius);
        }
    }

    [System.Serializable]
    public class RoomTransitionEvent : UnityEvent { }
}
