using Oculus.Interaction;
using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using Unity.AppUI.UI;
using UnityEngine;
using UnityEngine.Events;

namespace KVRL.HSS08.Testing
{
    public class TestEnvironmentSwapper : MonoBehaviour
    {
        [SerializeField] OVRManager ovr;
        [SerializeField] OVRPassthroughLayer passthrough;
        [SerializeField] ObjectPoolPlacer pool;

        public float swapDuration = 1f;

        public EnvironmentSwapEvent onSwap = new EnvironmentSwapEvent();
        public EnvironmentSwapEvent onPassthrough = new EnvironmentSwapEvent();
        public EnvironmentSwapEvent onVirtual = new EnvironmentSwapEvent();

        private bool isPassthrough = true;
        public bool IsPassthrough { get { return isPassthrough; } }

        private Coroutine swapCoroutine = null;

        private static TestEnvironmentSwapper _instance;
        public bool ignorePointerEvent;
        public static TestEnvironmentSwapper Instance
        {
            get
            {
                return _instance;
            }

            private set { _instance = value; }
        }

        private void Awake()
        {
            Instance = this;
        }

        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {

        }

        public void TriggerSwap(PointerEvent evt)
        {
            /// TODO:
            /// Implement
            /// Add filtering via PointerEvent data field
            /// 
            if (ignorePointerEvent) return;
            if (FilterEvent(evt.Data))
            {
                if (swapDuration <= 0)
                {
                    TriggerFX(evt);
                    SwapPassthroughState();
                    SwapEnvironments();
                } else if (swapCoroutine == null)
                {
                    swapCoroutine = StartCoroutine(PerformSwapSequence(evt.Pose.position, -evt.Pose.forward));
                }
            }
        }

        bool FilterEvent(object data)
        {
            /// TODO:
            /// Implement filter based on PointerEvent data (possibly Scriptable Object)
            /// 

            if (data is InteractionData iData)
            {
                return (iData.interactions & ValidInteractions.EnvSwap) != 0;
            }

            return true;
        }

        [Button]
        void TestSwapCoroutine()
        {
            StartCoroutine(PerformSwapSequence(Vector3.zero, new Vector3(0, 0, -1)));
        }

        IEnumerator PerformSwapSequence(Vector3 pos, Vector3 norm)
        {
            float startTime = Time.time;
            float endTime = startTime + swapDuration;
            float midpoint = (startTime + endTime) * 0.5f;

            bool oldPassthroughState = IsPassthrough;
            bool newPassthroughState = !oldPassthroughState;

            Vector3 positionWS = pos;  new Vector3(0, 1, 1);
            Vector3 normalWS = norm;  new Vector3(0, 0, -1);

            while (Time.time < midpoint)
            {
                // Fade out current state
                float t_out = 1 - Mathf.InverseLerp(startTime, midpoint, Time.time); // From 1 to 0

                if (oldPassthroughState)
                {
                    FadePassthroughState(t_out);
                }

                yield return null;
            }

            // Midpoint magic
            TriggerFX(positionWS, normalWS);
            SwapPassthroughState();
            SwapEnvironments();

            while (Time.time < endTime)
            {
                // Fade in next stage
                float t_in = Mathf.InverseLerp(midpoint, endTime, Time.time); // From 0 to 1

                if (newPassthroughState)
                {
                    FadePassthroughState(t_in);
                }

                yield return null;
            }

            // Finalize
            if (newPassthroughState)
            {
                FadePassthroughState(1);
            }

            swapCoroutine = null;
        }

        void TriggerFX(Vector3 posWS, Vector3 normWS)
        {
            if (pool != null)
            {
                pool.PlaceObject(posWS, normWS);
            }
        }

        void TriggerFX(PointerEvent evt)
        {
            /// TODO:
            /// Implement positioning and animation of distorsion effect
            /// 

            if (pool != null)
            {
                pool.PlaceObject(evt);
            }
        }

        void FadePassthroughState(float t)
        {
            if (passthrough != null)
            {
                passthrough.textureOpacity = t;
            }
        }

        void SwapPassthroughState()
        {
            isPassthrough = !isPassthrough;

            ovr.isInsightPassthroughEnabled = isPassthrough;
        }

        void SwapEnvironments()
        {
            EnvironmentSwapData data = new EnvironmentSwapData();

            onSwap.Invoke(data);

            SetEnvironment(isPassthrough, data);

            //if (isPassthrough) {
            //    onPassthrough.Invoke(data);
            //} else
            //{
            //    onVirtual.Invoke(data);
            //}
        }

        void SetEnvironment(bool pthru, EnvironmentSwapData data)
        {
            if (pthru)
            {
                onPassthrough.Invoke(data);
            }
            else
            {
                onVirtual.Invoke(data);
            }
        }
    }

    [System.Serializable]
    public class EnvironmentSwapEvent : UnityEvent<EnvironmentSwapData>
    {

    }

    [System.Serializable]
    public struct EnvironmentSwapData
    {
        public static EnvironmentSwapData Empty => new EnvironmentSwapData();
    }

    public class EnvironmentSwapManager
    {
        private static EnvironmentSwapManager _instance;
        public static EnvironmentSwapManager Instance
        {
            get
            {
                if (_instance == null)
                {
                    _instance = new EnvironmentSwapManager();
                }

                return _instance;
            }
        }


    }
}
