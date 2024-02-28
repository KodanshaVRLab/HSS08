using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShikiriAnimationController : MonoBehaviour
{
    public Animator anim;
    public float maxSpeed = 0.05f;
    public float speedMultiplier = 0.5f;
    [Range(0f, 1f)]
    public float walkBlend;
    public float speed=0.1f;
    public bool isDancing, isWalking;
    public float maxRayDist = 1000;
    public LayerMask lm;
    public float rotationSpeed = 1f;
    public float positionSpeed = 1f;

    public bool wallIsDetected;
    Quaternion targetRotation;
    public float roationDelta = 0f;
    public float positionDelta = 0f;
    public Transform rayPoint;
    Quaternion startRotation;
    Vector3 hitPoint,startpos, hitPointOffset;
    public bool adjustPosition;
    public Transform debugSphere;
    LineRenderer lr;

    public Transform target;

    // Start is called before the first frame update
    void Start()
    {
        lr = GetComponent<LineRenderer>();
        anim = GetComponent<Animator>();
        walkBlend = 0.7f;
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = new Color(1, 0, 0, 0.24f);
        Gizmos.DrawSphere(rayPoint.position, 0.25f);
        Gizmos.color = wallIsDetected ? new Color(1, 0, 0, 0.24f): new Color(0, 1, 0, 0.24f);
        Gizmos.DrawLine(rayPoint.position, rayPoint.position + rayPoint.forward * maxRayDist);

        Gizmos.DrawCube(startClimbingTarget, 0.25f * Vector3.one);
        if (wallIsDetected)
        {
            Gizmos.DrawSphere(hitPoint, 0.25f);
        }

    }
    bool isTesting;
    public float offest;
    public Vector3 startClimbingTarget;
    public float rotationSpeedX ,movementSpeedX;
    public float angleThreshold,distanceThreshold;
    public bool isclimbing;
    public float animationBlendSpeed = 1f;
    private void OnEnable()
    {
        
    }
    [Button]
    public void test()
    {
        if (!isTesting)
        {
            isTesting = true;
            startClimbingTarget = target.position -target.forward* offest;
            startClimbingTarget.y = transform.position.y;
            anim.SetBool("isDancing", true);
            walkBlend = 0f;
        }

        if (target)
        {

            Vector3 lookPos = target.position - transform.position;
            lookPos.y = 0; // This removes the vertical difference between the objects
            Quaternion targetRotation = Quaternion.LookRotation(lookPos);
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, Time.deltaTime * rotationSpeedX);
            var currentAngle = Quaternion.Angle(transform.rotation, targetRotation);
           
            
            if (angleThreshold > currentAngle)
            {
                walkBlend += Time.deltaTime * animationBlendSpeed;
               
                anim.SetLayerWeight(1, walkBlend);
                anim.SetBool("isWalking", true);
                
                
                var nextpos = Vector3.Slerp(transform.position, startClimbingTarget, Time.deltaTime * movementSpeedX);
                nextpos.y = transform.position.y;
                transform.position = nextpos;
                var currentDist = Vector3.Distance(transform.position, startClimbingTarget);
                Debug.Log(currentDist);
                if (currentDist < distanceThreshold)
                {
                    isTesting = false;
                    isclimbing = true;
                }

            }
        }
        
    }

    // Update is called once per frame
    void Update()
    {
        if (isTesting)
        {
            test();
            return;
        }

        else if (!isclimbing) return;
       
        if(lr && debugSphere)
        {
            lr.SetPosition(0, rayPoint.position);
            lr.SetPosition(1, debugSphere.position);
        }
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
            hitPoint = hito.point;
            startpos = transform.position;
            debugSphere.position = hitPoint;
            Vector3 forward = transform.up - hito.normal* Vector3.Dot(transform.up, hito.normal);
            targetRotation= Quaternion.LookRotation(forward, hito.normal);
            startRotation = transform.rotation;
             
        }
        else if(wallIsDetected)
        {
            speed = maxSpeed/speedMultiplier;
            transform.rotation = Quaternion.Slerp(startRotation, targetRotation, roationDelta);
          
            roationDelta += Time.deltaTime*rotationSpeed;
            if (adjustPosition)
            {

                transform.position = Vector3.Lerp(startpos, hitPoint, positionDelta) + transform.forward * speed;
                positionDelta += Time.deltaTime * positionSpeed;

                if (positionDelta > 1)
                    adjustPosition = false;

            }
            if (roationDelta>1)
            {
                
                positionDelta = 0;
                
                hitPoint.x = startpos.x;
                hitPoint.z = startpos.z;
                
                roationDelta = 0;
                wallIsDetected = false;
                speed =maxSpeed;
            }

        }
        
        else
            debugSphere.position = rayPoint.position+rayPoint.forward*maxRayDist;
    }
}
