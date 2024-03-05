using Microsoft.SqlServer.Server;
using Oculus.Interaction;
using Oculus.Interaction.HandGrab;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UIElements;
using UnityEngine.XR.Interaction.Toolkit.AffordanceSystem.Receiver.Primitives;

namespace KVRL.HSS08.Testing
{
    public class MarkerSnapToSurface : Repositionable
    {
        [SerializeField] Rigidbody rb;
        [SerializeField] float surfaceBias = 0.3f;
        [SerializeField] Transform surfaceMarker = null;
        [SerializeField, Tooltip("Layer mask for the reticle placement raycast.")] LayerMask layerMask;

        [Tooltip("Layer mask for the margin collision detection.")] public LayerMask collisionLayerMask;
        [Min(0f)] public float collisionMargin = 0.5f;

        public enum SnapMode
        {
            RaycastRaw,
            RaycastClosest
        }

        [SerializeField] SnapMode snapMode = SnapMode.RaycastRaw;

        [SerializeField] bool debugVerbose = false;

        private Vector3 cachedMarkerPos;
        private Quaternion cachedMarkerRot;
        private float cachedMarkerDistance = 0;

        private bool snapping = false;
        private bool validFound = true;
        private Vector3 snapPoint = Vector3.zero;
        private Vector3 snapNormal = Vector3.zero;
        private Vector3 lastValidPoint = Vector3.zero;
        private Vector3 lastValidNormal = Vector3.zero;

        private List<Plane> collisionPlanes = new List<Plane>();

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

        public bool testShikiri = false;
        /// <summary>
        /// TODO Remove
        /// add to the list of shikiris Markers upon creation
        /// </summary>
        private void Start()
        {
            if(testShikiri)
            ShikiriAnimationController.Instance.addMarker(this);
        }
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
            CacheSurfaceMarkerTransform();
        }

        // Update is called once per frame
        void Update()
        {
            if (snapping)
            {
                (snapPoint, snapNormal) = AdjustMarkerReticle(snapPoint, snapNormal, out bool error);
                validFound = !error;
            }
        }

        public void InteractionStarted()
        {
            //Debug.LogWarning("SNAPPLE");
            snapping = true;
        }

        public void InteractionEnded()
        {
            //Debug.LogWarning($"SNAPPN'T : {snapPoint}");
            //SnapToPoint(snapPoint);
            if (validFound)
            {
                StartCoroutine(DelayedSnap(snapPoint, snapNormal, 2));
            } else
            {
                StartCoroutine(DelayedSnap(lastValidPoint, lastValidNormal, 2));
            }
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
            }
            else if (args.PreviousState == InteractableState.Select)
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

