using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static UnityEngine.InputSystem.InputAction;
using UnityEngine.UI;
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

    public void updateGraysCaleController()
    {

    }
    // Start is called before the first frame update
    void Start() 
    {
        passtrough = GetComponent<OVRPassthroughLayer>();
        if (!passtrough)
            Destroy(this);
    }
    public GameObject test;
    public void updateColorСontrol()
    {
        currentColorType++;
        if (currentColorType > 6) currentColorType = 0;
        passtrough.colorMapEditorType = (OVRPassthroughLayer.ColorMapEditorType)currentColorType;
        if (currentColorType<controllers.Length)
        controllers[currentColorType].SetActive(true);
    }
    
    public void RightStick(CallbackContext context)
    {
        var c = context.ReadValue<Vector2>();
        updatePasstrough(c.y * passSpeed);
        if(edgeOn)
        {
            color.x += c.x * passSpeed;
            changeColor();

        }
    }
    public void LeftStick(CallbackContext context)
    {
        var c = context.ReadValue<Vector2>();
         
        if (edgeOn)
        {
            color.y += c.x*passSpeed;
            color.z += c.y*passSpeed;
            changeColor();
        }
    }
    public void OnAButton(CallbackContext context)
    {
         
        if (test) test.SetActive(!test.activeInHierarchy);
        toggleEdgeRendering(!edgeOn);
    }
    public void updatePasstrough(float passtroughAmount)
    {
        passTAmount += passtroughAmount;
        passtrough.textureOpacity = passTAmount;
    }
    public void toggleEdgeRendering(bool value)
    {
        edgeOn = value;
        passtrough.edgeRenderingEnabled = edgeOn;
    }
    public void changeColor()
    {
        passtrough.edgeColor = new Color(color.x,color.y,color.z);
    }
    // Update is called once per frame
    void Update()
    {
        
    }
}
