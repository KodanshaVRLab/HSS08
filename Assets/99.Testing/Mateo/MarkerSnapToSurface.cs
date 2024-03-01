using Oculus.Interaction;
using Oculus.Interaction.HandGrab;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    public class MarkerSnapToSurface : Repositionable
    {
        [SerializeField] Rigidbody rb;
        [SerializeField] float surfaceBias = 0.3f;
        [SerializeField] Transform surfaceMarker = null;
        [SerializeField] LayerMask layerMask;

        public LayerMask collisionLayerMask;
        [Min(0f)] public float collisionMargin = 0.5f;

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

        /// <summary>
        /// Returns the last surface point the marker snapped to. Note that this is NOT the marker's own position.
        /// </summary>
        public Vector3 LastSnapPoint
        {
            get { return snapPoint; }
        }

        /// <summary>
        /// Returns the normal of the last surface point the marker snapped to.
        /// </summary>
        public Vector3 LastSnapNormal
        {
            get { return snapNormal; }
        }

        /// <summary>
        /// Returns the current marker position. Note that this matches the marker's transform, not the surface snap point.
        /// </summary>
        public Vector3 LastPosition
        {
            get { return transform.position; }
        }


        private static MarkerSnapToSurface[] AllMarkers;
        /// <summary>
        /// Returns a list of all active marker snappers in the scene
        /// </summary>
        /// <param name="updateList">If false, the last cached list will be returned again instead of querying the current state of the scene</param>
        /// <returns>The marker snapper list</returns>
        public static MarkerSnapToSurface[] FetchAllMarkers(bool updateList = false)
        {
            if (updateList || AllMarkers == null)
            {
                AllMarkers = FindObjectsOfType<MarkerSnapToSurface>();
            }

            return AllMarkers;
        }

        /// <summary>
        /// Returns a list of the snap points of all active marker snappers in the scene
        /// </summary>
        /// <param name="updateList">If false, the last cached marker list will be used again instead of querying the current state of the scene</param>
        /// <returns>The marker snap point list</returns>
        public static Vector3[] FetchAllSnapPoints(bool updateMarkerList = false)
        {
            var markers = FetchAllMarkers(updateMarkerList);
            Vector3[] points = new Vector3[markers.Length];

            for (int i = 0; i < markers.Length; ++i)
            {
                points[i] = markers[i].snapPoint;
            }

            return points;
        }

        /// <summary>
        /// Returns a list of the snap normals of all active marker snappers in the scene
        /// </summary>
        /// <param name="updateList">If false, the last cached marker list will be used again instead of querying the current state of the scene</param>
        /// <returns>The marker snap normal list</returns>
        public static Vector3[] FetchAllSnapNormals(bool updateMarkerList = false)
        {
            var markers = FetchAllMarkers(updateMarkerList);
            Vector3[] normals = new Vector3[markers.Length];

            for (int i = 0; i < markers.Length; ++i)
            {
                normals[i] = markers[i].snapNormal;
            }

            return normals;
        }

        /// <summary>
        /// Returns a list of the snap points and normals of all active marker snappers in the scene
        /// </summary>
        /// <param name="updateList">If false, the last cached marker list will be used again instead of querying the current state of the scene</param>
        /// <returns>The marker snap point and normal list. Tuples represent (point, normal)</returns>
        public static (Vector3, Vector3)[] FetchAllSnapPointsAndNormals(bool updateMarkerList = false)
        {
            var markers = FetchAllMarkers(updateMarkerList);
            (Vector3, Vector3)[] result = new (Vector3, Vector3)[markers.Length];

            for (int i = 0; i < markers.Length; ++i)
            {
                result[i] = (markers[i].snapPoint, markers[i].snapNormal);
            }

            return result;
        }


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

            if (collisionMargin > 0f)
            {
                if (!ApplyMargins(ref result.Item1, result.Item2))
                {
                    Debug.LogError($"Ran into an issue when applying margins!", gameObject);
                }
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

        public override void Reposition((Vector3, Vector3) posNorm)
        {
            (Vector3 p, Vector3 n) = AdjustMarkerReticle(posNorm.Item1, posNorm.Item2);

            SnapToPoint(p, n);
        }

        bool ApplyMargins(ref Vector3 position, Vector3 normal)
        {
            var overlaps = Physics.OverlapSphere(position, collisionMargin, collisionLayerMask);

            if (overlaps != null)
            {
                Vector3 delta = Vector3.zero;
                Vector3 corrected = position;

                int order = Mathf.Clamp(overlaps.Length, 0, 4);
                switch (order)
                {
                    // Case 0 should never really happen, but in either case this should mean we are only touching the plane we are snapping to (or aren't snapping to anything)
                    case 0:
                    case 1:
                        return true;
                    // Case 2 indicates that there is a single extra collision. so this is as simple as pushing away from it
                    case 2:
                        foreach (var overlap in overlaps)
                        {
                            Vector3 p = overlap.ClosestPoint(position);
                            Vector3 dn = position - p;

                            // Skip if distance is basically zero because that is the surface we are trying to snap to
                            if (dn.sqrMagnitude < 0.0001f)
                            {
                                continue;
                            }

                            float dist = dn.magnitude; // Should be less than the margin distance by definition
                            Vector3 tangent = Vector3.Cross(Vector3.Cross(normal, dn.normalized), normal).normalized; // Tangent to the snap plane and away from the collision point

                            float angleCorrect = 1f / Vector3.Dot(dn.normalized, tangent); // Enlarge offset based on angle difference. Otherwise, the push would only work on 90deg corners, undershooting acute corners and obtuse ones.
                            delta += tangent * (collisionMargin - dist) * angleCorrect; // Offset target point based by a distance such that collisionMargin is reached

                            // We should be able to end early since only one obstacle needs to be adjusted
                            break;
                        }

                        corrected = position + delta;
                        break;
                    // Case 3 indicates that we are dealing with a wedge (snapping plane + two obstacles)
                    case 3:
                        int offsetCount = 0;
                        Vector3[] offsets = new Vector3[2];

                        // Same idea as Case 2 except we gather two offsets
                        foreach (var overlap in overlaps)
                        {
                            Vector3 p = overlap.ClosestPoint(position);
                            Vector3 dn = position - p;

                            // Skip if distance is basically zero because that is the surface we are trying to snap to
                            if (dn.sqrMagnitude < 0.0001f)
                            {
                                continue;
                            }

                            float dist = dn.magnitude; // Should be less than the margin distance by definition
                            Vector3 tangent = Vector3.Cross(Vector3.Cross(normal, dn.normalized), normal).normalized; // Tangent to the snap plane and away from the collision point

                            float angleCorrect = 1f; // / Vector3.Dot(dn.normalized, tangent); // Enlarge offset based on angle difference. Otherwise, the push would only work on 90deg corners, undershooting acute corners and obtuse ones.
                            offsets[offsetCount] = tangent * (collisionMargin - dist) * angleCorrect; // Offset target point based by a distance such that collisionMargin is reached

                            ++offsetCount;
                        }

                        // Offsets in hand, we compute the proper delta
                        // First, the "unit" delta produced from adding both offsets. This should be correct if the wedge angle is 90 deg
                        Vector3 unitDelta = offsets[0] + offsets[1];

                        // Second, the correction factor. This needs to be 1 at right angles, steer towards infinity at acute angles, and towards 0 at obtuse angles
                        // TODO
                        // Finally, output the correct offset
                        corrected = position + unitDelta;
                        break;
                    // Case 4 indicates 3 or more overlaps, which would most likely indicate there won't be any valid solution
                    case 4:
                        return false;
                }

                // Repeat for all overlapping colliders to accumulate offsets
                // Should work in everyday corners but might be wonky in super tight spots where the overall available space is smaller than the margin
                //foreach (var overlap in overlaps)
                //{
                //    Vector3 p = overlap.ClosestPoint(position);
                //    Vector3 dn = position - p;

                //    // Skip if distance is basically zero because that is the surface we are trying to snap to
                //    if (dn.sqrMagnitude < 0.0001f)
                //    {
                //        continue;
                //    }

                //    float dist = dn.magnitude; // Should be less than the margin distance by definition
                //    Vector3 tangent = Vector3.Cross(Vector3.Cross(normal, dn.normalized), normal).normalized; // Tangent to the snap plane and away from the collision point
                    

                //    if (delta.sqrMagnitude > 0)
                //    {

                //    }

                //    float angleCorrect = 1f; // / Vector3.Dot(dn.normalized, tangent); // Enlarge offset based on angle difference. Otherwise, the push would only work on 90deg corners, undershooting acute corners and obtuse ones.
                //    corrected += tangent * (collisionMargin - dist) * angleCorrect; // Offset target point based by a distance such that collisionMargin is reached
                //}

                // Apply offsets
                //position += delta;
                position = corrected;
            }

            return true;
        }

       
       public Vector3 CheckCollisionAndGetHitPoint(Vector3 startPos, Transform targetTransform, float raycastDistance = 10f)
       {
            RaycastHit hit;

            // Raycast Up
            if (Physics.Raycast(startPos, transform.up, out hit, raycastDistance))
            {
                if (hit.transform == targetTransform)
                {
                    return hit.point;
                }
            }

            // Raycast Down (-Up)
            if (Physics.Raycast(startPos, -transform.up, out hit, raycastDistance))
            {
                if (hit.transform == targetTransform)
                {
                    return hit.point;
                }
            }

            // Raycast Right
            if (Physics.Raycast(startPos, transform.right, out hit, raycastDistance))
            {
                if (hit.transform == targetTransform)
                {
                    return hit.point;
                }
            }

            // Raycast Left (-Right)
            if (Physics.Raycast(startPos, -transform.right, out hit, raycastDistance))
            {
                if (hit.transform == targetTransform)
                {
                    return hit.point;
                }
            }

            // If no collision found, return null
            return Vector3.zero;
        }
        
        /// <summary>
        /// Computes the marker's snap point on a surface by doing a raycast. If you only need the last snap point the marker snapped to, use LastSnapPoint.
        /// </summary>
        /// <returns>The surface snap point, or the marker's position if the raycast fails.</returns>
        public Vector3 GetSnapPoint()
        {
            RaycastHit hit;
            if (Physics.Raycast(transform.position, transform.forward, out hit, 3f, layerMask))
            {
              return hit.point;
            }
            return transform.position;
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

        private void OnDrawGizmosSelected()
        {
            RaycastHit hit;
            if (Physics.Raycast(transform.position, transform.forward, out hit, 3f, collisionLayerMask))
            {
                Vector3 p0 = hit.point;
                Vector3 n = hit.normal;

                Gizmos.color = Color.yellow;
                Gizmos.DrawSphere(p0, 0.05f);

                Vector3 p1 = p0;
                ApplyMargins(ref p1, n);

                Gizmos.color = Color.white;
                Gizmos.DrawSphere(p1, 0.05f);

                bool obstructed = p0 != p1;
                Gizmos.color = obstructed ? Color.red : Color.green;
                Gizmos.DrawWireSphere(p0, collisionMargin);
            }
        }
    }
}
