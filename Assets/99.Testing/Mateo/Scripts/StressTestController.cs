using Sirenix.OdinInspector;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.Universal.Internal;
using UnityEngine.UI;
using UnityEngine.VFX;


namespace KVRL.HSS08.Testing
{
    public class StressTestController : MonoBehaviour
    {
        [SerializeField] OVRManager ovr;
        [SerializeField] OVRPassthroughLayer passthroughLayer;

        [Header("Skinned Meshes")]
        [SerializeField] Transform skinnedMeshContainer;
        private List<SkinnedMeshRenderer> skinnedMeshes;
        [SerializeField] Slider skinnedMeshSlider;
        [SerializeField] TMP_Text skinnedMeshCounter;
        [SerializeField] TMP_Text skinnedTriangleCounter;
        [SerializeField] int maxSkinnedMeshes = 100;

        private int trisPerSkinnedMesh = 0;
        private int vertsPerSkinnedMesh = 0;

        [Header("Meshes")]
        [SerializeField] Transform meshContainer;
        private List<MeshRenderer> meshes;
        [SerializeField] Slider meshSlider;
        [SerializeField] TMP_Text meshCounter;
        [SerializeField] TMP_Text triangleCounter;
        [SerializeField] int maxMeshes = 100;

        private int vertsPerMesh = 0;
        private int trisPerMesh = 0;

        [Header("Visual Effects")]
        [SerializeField] Transform VFXContainer;
        private List<VisualEffect> vfxs;
        [SerializeField] Slider vfxSlider;
        [SerializeField] TMP_Text vfxCounter;
        [SerializeField] Slider particleSlider;
        [SerializeField] TMP_Text particleCounter;
        [SerializeField] TMP_Text totalParticleCounter;
        [SerializeField] int maxSystems = 50;
        [SerializeField] int maxParticlesPerSystem = 8000;

        private int systemCount = 0;
        private int particleCount = 50;

        [Header("Features")]
        [SerializeField, ReadOnly] Camera hmdCamera;

        [SerializeField] GameObject ppVolume;
        [SerializeField, ReadOnly] VolumeProfile postPro;
        [SerializeField] Toggle ppToggle;
        [SerializeField] Toggle[] ppEffectToggles;

        [SerializeField] Toggle passthroughToggle;

        [SerializeField] GameObject hdriSky;
        [SerializeField] Toggle hdriSkyToggle;

        public int SkinnedMeshCount
        {
            get; private set;
        }

        public int MeshCount
        {
            get; private set;
        }

        public int VFXCount
        {
            get; private set;
        }

        public int ParticleCount
        {
            get; private set;
        }

        public bool PassthroughEnabled
        {
            get; private set;
        }

        [Flags]
        public enum PostProEffectTests
        {
            Tonemapping = 0b00000001,
            Bloom =        0b00000010,
            DOF =          0b00000100,
            ColorAdjust =  0b00001000
        }
        public PostProEffectTests PostProMask
        {
            get; private set;
        }

        [Header("Debug")]
        [SerializeField] bool debugVerbose = false;

        protected virtual void OnValidate()
        {
            if (ovr == null)
            {
                ovr = FindObjectOfType<OVRManager>();
            }

            if (passthroughLayer == null)
            {
                passthroughLayer = FindObjectOfType<OVRPassthroughLayer>();
            }
        }

        private void Awake()
        {
            PopulateComponentList(skinnedMeshContainer, ref skinnedMeshes);
            GameObject smTemplate = BindComponentList(skinnedMeshContainer, skinnedMeshes, skinnedMeshSlider, skinnedMeshCounter, maxSkinnedMeshes, true);
            ComputeSkinnedPolyEstimate(smTemplate);
            BindGeometryStats(skinnedMeshSlider, skinnedTriangleCounter, vertsPerSkinnedMesh, trisPerSkinnedMesh);

            PopulateComponentList(meshContainer, ref meshes);
            GameObject mTemplate = BindComponentList(meshContainer, meshes, meshSlider, meshCounter, maxMeshes, true);
            ComputeMeshPolyEstimate(mTemplate);
            BindGeometryStats(meshSlider, triangleCounter, vertsPerMesh, trisPerMesh);

            PopulateComponentList(VFXContainer, ref vfxs);
            BindComponentList(VFXContainer, vfxs, vfxSlider, vfxCounter, maxSystems);
            BindVFXParticleCount(vfxs, vfxSlider, particleSlider, particleCounter, totalParticleCounter);

            var ovrRig = ovr.GetComponent<OVRCameraRig>();
            var camL = ovrRig.leftEyeCamera;
            var camC = ovrRig.centerEyeAnchor.GetComponent<Camera>();
            var camR = ovrRig.rightEyeCamera;



            BindMasterPostPro(ppVolume,
                camL.GetUniversalAdditionalCameraData(),
                camC.GetUniversalAdditionalCameraData(),
                camR.GetUniversalAdditionalCameraData(),
                ppToggle, ppEffectToggles);
            BindPostToggles(ppEffectToggles);

            BindPassthrough(passthroughToggle);
            BindHDRISky(hdriSky, camL, camC, camR, hdriSkyToggle);

            RefreshAllStates();
        }

        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {

        }

