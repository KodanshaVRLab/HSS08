using AmplifyShaderEditor;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Animations.Rigging;

namespace KVRL.HSS08.Testing
{
    public class PointingIKWeightController : MonoBehaviour
    {
        [SerializeField] Transform characterReference;
        [SerializeField] Transform targetReference;

        [SerializeField] MultiAimConstraint[] constraints;
        public Vector2 distanceBlendRange = new Vector2(1f, 3f);
        public Vector2 weightMinMaxrange = new Vector2(0f, 0.5f);

        [SerializeField] Transform handReference;
        [SerializeField] MultiAimConstraint handCorrection;
        public Vector2 handDistanceBlendRange = new Vector2(0f, 0.1f);


        [SerializeField] bool keepGizmosAlways = false;

        bool IsValid => characterReference != null && targetReference != null && handReference != null;

        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {

            if (IsValid && constraints != null)
            {
                float w = GetWeight(GetDistanceToTarget(characterReference));

                foreach (var c in constraints)
                {
                    c.weight = w;
                }

                if (handCorrection != null)
                {
                    handCorrection.weight = GetHandWeight();
                }
            }
        }

        float GetWeight(float d)
        {
            return Mathf.Lerp(
                    weightMinMaxrange.x,
                    weightMinMaxrange.y,
                    Mathf.Clamp01(Mathf.InverseLerp(
                        distanceBlendRange.x,
                        distanceBlendRange.y,
                        d
                        ))
                    );
        }

        float Remap(Vector2 domain, Vector2 range, float t)
        {
            return Mathf.Lerp(
                range.x,
                range.y,
                Mathf.Clamp01(Mathf.InverseLerp(
                    domain.x,
                    domain.y,
                    t
                    ))
                );
        }

        float GetDistanceToTarget(Transform source)
        {
            if (!IsValid)
            {
                return 0f;
            }

            return Vector3.Distance(source.position, targetReference.position);
        }

        float GetHandWeight()
        {
            if (handReference == null)
            {
                return 0f;
            }

            return Remap(handDistanceBlendRange, new Vector2(0f, 1f), GetDistanceToTarget(handReference));
        }

        void DoGizmos()
        {
            if (IsValid)
            {
                Gizmos.color = Color.yellow;
                Gizmos.DrawSphere(characterReference.position, 0.05f);

                Gizmos.color = Color.black;
                Gizmos.DrawWireSphere(characterReference.position, distanceBlendRange.x);

                Gizmos.color = Color.white;
                Gizmos.DrawWireSphere(characterReference.position, distanceBlendRange.y);

                Gizmos.color = Color.Lerp(Color.black, Color.white, Mathf.InverseLerp(distanceBlendRange.x, distanceBlendRange.y, GetDistanceToTarget(characterReference)));
                Gizmos.DrawSphere(targetReference.position, 0.1f);
            }
        }

        private void OnDrawGizmos()
        {
            if (keepGizmosAlways)
            {
                DoGizmos();
            }
        }

        private void OnDrawGizmosSelected()
        {
            DoGizmos();
        }
    }
}
