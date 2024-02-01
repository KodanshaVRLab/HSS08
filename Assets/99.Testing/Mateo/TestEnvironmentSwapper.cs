using Oculus.Interaction;
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
        [SerializeField] ObjectPoolPlacer pool;

        public EnvironmentSwapEvent onSwap = new EnvironmentSwapEvent();
        public EnvironmentSwapEvent onPassthrough = new EnvironmentSwapEvent();
        public EnvironmentSwapEvent onVirtual = new EnvironmentSwapEvent();

        private bool isPassthrough = true;
        public bool IsPassthrough { get { return isPassthrough; } }

        private static TestEnvironmentSwapper _instance;
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

            if (FilterEvent(evt.Data))
            {
                TriggerFX(evt);
                SwapPassthroughState();
                SwapEnvironments();
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
