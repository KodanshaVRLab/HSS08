using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static UnityEngine.InputSystem.InputAction;
using UnityEngine.UI;
using Sirenix.OdinInspector;

public class PassTroughController : MonoBehaviour
{
    public OVRPassthroughLayer passtrough;
    float passTAmount;
    public float passSpeed = 0.1f;
    public Vector3 color;
    public bool edgeOn;
    int currentColorType = 0;
    public GameObject[] controllers;

    public Slider contrast, brightness, saturation;
    public Slider GrayScale_Contrast, Grayscale_Brightness, Grayscale_Posterize;
    public Slider GrayScale2Color_Contrast, Grayscale2Color_Brightness, Grayscale2Color_Posterize;
    public Slider ColorLut_Blend;
    public Slider BlendedLut_Blend;
    public TMPro.TextMeshProUGUI CurrentModelabel, toggleBtnLabel;

    public Texture2D originLUT, targetLUT;
    
    // Start is called before the first frame update
    void Start() 
    {
        currentColorType = 6;
        updateColorСontrol();
        passtrough = GetComponent<OVRPassthroughLayer>();
        if (!passtrough)
            Destroy(this);
        changeColor();
    }
    public GameObject test;
    float currentContrast, currentSaturation, currentBrightness, currentGSContrast,currentGSBrightness,currentGSPosterize;
    float currentLutBlend, currentBlendedLutBlend;
    public Image colorIMG;
    [Button]
    public void updateColorСontrol()
    {

        /*
             public enum ColorMapEditorType
    {
        None = 0,
        GrayscaleToColor = 1,
        Controls = 1,
        Custom = 2,
        Grayscale = 3,
        ColorAdjustment = 4,
        ColorLut = 5,
        InterpolatedColorLut = 6
    }*/

        switch (currentColorType)
        {
            case 1:
                currentColorType = 5;
                break;
            
            case 3:
                currentColorType = 1;
                break;
            case 4:
                currentColorType = 3;
                break;
            case 5:
                currentColorType = 6;
                break;
            case 6:
                currentColorType = 4;
                break;
            default:
                currentColorType = 3;
                break;
        }

        for (int i = 0; i < controllers.Length; i++)
        {
            if(controllers[i])
            controllers[i].SetActive(false);
        }
         
        passtrough.colorMapEditorType = (OVRPassthroughLayer.ColorMapEditorType)currentColorType;
        if (currentColorType<controllers.Length)
        controllers[currentColorType].SetActive(true);
        if (CurrentModelabel)
            CurrentModelabel.text = ((OVRPassthroughLayer.ColorMapEditorType)currentColorType).ToString();
    }

    public void updateColorAdjustment()
    {

    }
    
    public void RightStick(CallbackContext context)
    {
        
    }
    public void LeftStick(CallbackContext context)
    {
        
    }
    public void OnBButton(CallbackContext context)
    {
        
    }
    public void OnAButton(CallbackContext context)
    {

        
    }

    public void updateContrast(float c)
    {
        currentContrast = c;
        passtrough.SetBrightnessContrastSaturation(currentBrightness, currentContrast, currentSaturation);
    }
    public void updateBrightness(float c)
    {
        currentBrightness= c;
        passtrough.SetBrightnessContrastSaturation(currentBrightness, currentContrast, currentSaturation);
    }
    public void updateSaturation(float c)
    {
        currentSaturation= c;
        passtrough.SetBrightnessContrastSaturation(currentBrightness, currentContrast, currentSaturation);
     }
    public void updateLutBlend(float c)
    {
        currentLutBlend = c;
        passtrough.SetColorLut(new OVRPassthroughColorLut(originLUT), currentLutBlend);
    }
    public void updateBlendedLutBlend(float c)
    {
        currentBlendedLutBlend = c;
        passtrough.SetColorLut(new OVRPassthroughColorLut(originLUT), currentBlendedLutBlend);
    }

    //Grayscale
    public void updateGSContrast(float c)
    {
        currentGSContrast = c;
        passtrough.SetColorMapControls(currentGSContrast, currentGSBrightness, currentGSPosterize, null, (OVRPassthroughLayer.ColorMapEditorType)currentColorType);
    }
    public void updateGSBrightness(float c)
    {
        currentGSBrightness = c;
        passtrough.SetColorMapControls(currentGSContrast,currentGSBrightness,currentGSPosterize,null, (OVRPassthroughLayer.ColorMapEditorType)currentColorType);
    }
    public void updatePosterize(float c)
    {
        currentGSPosterize = c;
        passtrough.SetColorMapControls(currentGSContrast, currentGSBrightness, currentGSPosterize, null, (OVRPassthroughLayer.ColorMapEditorType)currentColorType);
    }

    public void updatePasstrough(float passtroughAmount)
    {
        passTAmount = passtroughAmount;
        passtrough.textureOpacity = passTAmount;
    }
    public void toggleEdgeRendering(bool value)
    {
        edgeOn = value;
        passtrough.edgeRenderingEnabled = edgeOn;
    }
    public void toggleEdgeRendering()
    {
        edgeOn = !edgeOn;
        if (toggleBtnLabel)
            toggleBtnLabel.text = edgeOn ? "Turn Edges Off" : "TurnEdgesOn";
        passtrough.edgeRenderingEnabled = edgeOn;
    }
    public void changeColor()
    {
        passtrough.edgeColor = new Color(color.x,color.y,color.z);
        if (colorIMG) colorIMG.color = passtrough.edgeColor;
    }
    public void updateColorX(float x)
    {
        color.x = x;
        
        changeColor();
    }
    public void updateColorY(float x)
    {
        color.y = x;
        changeColor();
    }
    public void updateColorZ(float x)
    {
        color.z= x;
        changeColor();
    }
    // Update is called once per frame
    void Update()
    {
        
    }
}
