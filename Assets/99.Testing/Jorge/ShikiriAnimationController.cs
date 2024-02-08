using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShikiriAnimationController : MonoBehaviour
{
    public Animator anim;
    public float maxSpeed = 0.05f;
    [Range(0f, 1f)]
    public float walkBlend;
    public float speed=0.1f;
    public bool isDancing, isWalking;
    public float maxRayDist = 1000;
    public LayerMask lm;
    public float rotationSpeed = 1f;
    public bool wallIsDetected;
    Quaternion targetRotation;
    float roationDelta = 0f;
    public Transform rayPoint;
    // Start is called before the first frame update
    void Start()
    {
        anim = GetComponent<Animator>();
        walkBlend = 0.7f;
    }

    // Update is called once per frame
    void Update()
    {
        if(anim)
        {
            anim.SetBool("isDancing", isDancing);
            anim.SetBool("isWalking", isWalking);

            anim.SetLayerWeight(1, walkBlend);

            transform.position += transform.forward * speed;
        }
        Ray r = new Ray(rayPoint.position, rayPoint.forward);
        RaycastHit hito;
        
        if(!wallIsDetected && Physics.Raycast(r,out hito,maxRayDist,lm))
        {
            
            wallIsDetected = true;
            Debug.Log(hito.normal);
            Vector3 forward = transform.up - hito.normal* Vector3.Dot(transform.up, hito.normal);
            targetRotation= Quaternion.LookRotation(forward, hito.normal);
             
        }
        else if(wallIsDetected)
        {
            speed = maxSpeed/3f;
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, roationDelta);
            roationDelta += Time.deltaTime*rotationSpeed;
            if(roationDelta>1)
            {
                roationDelta = 0;
                wallIsDetected = false;
                speed =maxSpeed;
            }
        }
    }
}
