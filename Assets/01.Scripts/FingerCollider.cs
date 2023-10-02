using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FingerCollider : MonoBehaviour
{

    public float maxLaserDistance=3f;
    public MikasaController mikasa;
    LineRenderer lr;
    public bool hasTarget;
    public LayerMask layerMask;

    RaycastHit hito;
    public OVRHand controllingHand, otherHand;
    public bool mikasaSelected, twoHandSelection,controllingHandSelection,otherHandSelection;
    public bool controllingHandPinch, otherHandPinch;
    VRDistanceButton currentVRDistanceBtn;

    public PlayerMG playerMG;

    Vector3 controllingHandInitialPos, otherHandInitialPos, otherHandInitialRot;

    float handsInitialDistance;
    public Transform rayOrigin;
    MikasaInteractableObject currentController;

    public bool useRot;
    public GameObject currentSelectedObject;
    public List<GameObject> placableObjects;
    public TextMesh debugText;
    public VRButton handButton;
    public RotationSystem rotSystem;
    public FingerCollider otherFinger;

    public HandInteractor handInteractor, otherhandInteractor;
    // Start is called before the first frame update
    void Start()
    {
        GetComponent<Renderer>().material.color = Color.green;
        lr = GetComponent<LineRenderer>();
        rayOrigin = rayOrigin ? rayOrigin : transform;
        currentSelectedObject = mikasa.gameObject;
    }
    private void OnTriggerEnter(Collider other)
    {
        GetComponent<Renderer>().material.color = Color.red;
        VRButton button;
        
        if (other.TryGetComponent<VRButton>(out button) && button!=handButton)
        {
            button.Click();
        }
        
        

    }
    public void updateCurrentObject(GameObject newObject)
    {
        currentSelectedObject = newObject;
    }
    private void OnTriggerExit(Collider other)
    {
        GetComponent<Renderer>().material.color = Color.green;
    }
    // Update is called once per frame
    void Update()
    {
        if (debugText)
        {
            debugText.text = "has object " + (currentSelectedObject != null) + " left pinch" + controllingHandPinch.ToString();
        }
        if (!lr) return;
        lr.SetPosition(0, rayOrigin.position);
        Ray r = new Ray(rayOrigin.position, rayOrigin.position- rayOrigin.right*maxLaserDistance);
        controllingHandPinch = controllingHand && controllingHand.GetFingerIsPinching(OVRHand.HandFinger.Index);
        otherHandPinch = otherHand && otherHand.GetFingerIsPinching(OVRHand.HandFinger.Index);
        
        if (currentSelectedObject)
        {
            lr.enabled = true;

            if ( Physics.Raycast(r,out hito, maxLaserDistance, layerMask))
            {
                
                if(currentSelectedObject && hito.normal.normalized.y>=0.91f)
                {
                    currentSelectedObject.SetActive(true);
                    currentSelectedObject.transform.position = hito.point;
                    lr.material.color = Color.green;
                }
                else
                {
                    lr.material.color = Color.red;
                    currentSelectedObject.SetActive(false);
                }

                //if (!mikasaSelected)
                {

                    if (hito.transform.TryGetComponent<VRDistanceButton>(out currentVRDistanceBtn) && controllingHandPinch)
                    {
                        //hito.transform.GetComponent<VRDistanceButton>().Click();
                        mikasaSelected = true;
                    }
                    if(mikasa.currentState!= MikasaController.State.editing || (currentController&& currentController.transform!= hito.transform) )
                    {

                        if(controllingHandPinch && hito.transform.TryGetComponent<MikasaInteractableObject>(out currentController))
                        {
                            currentController.SetupMikasa(mikasa);
                            currentSelectedObject = null;
                        }                  
                    
                    }
                    lr.SetPosition(1, hito.point);
                    lr.material.color = Color.green;
                    hasTarget = true;
                }
            }
            else
            {
                lr.SetPosition(1, rayOrigin.position - rayOrigin.right * maxLaserDistance);
                lr.material.color = Color.red;
            }
               

        }
        else
        {
            lr.enabled = false;

             
           /* lr.SetPosition(1, rayOrigin.position - rayOrigin.right * maxLaserDistance);
            lr.material.color = Color.red;
            hasTarget = false;
            if(mikasaSelected && currentVRDistanceBtn)
            {
               // currentVRDistanceBtn.Diselect();
                mikasaSelected = false;
                currentVRDistanceBtn = null;

            }*/
        }


        if(mikasa.currentState== MikasaController.State.editing)
        {
            if(rotSystem)
            rotSystem.UpdateTransform(controllingHandPinch && otherHandPinch, handInteractor.wristTransform,otherhandInteractor.wristTransform);
            //UpdateTrasnform();
        }
    }

    private void UpdateTrasnform()
    {
        if (controllingHandPinch && otherHandPinch)
        {

            if(playerMG)
            {
                if(!twoHandSelection)
                {
                    controllingHandInitialPos = controllingHand.transform.position;
                    otherHandInitialPos = otherHand.transform.position;
                    handsInitialDistance = Vector3.Distance(controllingHandInitialPos, otherHandInitialPos);
                    twoHandSelection = true;
                }
                else
                {
                    var delta = Vector3.Distance(controllingHand.transform.position, otherHand.transform.position) - handsInitialDistance;
                    playerMG.UpdateScale(delta);
                }
                
            }
        }
        else //if only one hand controlling hand translation, other hand rotation
        {
            
            twoHandSelection = false;
            if(!otherHandSelection && controllingHandPinch)
            {
                if(!controllingHandSelection)
                {
                    controllingHandInitialPos = controllingHand.transform.position;
                    controllingHandSelection = true;
                }
                else
                {
                    var delta = controllingHand.transform.position - controllingHandInitialPos;
                    playerMG.UpdatePosition(delta);
                }
            }
            else
            {
                controllingHandSelection = false;
            }
            if(!controllingHandSelection && otherHandPinch)
            {
                if (!otherHandSelection)
                {
                    otherHandInitialPos = otherHand.transform.position;
                    otherHandInitialRot = otherHand.transform.rotation.eulerAngles;
                    otherHandSelection = true;
                }
                else
                {
                    var delta = otherHand.transform.position- otherHandInitialPos;
                    var deltarot = otherHand.transform.rotation.eulerAngles - otherHandInitialRot;
                    delta = new Vector3(delta.y, delta.z, delta.x);
                    
                    playerMG.UpdateRotaion(useRot? deltarot:delta);
                }
            }
            else
            {
                otherHandSelection = false;
            }
        }
    }

    public Vector3 getLaserPointingPoint() => lr ? lr.GetPosition(1) : Vector3.zero;

    public void setMikasaPosition()
    {
         
        if(mikasa && hasTarget)
        {
            MikasaInteractableObject Mio;
            if(hito.transform.TryGetComponent<MikasaInteractableObject>(out Mio))
            {
                Mio.SetupMikasa(mikasa);
            }
            


        }
    }
}
