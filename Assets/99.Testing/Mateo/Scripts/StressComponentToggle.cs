using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace KVRL.HSS08.Testing
{
    public class StressComponentToggle : MonoBehaviour
    {
        [SerializeField] Toggle toggle;
        [SerializeField] string target = "UnityEngine.MonoBehaviour";
         
        System.Type type;

        private void OnValidate()
        {
            if (toggle == null)
            {
                TryGetComponent(out toggle);
            }
        }

        private void Awake()
        {
            bool parseSuccessful = true;
            try
            {
                type = System.Type.GetType(target);
            } catch (System.Exception e)
            {
                Debug.LogError($"Type parsing failed with the following Exception:\n{e.Message}", gameObject);
                parseSuccessful = false;
            }

            if (type == null)
            {
                Debug.LogError($"Type parsing yielded NULL", gameObject);
                parseSuccessful = false;
            }

            if (!parseSuccessful)
            {
                Destroy(this);
                return;
            }
        }

        private void OnEnable()
        {
            if (toggle != null)
            {
                toggle.onValueChanged.AddListener(SetComponent);

                toggle.Trigger();
            }
        }

        private void OnDisable()
        {
            if (toggle != null)
            {
                toggle.onValueChanged.RemoveListener(SetComponent);
            }
        }

        void SetComponent(bool state)
        {
            var all = FindObjectsByType(type, FindObjectsInactive.Include, FindObjectsSortMode.None);
            if (all != null)
            {
                foreach (var comp in all)
                {
                    var m = comp as MonoBehaviour;
                    if (m != null)
                    {
                        m.enabled = state;
                    }
                }
            }
        }

        [Button]
        void TestTypeParsing()
        {
            bool parseSuccessful = true;
            System.Type result = null;
            try
            {
                result = System.Type.GetType(target);
            }
            catch (System.Exception e)
            {
                Debug.LogError($"Type parsing failed with the following Exception:\n{e.Message}", gameObject);
                parseSuccessful = false;
            }

            if (result == null)
            {
                Debug.LogError($"Type parsing yielded NULL", gameObject);
                parseSuccessful = false;
            }

            if (parseSuccessful)
            {
                Debug.LogWarning($"Type parsing succeeded, yielding {result}");
            }
        }

        [Button]
        void Toggle()
        {
            if (toggle != null)
            {
                toggle.isOn = !toggle.isOn;
            }
        }
    }
}