        (Vector3, Vector3) AdjustMarkerReticle(Vector3 lastPoint, Vector3 lastNormal, out bool error)
        {
            (Vector3, Vector3) result = (lastPoint, lastNormal);
            error = false;

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
                    result = (lastValidPoint, lastValidNormal);
                    error = true;
                    Debug.LogError($"Ran into an issue when applying margins!", gameObject);
                }
            }

            if (surfaceMarker != null)
            {
                float idealOffset = 0.1f; // surfaceBias - cachedMarkerDistance;
                //Vector3 surfaceNormal = (transform.position - result).normalized; 

                surfaceMarker.position = result.Item1 + result.Item2 * idealOffset;
                surfaceMarker.LookAt(result.Item1, Vector3.up);
                surfaceMarker.gameObject.SetActive(!error);
            }

            return result;
        }

        public override bool RepositionCheck((Vector3, Vector3) posNorm)
        {
            (Vector3 p, Vector3 n) = AdjustMarkerReticle(posNorm.Item1, posNorm.Item2, out bool error);
            if (error)
            {
                return false;
            }


            SnapToPoint(p, n);
            return true;
        }

        List<Plane> FilterOverlaps(Collider[] raw, Vector3 pos, Vector3 norm, List<Plane> filtered)
        {
            filtered.Clear();

            foreach (Plane p in OverlapPlanes(pos, norm, raw))
            {
                filtered.Add(p); // Should only add planes that match a non-Mesh Collider, and not be the snap surface itself
            }

            return filtered;
        }

        bool ApplyMargins(ref Vector3 position, Vector3 normal)
        {
            var overlaps = Physics.OverlapSphere(position, collisionMargin, collisionLayerMask);

            // Prefilter initial collision planes to weed out the surface plane and any incompatible colliders
            FilterOverlaps(overlaps, position, normal, collisionPlanes);

            if (collisionPlanes != null)
            {
                Vector3 delta = Vector3.zero;
                Vector3 corrected = position;

                if (debugVerbose)
                {
                    Debug.Log($"Overlap Count: {collisionPlanes.Count}");
                }

                int order = Mathf.Clamp(collisionPlanes.Count, 0, 3);
                switch (order)
                {
                    // Case 0 should never really happen, but in either case this should mean we are only touching the plane we are snapping to
                    case 0:
                        return true;
                    // Case 1 indicates that there is a single extra collision. In this case, a simple push may fix the intersection.
                    // However, some border cases might push the target into a different wall, so we must do a second pass
                    case 1:
                        corrected = SolveSingle(position, normal, collisionPlanes);
                        break;

                    // Case 2 indicates that we are dealing with a wedge (snapping plane + two obstacles).
                    // Both obstacle planes should have an intersection we can solve for
                    case 2:
                        corrected = SolveDouble(position, normal, collisionPlanes);
                        break;

                    // Case 3 indicates 3 or more overlaps, which would most likely indicate there won't be any valid solution
                    case 3:
                        return false;
                }
                position = corrected;
            }

            return true;
        }

        Vector3 SolveSingle(Vector3 center, Vector3 normal, List<Plane> overlaps)
        {
            Plane surface = new Plane(normal, center);

            // Solve for single plane first
            Plane solution = overlaps[0]; // OverlapPlanes(center, normal, overlaps).First<Plane>();

            // Naive Closest Point on Plane solution won't stay on surface plane of the wall isn't perpendicular
            // Instead, we want to first project the solution plane normal onto the surface plane
            // And then use that to intersect a ray
            Vector3 deltaDir = Vector3.ProjectOnPlane(solution.normal, surface.normal).normalized;

            Vector3 candidate;
            // Intersection exists: use raycast data
            if (solution.Raycast(new Ray(center, deltaDir), out float dist))
            {
                //Debug.Log(dist);
                candidate = center + deltaDir * dist;
            } else // No intersection, default to closest point (perpendicular)
            {
                candidate = solution.ClosestPointOnPlane(center);
            }

            // Do a secondary test to ensure we didn't wedge oursleves into a corner
            var secondary = Physics.OverlapSphere(candidate, collisionMargin, collisionLayerMask);
            // Filter again
            FilterOverlaps(secondary, candidate, normal, collisionPlanes);

            // An overlap now means the real solution rerquires both the inital wall, and the new collision to find the wedge solution
            if (collisionPlanes != null && collisionPlanes.Count > 0) // "First" overlap should be our surface plane
            {
                Plane nextSolution = collisionPlanes[0];
                candidate = SolveWedge(candidate, surface, solution, nextSolution);
            }

            return candidate;
        }

        Vector3 SolveDouble(Vector3 center, Vector3 normal, List<Plane> filtered)
        {
            Plane surface = new Plane(normal, center);
            //var filtered = OverlapPlanes(center, normal, overlaps).GetEnumerator();
            //filtered.MoveNext();
            Plane plane0 = filtered[0]; //.Current;
            //filtered.MoveNext();
            Plane plane1 = filtered[1]; //.Current;

            return SolveWedge(center, surface, plane0, plane1);
        }

        Vector3 SolveWedge(Vector3 center, Plane surface, Plane plane0, Plane plane1)
        {
            //Debug.Log($"surf {surface}\np0 {plane0}\np1 {plane1}");

            // Find point on each plane
            Vector3 p0 = plane0.ClosestPointOnPlane(center);
            Vector3 p1 = plane1.ClosestPointOnPlane(center);

            // Raw delta between points. This should give us a general "correction" direction to work with
            Vector3 delta = p1 - p0;
            // Project delta on plane0. This might not lie within plane1 if plane0 and plane1 are not perpendicular, so we need to solve properly
            delta = Vector3.ProjectOnPlane(delta, plane0.normal).normalized;

            // Intersect p1. This should be our first point on the intersection line
            Vector3 o = plane1.ClosestPointOnPlane(p0); // default to perpendicular in case the raycast misses
            if (plane1.Raycast(new Ray(p0, delta), out float dist))
            {
                o = p0 + delta * dist;
            }

            // Line direction is defined by crossing both plane normals
            Vector3 l = Vector3.Cross(plane0.normal, plane1.normal).normalized;

            // Raycast intersect this line with the surface plane and we are done
            surface.Raycast(new Ray(o, l), out float lineDist);

            return o + l * lineDist;
        }

        IEnumerable<Plane> OverlapPlanes(Vector3 position, Vector3 normal, Collider[] overlaps)
        {
            //foreach (var overlap in overlaps)
            //{
            //    Vector3 wallPoint = overlap.ClosestPoint(position);
            //    float d = Vector3.Distance(wallPoint, position);
            //    Debug.Log(d);
            //}

            int count = 0;
            foreach (var overlap in overlaps)
            {
                // Skip MeshColliders since they error due to them not being compatible with Collider.ClosestPoint. Planes should use box colliders anyways.
                if (overlap is MeshCollider)
                {
                    continue;
                }

                Vector3 wallPoint = overlap.ClosestPoint(position);
                float d = Vector3.Distance(wallPoint, position);
                Vector3 planeNormal = position - wallPoint;
                planeNormal.Normalize();

                //Debug.Log($"clsest: {wallPoint}");

                // Skip if distance is basically zero because that is the surface we are trying to snap to
                if (d <= 0.001f || planeNormal == normal)
                {
                    //Debug.Log($"Skip at element {count}/{overlaps.Length}");
                    continue;
                }

                Vector3 planePoint = wallPoint + planeNormal * (collisionMargin + 0.001f);

                Plane plane = new Plane(planeNormal, planePoint);

                //Debug.LogWarning(plane);

                yield return plane;
                ++count;
            }
        }

        /// <summary>
        /// Obsolete
        /// </summary>
        /// <param name="startPos"></param>
        /// <param name="targetTransform"></param>
        /// <param name="raycastDistance"></param>
        /// <returns></returns>
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
        /// <summary>
        /// Computes which marker's surface the snap point is by doing a raycast. .
        /// </summary>
        /// <returns>The surface snap point, transform.</returns>

        public Transform GetSnapTransform()
        {
            RaycastHit hit;
            if (Physics.Raycast(transform.position, transform.forward, out hit, 3f, layerMask))
            {
                return hit.transform;
            }
            return null;
        }
        /// <summary>
        /// Computes the marker's snap point surface normal by doing a raycast. If you only need the last snap point the marker snapped to, use LastSnapPoint.
        /// </summary>
        /// <returns>The surface hit Normal , or the marker's normal if the raycast fails.</returns>

        public Vector3 GetSnapNormal()
        {
            RaycastHit hit;
            if (Physics.Raycast(transform.position, transform.forward, out hit, 3f, layerMask))
            {
                return hit.normal;
            }
            return transform.forward;
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

            if (surfaceMarker != null)
            {
                surfaceMarker.gameObject.SetActive(true);
            }

            lastValidPoint = point;
            lastValidNormal = normal;
        }

        void RestoreSurfaceMarkerTransform()
        {
            if (surfaceMarker != null)
            {
                surfaceMarker.localPosition = cachedMarkerPos;
                surfaceMarker.localRotation = cachedMarkerRot;
            }
        }

        [Sirenix.OdinInspector.Button]
        void TryBindPlacementCallback()
        {
            var placer = GetComponentInParent<ObjectPoolPlacer>();
            if (placer != null)
            {
                
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
