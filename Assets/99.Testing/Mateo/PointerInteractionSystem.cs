using Oculus.Interaction;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

namespace KVRL.HSS08.Testing
{
    public abstract class PointerInteractionSystem : MonoBehaviour
    {
        [SerializeField] protected OVRManager ovr;
        [SerializeField] protected OVRPassthroughLayer passthrough;

        [SerializeField, Tooltip("Set as False if this system is triggered by a separate system instead of from the OVR interaction directly")] 
        protected bool isMainSystem = true;
        public bool IsMainSystem
        {
            get { return isMainSystem; }
        }

        public ValidInteractions interactionFilter = ValidInteractions.None;
        [SerializeField] protected bool defaultInteractionFilter = true;

        public PointerInteractionEvent OnInteraction = new PointerInteractionEvent();

        protected static PointerInteractionSystem _instance;
        public static PointerInteractionSystem Instance
        {
            get { return _instance; }
            protected set { _instance = value; }
        }

        protected virtual void OnValidate()
        {
            if (ovr == null)
            {
                ovr = FindObjectOfType<OVRManager>();
            }

            if (passthrough == null)
            {
                passthrough = FindObjectOfType<OVRPassthroughLayer>();
            }
        }

        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {

        }

        public abstract void TriggerInteraction(PointerEvent evt);

        protected abstract bool FilterEvent(object data);
    }

    [System.Serializable]
    public class PointerInteractionEvent : UnityEvent<PointerEvent> { }
}
