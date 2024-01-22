using Oculus.Interaction;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    public class DecalCallbackRuntimeBinder : MonoBehaviour
    {
        DecalManagerTest decalSystem;
        PointableUnityEventWrapper callbackWrapper;
        [SerializeField] bool verbose = false;

        private void Awake()
        {
            FetchReferences();
        }

        private void OnEnable()
        {
            if (decalSystem != null && callbackWrapper != null)
            {
                callbackWrapper.WhenSelect.AddListener(decalSystem.PlaceDecal);

                if (verbose)
                {
                    Debug.Log($"Added {decalSystem.name}'s listener to {callbackWrapper.name}'s Event");
                }
            } else if (verbose)
            {
                Debug.Log($"Binding failed. Staus:\nDecalSystem: {decalSystem}\nWrapper: {callbackWrapper}");
            }
        }

        private void OnDisable()
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

            if (callbackWrapper == null)
            {
                if (TryGetComponent(out callbackWrapper) && log)
                {
                    Debug.Log($"Auto-assigned Pointable Unity Event Wrapper found on {name} to its Decal Callback Runtime Binder.");
                }
            }
        }
    }
}
