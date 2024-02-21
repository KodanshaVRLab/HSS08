using Oculus.Interaction;
using Oculus.Interaction.HandGrab;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    public class MarkerSnapToSurface : MonoBehaviour
    {
        [SerializeField] Rigidbody rb;
        [SerializeField] float surfaceBias = 0.3f;
        [SerializeField] Transform surfaceMarker = null;
        [SerializeField] LayerMask layerMask;

        public enum SnapMode
        {
            RaycastRaw,
            RaycastClosest
        }

        [SerializeField] SnapMode snapMode = SnapMode.RaycastRaw;

        private Vector3 cachedMarkerPos;
        private Quaternion cachedMarkerRot;
        private float cachedMarkerDistance = 0;

        private bool snapping = false;
        private Vector3 snapPoint = Vector3.zero;
        private Vector3 snapNormal = Vector3.zero;
        private Collider[] snapColliders;


        private void OnValidate()
        {
            if (rb == null)
            {
                rb = GetComponent<Rigidbody>();
            }
        }

        private void Awake()
        {
            //DistanceGrabInteractable dum;
            //if (TryGetComponent(out dum))
            //{
            //    dum.WhenStateChanged += StateChange;
            //}
        }

        void StateChange(InteractableStateChangeArgs args)
        {
            Debug.Log("STATE CHANGE MF");
        }

        private void OnEnable()
        {
            BindCallbacks();
        }

        // Update is called once per frame
        void Update()
        {
            if (snapping)
            {
                (snapPoint, snapNormal) = AdjustMarkerReticle(snapPoint, snapNormal);
            }
        }

        public void InteractionStarted()
        {
            Debug.LogWarning("SNAPPLE");
            CacheSurfaceMarkerTransform();
            snapping = true;
        }

        public void InteractionEnded()
        {
            Debug.LogWarning($"SNAPPN'T : {snapPoint}");
            //SnapToPoint(snapPoint);
            StartCoroutine(DelayedSnap(snapPoint, snapNormal, 2));
            RestoreSurfaceMarkerTransform();
            snapping = false;
        }

        void BindCallbacks()
        {
            DistanceGrabInteractable controller;
            DistanceHandGrabInteractable hand;

            if (TryGetComponent(out controller))
            {
                controller.WhenStateChanged += InteractionCallback;
            }

            if (TryGetComponent(out hand))
            {
                hand.WhenStateChanged += InteractionCallback;
            }
        }

        void UnbindCallbacks()
        {
            DistanceGrabInteractable controller;
            DistanceHandGrabInteractable hand;

            if (TryGetComponent(out controller))
            {
                controller.WhenStateChanged -= InteractionCallback;
            }

            if (TryGetComponent(out hand))
            {
                hand.WhenStateChanged -= InteractionCallback;
            }
        }

        void InteractionCallback(InteractableStateChangeArgs args)
        {
            if (args.NewState == InteractableState.Select)
            {
                InteractionStarted();
            } else if (args.PreviousState == InteractableState.Select)
            {
                InteractionEnded();
            }
        }

        void CacheSurfaceMarkerTransform()
        {
            if (surfaceMarker != null)
            {
                cachedMarkerPos = surfaceMarker.localPosition;
                cachedMarkerRot = surfaceMarker.localRotation;
                cachedMarkerDistance = Vector3.Distance(transform.position, cachedMarkerPos);
            }
        }

        (Vector3, Vector3) AdjustMarkerReticle(Vector3 lastPoint, Vector3 lastNormal)
        {
            (Vector3, Vector3) result = (lastPoint, lastNormal);

            // This trash refuses to work
            //int hits = Physics.OverlapSphereNonAlloc(transform.position, 15f, snapColliders);//, layerMask, QueryTriggerInteraction.Ignore);
            //Debug.LogWarning(hits);

            //// Check for nearby walls
            //if (hits > 0)
            //{
            //    Vector3 closest = Vector3.zero;
            //    Vector3 reference = transform.position;
            //    float distance = float.MaxValue;
            //    for (int i = 0; i < snapColliders.Length; i++)
            //    {
            //        Collider test = snapColliders[i];
            //        Vector3 testPos = test.transform.position;
            //        Quaternion testRot = test.transform.rotation;

            //        Vector3 candidate = Physics.ClosestPoint(reference, snapColliders[0], testPos, testRot);
            //        float d = Vector3.Distance(candidate, reference);
                    
            //        if (d < distance)
            //        {
            //            closest = candidate;
            //            distance = d;
            //        }
            //    }

            //    if (distance < float.MaxValue)
            //    {
            //        result = closest;
            //    }

            //    Debug.LogWarning(distance);
            //}

            // check but using Raycasts cause those should actually not be broken unity code
            RaycastHit hit;
            if (Physics.Raycast(transform.position, transform.forward, out hit, 3f, layerMask))
            {
                switch (snapMode)
                {
                    case SnapMode.RaycastRaw:
                        result.Item1 = hit.point;
                        result.Item2 = hit.normal;
                        break;
                        case SnapMode.RaycastClosest: 
                        result.Item1 = Physics.ClosestPoint(transform.position,
                            hit.collider,
                            hit.transform.position,
                            hit.transform.rotation);
                        result.Item2 = (transform.position - result.Item1).normalized; // By definition, the closest point needs to be orthogonal
                        break;
                }

                Debug.LogWarning(hit.collider.name);
            }

            if (surfaceMarker != null)
            {
                float idealOffset = 0.1f; // surfaceBias - cachedMarkerDistance;
                //Vector3 surfaceNormal = (transform.position - result).normalized; 

                surfaceMarker.position = result.Item1 + result.Item2 * idealOffset;
                surfaceMarker.LookAt(result.Item1, Vector3.up);
            }

            return result;
        }

        IEnumerator DelayedSnap(Vector3 point, Vector3 normal, int delay)
        {
            for (int i = 0; i < delay; i++)
            {
                yield return null;
            }

            SnapToPoint(point, normal);
        }

        void SnapToPoint(Vector3 point, Vector3 normal)
        {
            //Vector3 previous = transform.position; // Snapping from here to poitn should be parallel to the surface normal
            //Vector3 surfaceNormal = (previous - point).normalized;
            Vector3 target = point + normal * surfaceBias;

            Debug.LogWarning($"Snaping to point {target}");

            rb.position = target;
            transform.position = target;
            transform.LookAt(point, Vector3.up);
        }

        void RestoreSurfaceMarkerTransform()
        {
            if (surfaceMarker != null)
            {
                surfaceMarker.localPosition = cachedMarkerPos;
                surfaceMarker.localRotation = cachedMarkerRot;
            }
        }
    }
}
