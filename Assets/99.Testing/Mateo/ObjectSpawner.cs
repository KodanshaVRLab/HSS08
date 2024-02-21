using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    public class ObjectSpawner : MonoBehaviour
    {
        [SerializeField] Bounds spawnVolume = new Bounds(Vector3.zero, Vector3.one * 2f);
        public bool randomizeRotation = false;

        [SerializeField] GameObject[] templates = new GameObject[] { };
        [SerializeField, ReadOnly] ModelStats[] stats = new ModelStats[] { };

        [SerializeField, ReadOnly] ModelStats _totalStats;
        public ModelStats TotalStats
        {
            get { return _totalStats; }
        }

        public int TemplateCount => templates.Length;

        public int TotalVertexCount
        {
            get; private set;
        }

        public int TotalTriCount
        {
            get; private set;
        }

        public int TotalMaterialCount
        {
            get; private set;
        }

        public int TotalMeshCount
        {
            get; private set;
        }

        public int TotalSkinnedCount
        {
            get; private set;
        }

        private void OnValidate()
        {
            // Precalculate model stats in the editor
            if (templates != null && !Application.isPlaying)
            {
                stats = new ModelStats[templates.Length];
                for (int i = 0; i < templates.Length; ++i)
                {
                    PrecalculateModelStats(i);
                }
            }

            _totalStats.name = "TOTALS";
        }

        private void Awake()
        {
            Clear();
        }

        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {

        }

        [Button]
        public GameObject Spawn(int index)
        {
            int i = SanitizeIndex(index);

            var place = PickPlacement();
            GameObject instance = Instantiate(templates[i], transform, false);
            instance.transform.SetLocalPositionAndRotation(place.Item1, place.Item2);

            UpdateTotals(i);

            return instance;
        }

        public ModelStats GetTemplateStats(int index)
        {
            int i = SanitizeIndex(index);
            return stats[i];
        }


        [Button]
        public void Clear()
        {
            // Destroy GameObjects
            for (int i = transform.childCount - 1; i >=0; --i)
            {
                Transform t = transform.GetChild(i);
                Destroy(t.gameObject);
            }

            // Reset totals
            _totalStats = new ModelStats { name = "TOTALS" };

            //TotalVertexCount = 0;
            //TotalTriCount = 0;
            //TotalMaterialCount = 0;
            //TotalMeshCount = 0;
            //TotalSkinnedCount = 0;
        }

        int SanitizeIndex(int index)
        {
            if (templates == null || templates.Length == 0)
            {
                return -1;
            }

            int i = Mathf.Max(0, Mathf.Min(templates.Length - 1, index));

            return i;
        }

        (Vector3, Quaternion) PickPlacement()
        {
            Vector3 pos = new Vector3(
                (Random.value - 0.5f) * spawnVolume.size.x,
                (Random.value - 0.5f) * spawnVolume.size.y,
                (Random.value - 0.5f) * spawnVolume.size.z
                ) + spawnVolume.center;

            Quaternion rot = randomizeRotation ? Random.rotationUniform : Quaternion.identity;

            return (pos, rot);
        }

        void UpdateTotals(int index)
        {
            var s = stats[index];

            _totalStats.vertCount += s.vertCount;
            _totalStats.triCount += s.triCount;
            _totalStats.materialCount += s.materialCount;
            _totalStats.meshRendererCount += s.meshRendererCount;
            _totalStats.skinnedRendererCount += s.skinnedRendererCount;
        }

        void PrecalculateModelStats(int index)
        {
            int i = SanitizeIndex(index);
            GameObject model = templates[i];
            ModelStats s = new ModelStats();

            if (model == null)
            {
                return;
            }

            s.name = model.name;
            AddStaticMeshStats(model, ref s);
            AddSkinnedMeshStats(model, ref s);

            stats[i] = s;
        }

        void AddStaticMeshStats(GameObject root, ref ModelStats stats)
        {
            var mf = root.GetComponentsInChildren<MeshFilter>();
            var mr = root.GetComponentsInChildren<MeshRenderer>();
            List<Material> materials = new List<Material>();

            for (int i = 0; i < mf.Length; ++i)
            {
                stats.vertCount += mf[i].sharedMesh.vertexCount;
                stats.triCount += mf[i].sharedMesh.triangles.Length / 3;

                foreach (Material m in mr[i].sharedMaterials)
                {
                    if (!materials.Contains(m))
                    {
                        materials.Add(m);
                    }
                }
            }

            stats.materialCount += materials.Count;
            stats.meshRendererCount += mr.Length;
        }

        void AddSkinnedMeshStats(GameObject root, ref ModelStats stats)
        {
            var sr = root.GetComponentsInChildren<SkinnedMeshRenderer>();
            List<Material> materials = new List<Material>();

            for (int i = 0; i < sr.Length; ++i)
            {
                stats.vertCount += sr[i].sharedMesh.vertexCount;
                stats.triCount += sr[i].sharedMesh.triangles.Length / 3;

                foreach (Material m in sr[i].sharedMaterials)
                {
                    if (!materials.Contains(m))
                    {
                        materials.Add(m);
                    }
                }
            }

            stats.materialCount += materials.Count;
            stats.skinnedRendererCount += sr.Length;
        }

        #region Debug

        [Button]
        void PrintTemplateStats()
        {
            if (templates == null)
            {
                return;
            }

            for (int i = 0; i < templates.Length; ++i)
            {
                Debug.Log(GetTemplateStats(i), gameObject);
            }
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.matrix = transform.localToWorldMatrix;
            Gizmos.color = Color.white;
            Gizmos.DrawWireCube(spawnVolume.center, spawnVolume.size);
            Gizmos.matrix = Matrix4x4.identity;
        }

        #endregion
    }

    [System.Serializable]
    public struct ModelStats
    {
        public string name;
        public int vertCount;
        public int triCount;
        public int materialCount;
        public int meshRendererCount;
        public int skinnedRendererCount;

        public override string ToString()
        {
            return $"Model Name: {name}\nVertices: {vertCount}\nTriangles: {triCount}\nMaterials: {materialCount}\nMesh Renderers: {meshRendererCount}\nSKinned Mesh renderers: {skinnedRendererCount}";
        }
    }
}
