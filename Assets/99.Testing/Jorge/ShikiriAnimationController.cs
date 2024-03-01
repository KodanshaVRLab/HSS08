using KVRL.HSS08.Testing;
using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class ShikiriAnimationController : MonoBehaviour
{
    public Animator anim;
    public float maxSpeed = 0.05f;
    public float speedMultiplier = 0.5f;
    [Range(0f, 1f)]
    public float walkBlend;
    public float speed = 0.1f;
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
    Vector3 hitPoint, startpos, hitPointOffset;
    public bool adjustPosition;
    public Transform debugSphere;
    LineRenderer lr;

    public Transform target;

    int currentMarkerIndex = 0;

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
        Gizmos.color = wallIsDetected ? new Color(1, 0, 0, 0.24f) : new Color(0, 1, 0, 0.24f);
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
    public float rotationSpeedX, movementSpeedX;
    public float angleThreshold, distanceThreshold;
    public bool isclimbing;
    public float animationBlendSpeed = 1f;

    public bool isinCorrectWall;

    public List<MarkerSnapToSurface> markers;
    MarkerSnapToSurface currentMarker;


    public LayerMask wallsLayer;

    public Transform currentWall;

    public float getCurrentFeetPosition()
    {       
            RaycastHit hit;
            if (Physics.Raycast(transform.position + transform.up * 0.5f, -transform.up, out hit, 3f, wallsLayer))
            {
                return hit.point.y;
            }

        return transform.position.y;
            
        
    }

    public Vector3 getCurrentSurfaceNormal()
    {
        RaycastHit hit;
        if (Physics.Raycast(transform.position + transform.up * 0.5f, -transform.up, out hit, 3f, wallsLayer))
        {
            Debug.Log("current normal " + hit.normal);
            return hit.normal;
        }
        return transform.up;
    }
    [Button]
    public Transform getcurrentWall()
    {
        RaycastHit hit;
        if (Physics.Raycast(transform.position+transform.up*0.5f, -transform.up, out hit, 3f, wallsLayer))
        {
            return hit.transform;
        }
        return null;
    }
    private void OnEnable()
    {
        var sceneMarkers = FindObjectsOfType<MarkerSnapToSurface>();
        markers = sceneMarkers.OrderBy(obj => Vector3.Distance(obj.transform.position, transform.position)).ToList();
        if (currentMarkerIndex < markers.Count)
            currentMarker = markers[currentMarkerIndex];
    }
    [Button]
    public void GoToStartPosition()
    {
        Debug.Log("Going to start point");
        if (!isTesting)
        {          
            if (currentMarker)
            {
                target = currentMarker.transform;
                isTesting = true;
                startClimbingTarget =  currentMarker.CheckCollisionAndGetHitPoint(target.position - target.forward * offest,getcurrentWall(),100);

               
                anim.SetBool("isDancing", true);
                walkBlend = 0f;
            }
        }

        if (target)
        {
            Vector3 lookPos = target.position - transform.position;
            if (transform.up == Vector3.up )
                lookPos.y = 0; // This removes the vertical difference between the objects
            else
             lookPos.z = 0;
            Quaternion targetRotation = Quaternion.LookRotation(lookPos,getCurrentSurfaceNormal());
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, Time.deltaTime * rotationSpeedX);
            var currentAngle = Quaternion.Angle(transform.rotation, targetRotation);
           
            
            if (angleThreshold > currentAngle)
            {
                walkBlend = Mathf.Clamp01(walkBlend+ Time.deltaTime * animationBlendSpeed);
               
                anim.SetLayerWeight(1, walkBlend);
                anim.SetBool("isWalking", true);
                
                
                var nextpos = Vector3.Slerp(transform.position, startClimbingTarget, Time.deltaTime * movementSpeedX);
               
                transform.position = nextpos;
                var c = transform.localPosition;
                c.y = getCurrentFeetPosition();

                transform.localPosition = c;
                
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
    public void goToTargetPoint()
    {
        Debug.Log("Going to start Marker");
        var targetPos = markers.Count > 0 ? currentMarker.GetSnapPoint() : target.position;
        
        var nextpos = Vector3.Slerp(transform.position, targetPos, Time.deltaTime * movementSpeedX);
        
        transform.position = nextpos;
        var currentDist = Vector3.Distance(transform.position, currentMarker.GetSnapPoint());
        Debug.Log(currentDist);
        if (currentDist < distanceThreshold/2f)
        {
            walkBlend = 0f;
            anim.SetLayerWeight(1, walkBlend);
            anim.SetBool("isWalking", false);
            StartCoroutine(waitAndDance());
            isinCorrectWall = false;
        }
    }
    public IEnumerator waitAndDance()
    {
        anim.SetBool("isDancing", true);
        yield return new WaitForSeconds(5f);
        currentMarkerIndex++;
        if (currentMarkerIndex < markers.Count)
            currentMarker = markers[currentMarkerIndex];
        GoToStartPosition();

    }

    // Update is called once per frame
    void Update()
    {
        currentWall= getcurrentWall();
        if (isTesting)
        {
            GoToStartPosition();
            return;
        }
        else if (isinCorrectWall)
        {
            goToTargetPoint();
        }
        else if (isclimbing)
        {
            tryClimbWall();
        }
        
    }

    private void tryClimbWall()
    {
        Debug.Log("Climbing Wall");
        if (lr && debugSphere)
        {
            lr.SetPosition(0, rayPoint.position);
            lr.SetPosition(1, debugSphere.position);
        }
        if (anim)
        {
            anim.SetBool("isDancing", isDancing);
            anim.SetBool("isWalking", isWalking);

            anim.SetLayerWeight(1, walkBlend);

            transform.position += transform.forward * speed;
        }
        Ray r = new Ray(rayPoint.position, rayPoint.forward);
        RaycastHit hito;

        if (!wallIsDetected && Physics.Raycast(r, out hito, maxRayDist, lm))
        {

            wallIsDetected = true;
            hitPoint = hito.point;
            startpos = transform.position;
            debugSphere.position = hitPoint;
            Vector3 forward = transform.up - hito.normal * Vector3.Dot(transform.up, hito.normal);
            targetRotation = Quaternion.LookRotation(forward, hito.normal);
            startRotation = transform.rotation;

        }
        else if (wallIsDetected)
        {
            speed = maxSpeed / speedMultiplier;
            transform.rotation = Quaternion.Slerp(startRotation, targetRotation, roationDelta);

            roationDelta += Time.deltaTime * rotationSpeed;
            if (adjustPosition)
            {

                transform.position = Vector3.Lerp(startpos, hitPoint, positionDelta) + transform.forward * speed;
                positionDelta += Time.deltaTime * positionSpeed;

                if (positionDelta > 1)
                    adjustPosition = false;

            }
            if (roationDelta > 1)
            {

                positionDelta = 0;

                hitPoint.x = startpos.x;
                hitPoint.z = startpos.z;

                roationDelta = 0;
                wallIsDetected = false;
                speed = maxSpeed;

                isclimbing = false;
                isinCorrectWall = true;
            }

        }

        else
            debugSphere.position = rayPoint.position + rayPoint.forward * maxRayDist;
    }
}
