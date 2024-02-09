using Sirenix.OdinInspector;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
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
        [SerializeField, ReadOnly] PostProcessData postPro;

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
            BindComponentList(skinnedMeshContainer, skinnedMeshes, skinnedMeshSlider, skinnedMeshCounter, maxSkinnedMeshes);
            
            BindComponentList(meshContainer, meshes, meshSlider, meshCounter, maxMeshes);
            
            BindComponentList(VFXContainer, vfxs, vfxSlider, vfxCounter, maxSystems);
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

        void BindComponentList<T>(Transform container, List<T> components, Slider slider, TMP_Text counter, int maxValue) where T : Component
        {
            if (components != null && components.Count > 0 && slider != null && counter != null)
            {
                void Callback(float value)
                {
                    int target = (int)value;
                    for (int i = 0; i < components.Count; ++i)
                    {
                        T t = components[i];
                        // t.enabled = i < target; // unity is fucking stupid and makes built-in components NOT MonoBehaviours, and only SOMETIMES Behaviours (enable/disable-able)
                        // Renderers Can be enabled/disabled but inherit from Component directly and NOT from Behaviour. Thanks.
                        t.gameObject.SetActive(i < target); 
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
    }
}
