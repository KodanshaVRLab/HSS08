using Sirenix.OdinInspector;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.UI;
using UnityEngine.VFX;


namespace KVRL.HSS08.Testing
{
    public class StressTestController : MonoBehaviour
    {
        [SerializeField] OVRManager ovr;
        [SerializeField] OVRPassthroughLayer passthroughLayer;

        [SerializeField] Transform skinnedMeshContainer;
        private List<SkinnedMeshRenderer> skinnedMeshes;
        [SerializeField] Slider skinnedMeshSlider;
        [SerializeField] TMP_Text skinnedMeshCounter;
        [SerializeField] TMP_Text skinnedTriangleCounter;
        [SerializeField] int maxSkinnedMeshes = 100;


        [SerializeField] Transform meshContainer;
        private List<MeshRenderer> meshes;
        [SerializeField] Slider meshSlider;
        [SerializeField] TMP_Text meshCounter;
        [SerializeField] TMP_Text triangleCounter;
        [SerializeField] int maxMeshes = 100;


        [SerializeField] Transform VFXContainer;
        private List<VisualEffect> vfxs;
        [SerializeField] Slider vfxSlider;
        [SerializeField] TMP_Text vfxCounter;
        [SerializeField] Slider particleSlider;
        [SerializeField] TMP_Text particleCounter;
        [SerializeField] TMP_Text totalParticleCounter;
        [SerializeField] int maxSystems = 50;
        [SerializeField] int maxParticlesPersystem = 8000;


        [SerializeField, ReadOnly] Camera hmdCamera;

        [SerializeField] GameObject ppVolume;
        [SerializeField, ReadOnly] PostProcessData postPro;
        [SerializeField] Toggle ppToggle;

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
            get;  private set;
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
            ColorGrading = 0b00000001,
            Bloom = 0b00000010
        }
        public PostProEffectTests PostProMask
        {
            get; private set;
        }

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
            BindComponentList(skinnedMeshContainer, skinnedMeshes, skinnedMeshSlider, skinnedMeshCounter, maxSkinnedMeshes, true);
            
            BindComponentList(meshContainer, meshes, meshSlider, meshCounter, maxMeshes);
            
            BindComponentList(VFXContainer, vfxs, vfxSlider, vfxCounter, maxSystems);

            var ovrRig = ovr.GetComponent<OVRCameraRig>();
            var camL = ovrRig.leftEyeCamera;
            var camC = ovrRig.centerEyeAnchor.GetComponent<Camera>();
            var camR = ovrRig.rightEyeCamera;

            

            BindMasterPostPro(ppVolume, 
                camL.GetUniversalAdditionalCameraData(), 
                camC.GetUniversalAdditionalCameraData(), 
                camR.GetUniversalAdditionalCameraData(), 
                ppToggle);
            BindPassthrough(passthroughToggle);
            BindHDRISky(hdriSky, camL, camC, camR, hdriSkyToggle);
        }

        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {

        }

        /// <summary>
        /// To test stress of having multiple character meshes at once
        /// </summary>
        /// <param name="skinnedMeshCount"></param>
        public void SetSkinnedMeshCount(float skinnedMeshCount)
        {

        }

        public void SetMeshCount(float meshCount)
        {

        }

        public void SetPostEffects(PostProEffectTests mask)
        {

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

                for (int i = 0; i < container.childCount; ++i) {
                    Transform c = container.GetChild(i);

                    T t;
                    if (c.TryGetComponent<T>(out t))
                    {
                        list.Add(t);
                    } else // Cover deeply nested components, like skinned mesh renderers in model prefabs
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

        void BindComponentList<T>(Transform container, List<T> components, Slider slider, TMP_Text counter, int maxValue, bool bindRoot = false) where T : Component
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
            } else if (debugVerbose)
            {
                Debug.LogError($"Could not bind slider callback, make sure references aren't null!\nContainer: {container}\nSlider: {slider}\nCounter: {counter}", gameObject);
            }
        }
    
        void BindMasterPostPro(GameObject volume, UniversalAdditionalCameraData camL, UniversalAdditionalCameraData camC, UniversalAdditionalCameraData camR, Toggle toggle)
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
                });
            }
        }

        void BindPassthrough(Toggle toggle) { 
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
    }
}
