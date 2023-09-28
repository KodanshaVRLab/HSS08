using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerMG : MonoBehaviour
{
    // Start is called before the first frame update
    public MikasaController controller;


    public GameObject  positionGizmo,rotationGizmo,scaleGizmo;

    public float scaleSpeed = 0.1f;
    public float movingSpeed = 0.2f;
    public float rotatingSpeed = 0.01f;
    public Transform cam;
    public bool gizmosEnabled;
    public Transform leftHandPos, rightHandPos;

    public void disableGizmos()
    {
        positionGizmo.SetActive(false);
        rotationGizmo.SetActive(false);
        scaleGizmo.SetActive(false);
        gizmosEnabled = false;
    }
    public void enableGizmos()
    {
        positionGizmo.SetActive(true);
        rotationGizmo.SetActive(true);
        scaleGizmo.SetActive(true);
        gizmosEnabled = true;
       
    }
    public void UpdatePosition(Vector3 delta)
    {
        if(cam)
        {
            
         /*   positionGizmo.SetActive(true);
            rotationGizmo.SetActive(false);
            scaleGizmo.SetActive(false);*/
        }
        if(controller.isCharacterPlaced && controller.currentParent)
        {
            controller.currentParent.position += delta*movingSpeed;
        }
    }
    public void UpdateRotaion(Vector3 delta)
    {
        if (cam)
        {
           /*  positionGizmo.SetActive(false);
            rotationGizmo.SetActive(true);
            scaleGizmo.SetActive(false);*/
        }
        if (controller.isCharacterPlaced && controller.currentParent)
        {
            controller.currentParent.Rotate(delta*rotatingSpeed);
        }
    }
    public void UpdateScale(float delta)
    {
        if (cam)
        {
            /* positionGizmo.SetActive(false);
            rotationGizmo.SetActive(false);
            scaleGizmo.SetActive(true);*/
        }
        if (controller.isCharacterPlaced && controller.currentParent)
        {
            controller.currentParent.localScale+= Vector3.one* delta*scaleSpeed;
        }
    }
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if(gizmosEnabled)
        {
            scaleGizmo.transform.position = (leftHandPos.position + rightHandPos.position) * 0.5f;
        }
    }
}
