using Oculus.Interaction;
using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Events;

#if UNITY_EDITOR
using UnityEditor;
#endif

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

        public enum PoolMode
        {
            Capped,
            AutoRecycle,
            OneAtATime
        }
        [SerializeField] PoolMode mode = PoolMode.AutoRecycle;

        public PositioningEvent onPositionObject = new PositioningEvent();


        private int poolIndex = 0;
        private bool capReached = false;


        [Button]
        protected GameObject GetNext()
        {
            // Skip if pool is capped and we already placed all items
            if (mode == PoolMode.Capped && capReached)
            {
                return null;
            }

            if (mode == PoolMode.OneAtATime)
            {
                int pIndex = (poolIndex + poolCapacity - 1) % poolCapacity;
                var prev = pool[pIndex];
                prev.SetActive(false);
                Debug.Log("Deactivating old object", prev);
            }

            var next = pool[poolIndex++];
            poolIndex %= poolCapacity;
            next.SetActive(true);

            // Flag as cap reached if we cycle back to the first item
            if (mode == PoolMode.Capped && poolIndex == 0)
            {
                capReached = true;
            }

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

            return PlaceObject(evt.Pose.position, evt.Pose.forward);
        }

        public GameObject PlaceObject(Vector3 positionWR, Vector3 normalWR)
        {
            var go = GetNext();

            // Null GO means either we have a problem, or we simply reached the object cap
            if (go != null)
            {
                Vector3 norm = normalWR;
                Vector3 pos = positionWR + norm * surfaceBias;

                PositionObject(go, pos, norm);
            }

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

            if (onPositionObject != null)
            {
                onPositionObject.Invoke((pos, norm));
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

        #region Editor Helpers

        [Button]
        void PopulatePool()
        {
#if UNITY_EDITOR
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
                GameObject g = PrefabUtility.InstantiatePrefab(templatePrefab, transform) as GameObject; //Instantiate(templatePrefab, transform, false);
                
                g.name = $"Pool Instance [{templatePrefab.name}]";
                g.SetActive(false);

                Repositionable r;
                if (!g.TryGetComponent(out r))
                {
                    r = g.GetComponentInChildren<Repositionable>();
                }

                if (r != null)
                {
                    onPositionObject.AddListener(r.Reposition);
                }

                PopulatePoolAdditional(g);

                pool.Add(g);
            }
#endif
        }

        protected virtual void PopulatePoolAdditional(GameObject instance)
        {

        }

        [Button]
        void DistributeGrid(Vector4 xzRange)
        {
#if UNITY_EDITOR
            float countRoot = Mathf.Sqrt(poolCapacity);
            float xSize = Mathf.Abs(xzRange.x - xzRange.y);
            float zSize = Mathf.Abs(xzRange.z - xzRange.w);

            float xGrid = Mathf.Max(Mathf.Ceil(countRoot * xSize / zSize), 1);
            float zGrid = Mathf.Max(Mathf.Ceil(countRoot * zSize / xSize), 1);

            int undoGroup = Undo.GetCurrentGroup();
            bool shouldBreak = false;

            for (int z = 0; z < zGrid; ++z)
            {
                float t_z = z / (zGrid - 1);
                for (int x = 0; x < xGrid; ++x)
                {
                    int index = Mathf.RoundToInt(z * xGrid + x);

                    float t_x = x / (xGrid - 1);
                    float xPos = Mathf.Lerp(xzRange.x, xzRange.y, t_x);
                    float zPos = Mathf.Lerp(xzRange.z, xzRange.w, t_z);

                    if (index >= poolCapacity)
                    {
                        shouldBreak = true;
                        break;
                    }

                    Transform target = pool[index].transform;

                    Undo.RecordObject(target, "Distribute Grid");

                    target.localPosition = new Vector3(xPos, 0, zPos);
                }

                if (shouldBreak) {
                    break;
                }
            }

            Undo.CollapseUndoOperations(undoGroup);
#endif
        }

        #endregion
    }

    [SerializeField]
    public class PositioningEvent : UnityEvent<(Vector3, Vector3)>
    {

    }

    public abstract class Repositionable : MonoBehaviour
    {
        public abstract void Reposition((Vector3, Vector3) posNorm);
    }
}
