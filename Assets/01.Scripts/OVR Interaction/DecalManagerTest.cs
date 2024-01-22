using Oculus.Interaction;
using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace KVRL.HSS08.Testing
{
    public class DecalManagerTest : MonoBehaviour
    {
        public GameObject decalTemplate;
        [SerializeField] float surfaceBias = 0.1f;
        [SerializeField] Vector2 sizeRange = Vector2.one;
        [SerializeField, Range(0, 180)] float rotationRange = 0f;
        [SerializeField] int poolCapacity = 50;
        [SerializeField, ReadOnly] List<DecalProjector> decalPool = new List<DecalProjector>();
        private int decalIndex = 0;

        DecalProjector GetNext()
        {
            var next = decalPool[decalIndex++];
            decalIndex %= poolCapacity;
            next.enabled = true;
            return next;
        }

        public void PlaceDecal(PointerEvent evt)
        {
            var decal = GetNext();
            Vector3 norm = evt.Pose.forward;
            Vector3 pos = evt.Pose.position + norm * surfaceBias;

            AdjustDecal(decal, pos, norm);
        }

        void AdjustDecal(DecalProjector decal, Vector3 pos, Vector3 norm)
        {
            float size = Random.Range(sizeRange.x, sizeRange.y);
            float angle = Random.Range(-rotationRange, rotationRange);

            decal.transform.position = pos;
            decal.transform.LookAt(pos - norm);
            Quaternion rot = Quaternion.AngleAxis(angle, decal.transform.forward);
            decal.transform.rotation = rot * decal.transform.rotation;

            // TODO: Why no work
            decal.size = new Vector3(size, size, 1);
        }

        #region Editor Helpers

        [Button]
        void PopulatePool()
        {
            if (Application.isPlaying)
            {
                return;
            }

            decalPool.Clear();
            for (int i = transform.childCount - 1; i >= 0; --i)
            {
                DestroyImmediate(transform.GetChild(i).gameObject);
            }

            for (int i  = 0; i < poolCapacity; i++)
            {
                GameObject g = Instantiate(decalTemplate, transform, false);
                g.name = $"Decal Instance [{decalTemplate.name}]";
                DecalProjector d = g.GetComponent<DecalProjector>();

                d.enabled = false;
                decalPool.Add(d);
            }

        }
        #endregion
    }
}
