using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    public class EnvironmentSwapListener : MonoBehaviour
    {
        [SerializeField] Renderer passthroughRenderer;
        [SerializeField] Renderer virtualRenderer;

        TestEnvironmentSwapper swapper;

        // Start is called before the first frame update
        void OnEnable()
        {
            swapper = TestEnvironmentSwapper.Instance;

            if (swapper != null )
            {
                BindCallbacks();

                SetCurrent();
            }
        }

        // Update is called once per frame
        void Update()
        {

        }

        private void OnDisable()
        {
            if ( swapper != null )
            {
                UnbindCallbacks();
            }
        }

        void BindCallbacks()
        {
            swapper.onPassthrough.AddListener(PassthroughCallback);
            swapper.onVirtual.AddListener(VirtualCallback);
        }

        void UnbindCallbacks()
        {
            swapper.onPassthrough.RemoveListener(PassthroughCallback);
            swapper.onVirtual.RemoveListener(VirtualCallback);
        }

        void SetCurrent()
        {
            if (swapper == null)
            {
                return;
            }

            if (swapper.IsPassthrough)
            {
                PassthroughCallback(EnvironmentSwapData.Empty);
            } else
            {
                VirtualCallback(EnvironmentSwapData.Empty);
            }
        }

        void PassthroughCallback(EnvironmentSwapData data)
        {
            if (passthroughRenderer != null)
            {
                passthroughRenderer.enabled = true;
            }

            if (virtualRenderer != null)
            {
                virtualRenderer.enabled = false;
            }
        }

        void VirtualCallback(EnvironmentSwapData data)
        {
            if (passthroughRenderer != null)
            {
                passthroughRenderer.enabled = false;
            }

            if (virtualRenderer != null)
            {
                virtualRenderer.enabled = true;
            }
        }
    }
}
