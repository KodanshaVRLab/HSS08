using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    public class StickToRoomWall : MonoBehaviour
    {
        public float searchRadius = 2f;
        public LayerMask layerMask;

        bool stuck = false;

        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {
            if (!stuck)
            {
                EvaluateSurfaces();
            }
        }

        void EvaluateSurfaces()
        {
            var surfaces = Physics.OverlapSphere(transform.position, searchRadius, layerMask);

            if (surfaces != null)
            {
                List<Vector3> posCandidates = new List<Vector3>();
                List<Quaternion> rotCandidates = new List<Quaternion>();

                foreach (var surface in surfaces)
                {
                    OVRSceneAnchor anchor;

                    if (surface.TryGetComponent(out anchor) || surface.transform.parent.TryGetComponent(out anchor))
                    {
                        OVRAnchor anchorLow = anchor.Anchor;
                        OVRSemanticLabels semantic;
                        if (anchorLow.TryGetComponent(out semantic))
                        {
                            if (!semantic.Labels.Contains("WALL_FACE"))
                            {
                                continue;
                            }

                            if (!anchorLow.TryGetComponent(out OVRLocatable locator))
                            {
                                continue;
                            }

                            if (!locator.TryGetSceneAnchorPose(out var pose))
                            {
                                continue;
                            }

                            Vector3 pos = pose.ComputeWorldPosition(Camera.main).GetValueOrDefault();
                            Quaternion rot = pose.ComputeWorldRotation(Camera.main).GetValueOrDefault();

                            posCandidates.Add(pos);
                            rotCandidates.Add(rot);

                            //transform.SetPositionAndRotation(pos, rot);
                            //stuck = true;

                            //return;
                        }
                    }
                }

                int bestPick = 0;
                float minDistance = float.MaxValue;
                Vector3 here = transform.position;

                for (int i = 0; i < posCandidates.Count; i++)
                {
                    float d = Vector3.Distance(here, posCandidates[i]);

                    if (d < minDistance)
                    {
                        minDistance = d;
                        bestPick = i;
                    }
                }

                transform.SetPositionAndRotation(posCandidates[bestPick], rotCandidates[bestPick]);
                stuck = true;
            }
        }
    }
}
