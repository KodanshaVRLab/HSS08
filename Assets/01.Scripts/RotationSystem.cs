using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class RotationSystem : MonoBehaviour
{
    public TextMesh text;
    public Transform leftController, rightController,controlledObject;
    public Vector3 originalAngles, currentAngles, deltaAngles;
    public Vector3 rotationAngle;
    bool isGrabbed;
    public float speed = 1f;
    public float speedZ = 1f;

    public Vector2 rotZThreshold = new Vector2(30f,65f);
    public float rotXThreshold = 45f;
    public float rotYThreshold = 45f;
    public float initialRotZ, currentRotZ, deltaRotZ,finalrotZ;
    public MikasaController mikasa;
    // Start is called before the first frame update
    void Start()
    {
        isGrabbed = false;
    }

    [Sirenix.OdinInspector.Button]
    public void onGrab()
    {
        isGrabbed = true;
        originalAngles = new Vector3(
                    Vector3.SignedAngle(leftController.right, rightController.position - leftController.position, Vector3.right)
                    , Vector3.SignedAngle(leftController.up, rightController.position - leftController.position, Vector3.up)
                    ,Vector3.SignedAngle(leftController.forward, rightController.position - leftController.position, Vector3.forward));
       
        controlledObject = mikasa.currentParent;
        initialRotZ =  getSignedAngle((leftController.rotation.eulerAngles.x + rightController.rotation.eulerAngles.x) / 2f);
    }
    // Update is called once per frame
    void Update()
    {
        if(text && leftController &&rightController)
        text.text ="angles "+ Vector3.SignedAngle(leftController.right,  rightController.position - leftController.position, Vector3.right).ToString()+
                    " , "+Vector3.SignedAngle(leftController.up, rightController.position - leftController.position, Vector3.up).ToString()+
                    " , " + Vector3.SignedAngle(leftController.forward, rightController.position - leftController.position, Vector3.forward).ToString();

        if (isGrabbed)
        {
            currentAngles = new Vector3(
                   Vector3.SignedAngle(leftController.right, rightController.position - leftController.position, Vector3.right)
                   , Vector3.SignedAngle(leftController.up, rightController.position - leftController.position, Vector3.up)
                   , Vector3.SignedAngle(leftController.forward, rightController.position - leftController.position, Vector3.forward));
            deltaAngles =  originalAngles- currentAngles;
            
            
            


            if (controlledObject)
            {
                //controlledObject.rotation=Quaternion.Euler(controlledObject.rotation.eulerAngles+(new Vector3(deltaAngles.y, deltaAngles.x, currentRotZ)*speed));
              /*  if (Mathf.Abs(currentRotZ) > rotZThreshold)
                    controlledObject.Rotate(0, 0, currentRotZ * speedZ);

                else if (Mathf.Abs(deltaAngles.x)> Mathf.Abs(deltaAngles.y) &&  Mathf.Abs(deltaAngles.x) > rotXThreshold)
                {
                    controlledObject.Rotate(0,deltaAngles.x*speed, 0);
                }
                else if (Mathf.Abs(deltaAngles.y) > rotYThreshold)
                {
                    controlledObject.Rotate(deltaAngles.y*speed, 0, 0);
                }
              */
            }
        }


    }

    public float checker;
        public float getSignedAngle(float ang)
        {
        return ang > 180 ? ang - 360 : ang;
        }
        private void LateUpdate()
    {
        if(isGrabbed)
        {
            currentRotZ = getSignedAngle((leftController.rotation.eulerAngles.x + rightController.rotation.eulerAngles.x) / 2f);
            deltaRotZ = getSignedAngle( initialRotZ-currentRotZ);
            finalrotZ = currentRotZ < initialRotZ ? 1 : -1;
            checker = getSignedAngle( currentRotZ > initialRotZ ? currentRotZ - initialRotZ : initialRotZ - currentRotZ);
            // current rot es menor >40 o  current rot es mayor 130
            if(currentRotZ<initialRotZ && checker>rotZThreshold.x || currentRotZ>initialRotZ && checker<rotZThreshold.y)
            controlledObject.Rotate(controlledObject.forward * finalrotZ);
            // onGrab();
        }
    }

    internal void UpdateTransform(bool isGrabbing, Transform leftHand, Transform rightHand)
    {
        if (!isGrabbed && isGrabbing)
        {
            leftController = leftHand;
            rightController = rightHand;
            onGrab();
            
        }
        else if(!isGrabbing)
        {
            isGrabbed = false;
        }
    }
}
