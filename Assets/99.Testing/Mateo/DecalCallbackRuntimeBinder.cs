using Oculus.Interaction;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    public class DecalCallbackRuntimeBinder : MonoBehaviour
    {
        [SerializeField] bool enableDecals = true;
        [SerializeField] bool enableEnvSwap = true;
        [SerializeField] bool enableGenerics = true;

        DecalManagerTest decalSystem;
        TestEnvironmentSwapper swapSystem;

        PointerInteractionSystem[] genericSystems = null;

        PointableUnityEventWrapper callbackWrapper;

        [SerializeField] bool verbose = false;

        private void Awake()
        {
            FetchReferences();
        }

        private void OnEnable()
        {
            if (enableDecals)
            {
                BindDecalCallbacks();
            }

            if (enableEnvSwap)
            {
                BindEnvSwapCallbacks();
            }

            if (enableGenerics)
            {
                BindGenericCallbacks();
            }
        }

        private void OnDisable()
        {
            if (enableDecals)
            {
                UnbindDecalCallbacks();
            }

            if (enableEnvSwap)
            {
                UnbindEnvSwapCallbacks();
            }

            if (enableGenerics)
            {
                UnbindGenericCallbacks();
            }
        }

        void FetchReferences(bool log = false)
        {
            // keeping log option if needed eventually for static scene refs
            if (decalSystem == null)
            {
                decalSystem = FindObjectOfType<DecalManagerTest>();
                if (decalSystem != null && log)
                {
                    Debug.Log($"Auto-assigned Decal Manager {decalSystem.name} to {name}'s Decal Callback Runtime Binder.");
                }
            }

            if (swapSystem == null)
            {
                swapSystem = FindObjectOfType<TestEnvironmentSwapper>();
                if (swapSystem != null && log)
                {
                    Debug.Log($"Auto-assigned Test Env Swapper {swapSystem.name} to {name}'s Decal Callback Runtime Binder.");
                }
            }

            if (callbackWrapper == null)
            {
                if (TryGetComponent(out callbackWrapper) && log)
                {
                    Debug.Log($"Auto-assigned Pointable Unity Event Wrapper found on {name} to its Decal Callback Runtime Binder.");
                }
            }

            if (genericSystems == null)
            {
                UpdateGenericSystems(log);
            }
        }

        void UpdateGenericSystems(bool log = false)
        {
            genericSystems = FindObjectsOfType<PointerInteractionSystem>(true);
            if (log && genericSystems != null && genericSystems.Length > 0)
            {
                Debug.Log($"Found a total of {genericSystems.Length} Pointer Interaction Systems");
            }
        }

        void BindDecalCallbacks()
        {
            if (decalSystem != null && callbackWrapper != null)
            {
                callbackWrapper.WhenSelect.AddListener(decalSystem.PlaceDecal);

                if (verbose)
                {
                    Debug.Log($"Added {decalSystem.name}'s listener to {callbackWrapper.name}'s Event");
                }
            }
            else if (verbose)
            {
                Debug.Log($"Binding failed. Staus:\nDecalSystem: {decalSystem}\nWrapper: {callbackWrapper}");
            }
        }

        void BindEnvSwapCallbacks()
        {
            if (swapSystem != null && callbackWrapper != null)
            {
                callbackWrapper.WhenSelect.AddListener(swapSystem.TriggerSwap);

                if (verbose)
                {
                    Debug.Log($"Added {swapSystem.name}'s listener to {callbackWrapper.name}'s Event");
                }
            }
            else if (verbose)
            {
                Debug.Log($"Binding failed. Staus:\nEnvSwapSystem: {swapSystem}\nWrapper: {callbackWrapper}");
            }
        }

        void BindGenericCallbacks()
        {
            if (genericSystems != null && callbackWrapper != null)
            {
                foreach (var sys in genericSystems)
                {
                    if (sys != null && sys.IsMainSystem)
                    {
                        callbackWrapper.WhenSelect.AddListener(sys.TriggerInteraction);
                    } else if (verbose)
                    {
                        Debug.LogWarning($"Skipped binding Pointer Interaction System {sys.name} because it's not a Main System");
                    }
                }
            }
        }

        void UnbindDecalCallbacks()
        {
            if (decalSystem != null && callbackWrapper != null)
            {
                callbackWrapper.WhenSelect.RemoveListener(decalSystem.PlaceDecal);

                if (verbose)
                {
                    Debug.Log($"Removed {decalSystem.name}'s listener from {callbackWrapper.name}'s Event");
                }
            }
            else if (verbose)
            {
                Debug.Log($"Binding failed. Staus:\nDecalSystem: {decalSystem}\nWrapper: {callbackWrapper}");
            }
        }

        void UnbindEnvSwapCallbacks()
        {
            if (swapSystem != null && callbackWrapper != null)
            {
                callbackWrapper.WhenSelect.RemoveListener(swapSystem.TriggerSwap);

                if (verbose)
                {
                    Debug.Log($"Removed {swapSystem.name}'s listener from {callbackWrapper.name}'s Event");
                }
            }
            else if (verbose)
            {
                Debug.Log($"Binding failed. Staus:\nEnvSwapSystem: {swapSystem}\nWrapper: {callbackWrapper}");
            }
        }

        void UnbindGenericCallbacks()
        {
            if (genericSystems != null && callbackWrapper != null)
            {
                foreach (var sys in genericSystems)
                {
                    if (sys != null && sys.IsMainSystem)
                    {
                        callbackWrapper.WhenSelect.RemoveListener(sys.TriggerInteraction);
                    }
                    else if (verbose)
                    {
                        Debug.LogWarning($"Skipped unbinding Pointer Interaction System {sys.name} because it's not a Main System");
                    }
                }
            }
        }
    }
}
