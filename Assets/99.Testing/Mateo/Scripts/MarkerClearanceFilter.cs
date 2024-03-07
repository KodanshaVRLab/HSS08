using Oculus.Interaction;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    public class MarkerClearanceFilter : MonoBehaviour, IGameObjectFilter
    {
        public LayerMask layerMask;
        public float clearanceRadius = 0.5f;
        [SerializeField] RayInteractor interactor;

        [SerializeField] bool debugInEditMode = false;

        private Collider[] overlaps;

        private void OnValidate()
        {
            if (interactor == null)
            {
                TryGetComponent(out interactor);
            }
        }

        public bool Filter(GameObject gameObject)
        {
            if (interactor != null)
            {
                var hit = interactor.CollisionInfo;
                Debug.LogWarning("fucking stupid");

                if (hit.HasValue)
                {
                    var val = hit.Value;

                    Vector3 point = val.Point;
                    Vector3 normal = val.Normal;

                    Vector3 center = point + normal * (clearanceRadius + 0.001f);

                    return CheckClearance(center);//Physics.OverlapSphereNonAlloc(center, clearanceRadius, overlaps) == 0;
                }
            }
            Debug.LogWarning($"peepee {gameObject.name}");
            return false;
        }

        bool CheckClearance(Vector3 center)
        {
            //Debug.LogWarning($"Clearance Check Happening at {center}");
            // lmfao non-alloc version LITERALLY does not work
            overlaps = Physics.OverlapSphere(center, clearanceRadius, layerMask, QueryTriggerInteraction.Ignore);
            Debug.LogWarning("poopoo");

            return overlaps == null || overlaps.Length == 0;
        }

        private void OnDrawGizmosSelected()
        {
            if (debugInEditMode)
            {
                //var o = Physics.OverlapSphere(transform.position, clearanceRadius);
                ////Debug.Log(o.Length);

                //Physics.OverlapSphereNonAlloc(transform.position, clearanceRadius, overlaps);
                //Debug.Log($"{o.Length} vs {overlaps.Length}");

                ////int n = CheckClearance(transform.position);
                ////Debug.Log(overlaps.Length);
                //RaycastHit hit;
                //bool yay = Physics.SphereCast(transform.position, clearanceRadius, transform.forward, out hit, 0.000f); //Physics.Raycast(transform.position, transform.forward, out hit);

                bool yay = CheckClearance(transform.position);
                float n = yay ? 0f : 1f;
                    //Physics.SphereCast(transform.position, clearanceRadius, Vector3.one, out hit, 0f) ? 0 : 1;
                //Debug.Log(hit.point);

                var c = Color.Lerp(Color.green, Color.red, (float)n);
                c.a = 0.5f;
                Gizmos.color = c;
                Gizmos.DrawSphere(transform.position, clearanceRadius);
            }
        }
    }
}
