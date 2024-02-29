using AmplifyShaderEditor;
using Oculus.Interaction;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Animations.Rigging;

namespace KVRL.HSS08.Testing
{
    public class PointingIKWeightController : MonoBehaviour
    {
        [SerializeField] Rig rig;
        [SerializeField] Rig[] additionalRigs;
        [SerializeField] Transform characterReference;
        [SerializeField] Transform targetReference;
        public AnimationCurve forwardFalloffCurve = AnimationCurve.Linear(0f, 0f, 0.5f, 1f);

        [SerializeField] MultiAimConstraint[] constraints;
        public Vector2 distanceBlendRange = new Vector2(1f, 3f);
        public Vector2 weightMinMaxrange = new Vector2(0f, 0.5f);

        [SerializeField] Transform handReference;
        [SerializeField] MultiAimConstraint handCorrection;
        public Vector2 handDistanceBlendRange = new Vector2(0f, 0.1f);


        [SerializeField] bool keepGizmosAlways = false;

        bool IsValid => rig != null && characterReference != null && targetReference != null && handReference != null;


        private void OnValidate()
        {
            if (rig == null)
            {
                TryGetComponent(out rig);
            }
        }
        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {

            if (IsValid && constraints != null)
            {
                float rw = GetRigWeight(targetReference.position);
                rig.weight = rw;

                if (additionalRigs != null)
                {
                    foreach (var r in additionalRigs)
                    {
                        r.weight = rw;
                    }
                }

                float w = GetTorsoTwistWeight(GetDistanceToTarget(characterReference));

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

        float GetRigWeight(Vector3 point)
        {
            Vector3 fwd = characterReference.forward;
            Vector3 dir = (point - characterReference.position).normalized;

            float t = Vector3.Dot(fwd, dir);

            return forwardFalloffCurve.Evaluate(t);
        }

        float GetTorsoTwistWeight(float d)
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
                float a = GetRigWeight(targetReference.position);

                Color chara = Color.yellow;
                chara.a = a;
                Gizmos.color = chara;
                Gizmos.DrawSphere(characterReference.position, 0.05f);

                Color rangeMin = Color.black;
                rangeMin.a = a;
                Gizmos.color = rangeMin;
                Gizmos.DrawWireSphere(characterReference.position, distanceBlendRange.x);

                Color rangeMax = Color.white;
                rangeMax.a = a;
                Gizmos.color = rangeMax;
                Gizmos.DrawWireSphere(characterReference.position, distanceBlendRange.y);

                Gizmos.color = Color.Lerp(rangeMin, rangeMax, Mathf.InverseLerp(distanceBlendRange.x, distanceBlendRange.y, GetDistanceToTarget(characterReference)));
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
