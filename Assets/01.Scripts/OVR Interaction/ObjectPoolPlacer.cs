using Oculus.Interaction;
using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace KVRL.HSS08.Testing
{
    public class ObjectPoolPlacer : PointerInteractionSystem
    {
        public GameObject templatePrefab;
        [SerializeField] float surfaceBias = 0.1f;
        [SerializeField] Vector2 sizeRange = Vector2.one;
        [SerializeField, Range(0, 180)] float rotationRange = 0f;
        [SerializeField] int poolCapacity = 50;
        [SerializeField, ReadOnly] List<GameObject> pool = new List<GameObject>();
        [SerializeField] bool oneAtATime = false;
        private int poolIndex = 0;



        [Button]
        protected GameObject GetNext()
        {
            if (oneAtATime)
            {
                int pIndex = (poolIndex + poolCapacity - 1) % poolCapacity;
                var prev = pool[pIndex];
                prev.SetActive(false);
                Debug.Log("Deactivating old object", prev);
            }

            var next = pool[poolIndex++];
            poolIndex %= poolCapacity;
            next.SetActive(true);
            return next;
        }

        public override void TriggerInteraction(PointerEvent evt)
        {
            PlaceObject(evt);
        }

        protected (GameObject, T) GetNextComponent<T>() where T : Component {
            var go = GetNext();
            T comp = go.GetComponent<T>();

            return (go, comp);
        }

        public GameObject PlaceObject(PointerEvent evt)
        {
            if (!FilterEvent(evt.Data))
            {
                return null;
            }

            return PlaceObject(evt.Pose.position, -evt.Pose.forward);
        }

        public GameObject PlaceObject(Vector3 positionWR, Vector3 normalWR)
        {
            var go = GetNext();
            Vector3 norm = normalWR;
            Vector3 pos = positionWR + norm * surfaceBias;

            PositionObject(go, pos, norm);

            return go;
        }

        protected override bool FilterEvent(object data)
        {
            if (data is InteractionData iData)
            {
                return (iData.interactions & interactionFilter) != 0;
            }

            return defaultInteractionFilter;
        }

        protected virtual void PositionObject(GameObject go, Vector3 pos, Vector3 norm)
        {
            Transform t = go.transform;

            float size = Random.Range(sizeRange.x, sizeRange.y);
            float angle = Random.Range(-rotationRange, rotationRange);

            t.position = pos;
            t.LookAt(pos - norm);
            Quaternion rot = Quaternion.AngleAxis(angle, t.forward);
            t.rotation = rot * t.rotation;
            t.localScale = Vector3.one * size;
        }

        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {

        }

        #region Editor Helpers

        [Button]
        void PopulatePool()
        {
            if (Application.isPlaying)
            {
                return;
            }

            pool.Clear();
            for (int i = transform.childCount - 1; i >= 0; --i)
            {
                DestroyImmediate(transform.GetChild(i).gameObject);
            }

            for (int i = 0; i < poolCapacity; i++)
            {
                GameObject g = Instantiate(templatePrefab, transform, false);
                g.name = $"Pool Instance [{templatePrefab.name}]";
                g.SetActive(false);

                PopulatePoolAdditional(g);

                pool.Add(g);
            }

        }

        protected virtual void PopulatePoolAdditional(GameObject instance)
        {

        }

        #endregion
    }
}
