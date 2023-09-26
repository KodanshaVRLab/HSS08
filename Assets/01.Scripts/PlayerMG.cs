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

    public void UpdatePosition(Vector3 delta)
    {
        if(cam)
        {
            positionGizmo.transform.position = cam.transform.position + new Vector3(0, 0.5f, 3f);
            positionGizmo.SetActive(true);
            rotationGizmo.SetActive(false);
            scaleGizmo.SetActive(false);
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
            positionGizmo.transform.position = cam.transform.position + new Vector3(0, 0.5f, 3f);
            positionGizmo.SetActive(false);
            rotationGizmo.SetActive(true);
            scaleGizmo.SetActive(false);
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
            positionGizmo.transform.position = cam.transform.position + new Vector3(0, 0.5f, 3f);
            positionGizmo.SetActive(false);
            rotationGizmo.SetActive(false);
            scaleGizmo.SetActive(true);
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
        
    }
}
