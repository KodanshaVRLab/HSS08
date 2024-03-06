using KVRL.HSS08.Testing;
using Oculus.Interaction;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace KVRL.HSS08
{
    public class HideCursorOnHover : MonoBehaviour
    {
        [SerializeField] PointableUnityEventWrapper wrapper;
        [SerializeField] InteractionData interactionToBlock;
        HidableCursor[] cursors;

        private void OnValidate()
        {
            if (wrapper == null)
            {
                TryGetComponent(out wrapper);
            }
        }

        private void Awake()
        {
            cursors = FindObjectsByType<HidableCursor>(FindObjectsInactive.Include, FindObjectsSortMode.None);
        }

        // Start is called before the first frame update
        void Start()
        {
            BindHoverCallbacks();
        }

        // Update is called once per frame
        void Update()
        {

        }

        void BindHoverCallbacks()
        {
            if (wrapper != null)
            {
                wrapper.WhenHover.AddListener(HideCallback);
                wrapper.WhenUnhover.AddListener(UnhideCallback);
            }
        }

        bool FilterEvent(PointerEvent e)
        {
            InteractionData data = e.Data as InteractionData;
            // If an interaction is specified, block only the type we care about
            if (data != null)
            {
                return data == interactionToBlock;
            }

            // If no interaction is specified, do nothing
            return false;
        }

        void HideCallback(PointerEvent e)
        {
            if (cursors != null && FilterEvent(e))
            {
                foreach (var cursor in cursors)
                {
                    cursor.SetActive(false);
                }
            }
        }

        void UnhideCallback(PointerEvent e)
        {
            if (cursors != null && FilterEvent(e))
            {
                foreach (var cursor in cursors)
                {
                    cursor.SetActive(true);
                }
            }
        }
    }
}
