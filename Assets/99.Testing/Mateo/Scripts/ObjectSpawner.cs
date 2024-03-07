using Sirenix.OdinInspector;
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
        private List<Material> uniqueMaterials = new List<Material>();

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
            for (int i = transform.childCount - 1; i >= 0; --i)
            {
                Transform t = transform.GetChild(i);
                Destroy(t.gameObject);
            }

            // Reset totals
            _totalStats = new ModelStats { name = "TOTALS" };

            // Reset Material list
            uniqueMaterials = new List<Material>();

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
            //_totalStats.materialCount += s.materialCount;
            _totalStats.meshRendererCount += s.meshRendererCount;
            _totalStats.skinnedRendererCount += s.skinnedRendererCount;

            _totalStats.MergeMaterials(s.sharedMaterials);
        }

        void PrecalculateModelStats(int index)
        {
            int i = SanitizeIndex(index);
            GameObject model = templates[i];
            ModelStats s = new ModelStats();
            LODStats l = new LODStats(0);
            s.sharedMaterials = new List<Material>();

            if (model == null)
            {
                return;
            }

            s.name = model.name;
            AddStaticMeshStats(model, ref s, ref l);
            AddSkinnedMeshStats(model, ref s, ref l);
            //Debug.LogWarning(l);

            stats[i] = s;
        }

        void AddStaticMeshStats(GameObject root, ref ModelStats stats, ref LODStats lods)
        {
            var mf = root.GetComponentsInChildren<MeshFilter>();
            var mr = root.GetComponentsInChildren<MeshRenderer>();
            //List<Material> materials = new List<Material>();

            for (int i = 0; i < mf.Length; ++i)
            {
                stats.vertCount += mf[i].sharedMesh.vertexCount;
                stats.triCount += mf[i].sharedMesh.triangles.Length / 3;

                foreach (Material m in mr[i].sharedMaterials)
                {
                    if (!stats.sharedMaterials.Contains(m))
                    {
                        stats.sharedMaterials.Add(m);
                    }
                }

                //lods.AnalyzeMesh(mf[i].sharedMesh); // TODO: Change to on-demand function to avoid editor freezes
            }

            //stats.materialCount += materials.Count;
            stats.meshRendererCount += mr.Length;
        }

        void AddSkinnedMeshStats(GameObject root, ref ModelStats stats, ref LODStats lods)
        {
            var sr = root.GetComponentsInChildren<SkinnedMeshRenderer>();
            //List<Material> materials = new List<Material>();

            for (int i = 0; i < sr.Length; ++i)
            {
                stats.vertCount += sr[i].sharedMesh.vertexCount;
                stats.triCount += sr[i].sharedMesh.triangles.Length / 3;

                foreach (Material m in sr[i].sharedMaterials)
                {
                    if (!stats.sharedMaterials.Contains(m))
                    {
                        stats.sharedMaterials.Add(m);
                    }
                }

                //lods.AnalyzeMesh(sr[i].sharedMesh);
            }

            //stats.materialCount += materials.Count;
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
        public int meshRendererCount;
        public int skinnedRendererCount;
        public List<Material> sharedMaterials;
        public int MaterialCount => sharedMaterials != null ? sharedMaterials.Count : 0;

        public void MergeMaterials(List<Material> materials)
        {
            if (sharedMaterials != null)
            {
                foreach (Material m in materials)
                {
                    if (!sharedMaterials.Contains(m))
                    {
                        sharedMaterials.Add(m);
                    }
                }
            }
            else
            {
                sharedMaterials = new List<Material>();
                sharedMaterials.AddRange(materials);
            }
        }

        public override string ToString()
        {
            return $"Model Name: {name}\nVertices: {vertCount}\nTriangles: {triCount}\nMaterials: {MaterialCount}\nMesh Renderers: {meshRendererCount}\nSKinned Mesh renderers: {skinnedRendererCount}";
        }
    }

    [System.Serializable]
    public struct LODStats
    {
        public int LODCount;
        public float minTriSize;
        public float maxTriSize;
        public float meanTriSize;

        public LODStats(int lods)
        {
            LODCount = lods;
            minTriSize = float.MaxValue;
            maxTriSize = 0.0f;
            meanTriSize = 0.0f;
        }

        public void AnalyzeMesh(Mesh mesh)
        {
            if (mesh == null || Application.isPlaying)
            {
                return;
            }

            for (int i = 0; i < mesh.triangles.Length; i += 3)
            {
                Vector3 A = mesh.vertices[mesh.triangles[i    ]];
                Vector3 B = mesh.vertices[mesh.triangles[i + 1]];
                Vector3 C = mesh.vertices[mesh.triangles[i + 2]];

                CompareTri(A, B, C);
            }
        }

        public override string ToString()
        {
            return $"LODs:{LODCount}\nSmallest:{minTriSize}\nLargest:{maxTriSize}";
        }

        float Height(Vector3 v0, Vector3 v1, Vector3 v2)
        {
            Vector3 u0 = v0 - v1;
            Vector3 u1 = v2 - v1;

            Vector3 b = u0 * (Vector3.Dot(u0, u1) / u0.sqrMagnitude);
            Vector3 h = u1 - b;

            return h.magnitude;
        }

        void CompareTri(Vector3 v0, Vector3 v1, Vector3 v2)
        {
            float h0 = Height(v0, v1, v2);
            float h1 = Height(v1, v2, v0);
            float h2 = Height(v2, v0, v1);

            float triMin = Mathf.Min(h0, h1, h2);
            float triMax = Mathf.Max(h0, h1, h2);

            minTriSize = Mathf.Min(minTriSize, triMin);
            maxTriSize = Mathf.Max(maxTriSize, triMax);
        }
    }
}