        public void SetPostEffects(PostProEffectTests mask)
        {
            if (postPro != null)
            {
                SetPostState<Tonemapping>(postPro, PostProEffectTests.Tonemapping, mask);
                SetPostState<Bloom>(postPro, PostProEffectTests.Bloom, mask);
                SetPostState<DepthOfField>(postPro, PostProEffectTests.DOF, mask);
                SetPostState<ColorAdjustments>(postPro, PostProEffectTests.ColorAdjust, mask);
            }
        }

        void SetPostState<T>(VolumeProfile post, PostProEffectTests flag, PostProEffectTests mask) where T : VolumeComponent
        {
            T effect;
            if (post.TryGet(out effect))
            {
                effect.active = (flag & mask) != 0;
            }
        }

        public void TogglePostEffect(PostProEffectTests mask)
        {

        }

        public void SetPassthrough(bool passthrough)
        {

        }

        public void TogglePassthrough()
        {

        }

        public void SetVFXCount(float vfxCount)
        {

        }

        public void SetParticleCount(float particleCount)
        {

        }

        void PopulateComponentList<T>(Transform container, ref List<T> list) where T : Component
        {
            if (container != null)
            {
                list = new List<T>();

                for (int i = 0; i < container.childCount; ++i)
                {
                    Transform c = container.GetChild(i);

                    T t;
                    if (c.TryGetComponent<T>(out t))
                    {
                        list.Add(t);
                    }
                    else // Cover deeply nested components, like skinned mesh renderers in model prefabs
                    {
                        t = c.GetComponentInChildren<T>();
                        if (t != null)
                        {
                            list.Add(t);
                        }
                    }
                }

                if (debugVerbose)
                {
                    Debug.Log($"Found {list.Count} components within {container.name}");
                }
            }
        }

        GameObject BindComponentList<T>(Transform container, List<T> components, Slider slider, TMP_Text counter, int maxValue, bool bindRoot = false) where T : Component
        {
            if (components != null && components.Count > 0 && slider != null && counter != null)
            {
                void Callback(float value)
                {
                    int target = (int)value;
                    for (int i = 0; i < components.Count; ++i)
                    {
                        T t = components[i];
                        if (bindRoot)
                        {
                            Transform root = t.transform;
                            while (root.parent != container)
                            {
                                root = root.parent;
                            }

                            root.gameObject.SetActive(i < target);
                        }
                        else
                        {
                            // t.enabled = i < target; // unity is fucking stupid and makes built-in components NOT MonoBehaviours, and only SOMETIMES Behaviours (enable/disable-able)
                            // Renderers Can be enabled/disabled but inherit from Component directly and NOT from Behaviour. Thanks.
                            t.gameObject.SetActive(i < target);
                        }
                    }

                    counter.text = $"{target}/{maxValue}";
                }

                slider.minValue = 0;
                slider.maxValue = maxValue;
                slider.onValueChanged.AddListener(Callback);
            }
            else if (debugVerbose)
            {
                Debug.LogError($"Could not bind slider callback, make sure references aren't null!\nContainer: {container}\nSlider: {slider}\nCounter: {counter}", gameObject);
            }

            return container != null ? container.GetChild(0).gameObject : null;
        }

        void ComputeSkinnedPolyEstimate(GameObject root)
        {
            if (debugVerbose && root != null)
            {
                Debug.Log($"Estimating stats for Skinned Meshes in {root.name}", gameObject);
            }

            if (root == null)
            {
                Debug.LogError("No GameObject found to compute Skinned Mesh stats!", gameObject);
                return;
            }

            var renderers = root.GetComponentsInChildren<SkinnedMeshRenderer>();
            int totalTris = 0, totalVerts = 0;
            foreach (SkinnedMeshRenderer renderer in renderers)
            {
                totalVerts += renderer.sharedMesh.vertices.Length;
                totalTris += renderer.sharedMesh.triangles.Length;
            }

            vertsPerSkinnedMesh = totalVerts;
            trisPerSkinnedMesh = totalTris;
        }

