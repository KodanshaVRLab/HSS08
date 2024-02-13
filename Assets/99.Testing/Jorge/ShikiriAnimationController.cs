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
    // Start is called before the first frame update
    void Start()
    {
        anim = GetComponent<Animator>();
        walkBlend = 0.7f;
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = new Color(1, 0, 0, 0.24f);
        Gizmos.DrawSphere(rayPoint.position, 0.25f);
        Gizmos.color = wallIsDetected ? new Color(1, 0, 0, 0.24f): new Color(0, 1, 0, 0.24f);
        Gizmos.DrawLine(rayPoint.position, rayPoint.position + rayPoint.forward * maxRayDist);
        if (wallIsDetected)
        {
            Gizmos.DrawSphere(hitPoint, 0.25f);
        }

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
            hitPoint = hito.point;

           
            Vector3 forward = transform.up - hito.normal* Vector3.Dot(transform.up, hito.normal);
            targetRotation= Quaternion.LookRotation(forward, hito.normal);
            startRotation = transform.rotation;
             
        }
        else if(wallIsDetected)
        {
            speed = maxSpeed/speedMultiplier;
            transform.rotation = Quaternion.Slerp(startRotation, targetRotation, roationDelta);
          
            roationDelta += Time.deltaTime*rotationSpeed;
            if (roationDelta>1)
            {
                
                positionDelta = 0;
                startpos = transform.position;
                hitPoint.x = startpos.x;
                hitPoint.z = startpos.z;
                adjustPosition = true;
                roationDelta = 0;
                wallIsDetected = false;
                speed =maxSpeed;
            }

        }
        else if(adjustPosition)
        {
           /* transform.position = Vector3.Lerp(startpos, hitPoint, positionDelta) +transform.forward* speed;
            positionDelta += Time.deltaTime * positionSpeed;

            if(positionDelta>1)
                adjustPosition = false;*/

        }
    }
}