        void ComputeMeshPolyEstimate(GameObject root)
        {
            if (debugVerbose && root != null)
            {
                Debug.Log($"Estimating stats for Meshes in {root.name}", gameObject);
            }

            if (root == null)
            {
                Debug.LogError("No GameObject found to compute Mesh stats!", gameObject);
                return;
            }

            var renderers = root.GetComponentsInChildren<MeshFilter>();
            int totalTris = 0, totalVerts = 0;
            foreach (MeshFilter renderer in renderers)
            {
                totalVerts += renderer.sharedMesh.vertices.Length;
                totalTris += renderer.sharedMesh.triangles.Length;
            }

            vertsPerMesh = totalVerts;
            trisPerMesh = totalTris;
        }

        void BindGeometryStats(Slider slider, TMP_Text stats, int unitVerts, int unitTris)
        {
            if (slider == null || stats == null)
            {
                return;
            }

            void SetStats(float count)
            {
                int totalVerts = (int)count * unitVerts;
                int totalTris = (int)count * unitTris;

                stats.text = $"Verts: {totalVerts} // Tris: {totalTris}";
            }

            slider.onValueChanged.AddListener(SetStats);
        }

        void BindVFXParticleCount(List<VisualEffect> vfx, Slider systemSlider, Slider countSlider, TMP_Text counter, TMP_Text output)
        {
            if (vfx == null || vfx.Count == 0 || systemSlider == null || countSlider == null || output == null)
            {
                return;
            }

            void SetOutput(int count)
            {
                output.text = $"Total particles: {count}";
            }

            void SysCallback(float sysCount)
            {
                int count = (int)(sysCount * countSlider.value);
                SetOutput(count);
            }

            void CountCallback(float countCount)
            {
                for (int i = 0; i < vfx.Count; ++i)
                {
                    vfx[i].SetFloat("Particle Count", countCount);
                }

                counter.text = $"{(int)countCount}/{maxParticlesPerSystem}";

                int count = (int)(countCount * systemSlider.value);
                SetOutput(count);
            }

            systemSlider.onValueChanged.AddListener(SysCallback);
            countSlider.onValueChanged.AddListener(CountCallback);
            countSlider.maxValue = maxParticlesPerSystem;
        }

        void BindMasterPostPro(GameObject volume, UniversalAdditionalCameraData camL, UniversalAdditionalCameraData camC, UniversalAdditionalCameraData camR, Toggle toggle, Toggle[] subToggles)
        {
            if (volume != null &&
                camL != null &&
                camC != null &&
                camR != null &&
                toggle != null)
            {
                toggle.onValueChanged.AddListener((bool b) =>
                {
                    camL.renderPostProcessing = b;
                    camC.renderPostProcessing = b;
                    camR.renderPostProcessing = b;
                    volume.SetActive(b);

                    if (subToggles != null)
                    {
                        for (int i = 0; i < subToggles.Length; ++i)
                        {
                            subToggles[i].interactable = b;
                        }
                    }
                });

                postPro = volume.GetComponent<Volume>().profile;
            }
        }

        void BindPostToggles(Toggle[] toggles)
        {
            void GeneratePPMask(bool dummy)
            {
                int mask = 0;
                for (int i = 0; i < toggles.Length; ++i)
                {
                    mask += (toggles[i].isOn ? 1 : 0) << i;
                }

                SetPostEffects((PostProEffectTests)mask);
            }

            for (int i = 0;i < toggles.Length; ++i)
            {
                toggles[i].onValueChanged.AddListener(GeneratePPMask);
            }
        }

        void BindPassthrough(Toggle toggle)
        {
            if (toggle != null && ovr != null)
            {
                toggle.onValueChanged.AddListener((bool b) =>
                {
                    ovr.isInsightPassthroughEnabled = b;
                });
            }
        }

        void BindHDRISky(GameObject sky, Camera camL, Camera camC, Camera camR, Toggle toggle)
        {
            if (sky != null && toggle != null)
            {
                toggle.onValueChanged.AddListener((bool b) =>
                {
                    CameraClearFlags flag = b ? CameraClearFlags.Skybox : CameraClearFlags.SolidColor;

                    camL.clearFlags = camC.clearFlags = camR.clearFlags = flag;
                    sky.SetActive(b);
                });
            }
        }

        void RefreshAllStates()
        {
            skinnedMeshSlider.Trigger();
            meshSlider.Trigger();
            vfxSlider.Trigger();
            particleSlider.Trigger();

            passthroughToggle.Trigger();
            ppToggle.Trigger();
            if (ppEffectToggles != null && ppEffectToggles.Length > 0)
            {
                ppEffectToggles[0].Trigger();
            }
            hdriSkyToggle.Trigger();
        }
    }

    public static class UIExtensions
    {
        public static void Trigger(this Toggle toggle)
        {
            toggle.onValueChanged.Invoke(toggle.isOn);
        }

        public static void Trigger(this Slider slider)
        {
            slider.onValueChanged.Invoke(slider.value);
        }
    }
}
