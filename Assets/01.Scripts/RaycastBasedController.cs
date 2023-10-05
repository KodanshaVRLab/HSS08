using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class RaycastBasedController : MonoBehaviour
{
    public float maxHeight;
    public Transform  origin;
    public float heigthAdjustmentSpeed=3f;
    public  float goal;

    Vector3 feetPos;   
     
    public LayerMask layerMask;

    [ReadOnly]
    public string currentHitName;
    [ReadOnly]
    public bool hasHit;
    public bool raycastSystemEnabled;
    public LineRenderer debugLine;

    public bool useTransformUP=true;
    public Transform target,ControlledTransform;
    Vector3 direction;


    // Start is called before the first frame update
    void Start()
    {
        if (!origin)
            origin = transform;

       
        if(!ControlledTransform)
        {
            ControlledTransform = transform;
        }
       
        
        raycastSystemEnabled = true;
    }


    // Update is called once per frame
    void Update()
    {
        if (useTransformUP)
        {
            direction =  origin.position - ControlledTransform.up*maxHeight;
        }
        else
        {
            direction = (target.position - origin.position);
        }

        if (!raycastSystemEnabled)
            return;
        Ray r = new Ray(origin.position,direction );
        RaycastHit outHit;
        if (Physics.Raycast(r, out outHit, maxHeight,layerMask))
        {
            currentHitName = outHit.transform.name;
            hasHit = true;
            feetPos = outHit.point;
            
             
           
            

        }
        else 
        {
            hasHit = false;
            currentHitName = "None";
            feetPos = direction;
            
            
            
        }
        Debug.DrawLine(origin.position, feetPos);

        if (debugLine)
        {
            debugLine.SetPosition(0, origin.position);
            debugLine.SetPosition(1, feetPos);
        }


       // goal = feetPos.y + maxHeight + headOffset;
         //transform.position = new Vector3(transform.position.x, Mathf.Lerp(transform.position.y,goal, Time.deltaTime*heigthAdjustmentSpeed),transform.position.z);
        
        
    }

    internal void tryGoToPosition()
    {
        if(hasHit)
        StartCoroutine(LerpToHitPosition());
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.yellow;
        Gizmos.DrawCube(feetPos, 0.2f * Vector3.one);

        Gizmos.DrawCube(origin.position, 0.2f * Vector3.one);

    }

    [Button]
    public void goToHitPosition()
    {
        if(hasHit)
            ControlledTransform.position = new Vector3(ControlledTransform.position.x, feetPos.y, ControlledTransform.position.z);
    }

    public IEnumerator LerpToHitPosition(float duration=3f)
    {
        Vector3 originalPos = ControlledTransform.position;
        var delta = 0f;
        while(duration>delta)
        {
            ControlledTransform.position = Vector3.Lerp(originalPos, new Vector3(ControlledTransform.position.x, feetPos.y, ControlledTransform.position.z), delta);
            yield return new WaitForEndOfFrame();
            delta += Time.deltaTime;
        }
        ControlledTransform.position = Vector3.Lerp(originalPos, new Vector3(ControlledTransform.position.x, feetPos.y, ControlledTransform.position.z), 1f);

    }
    public Vector3 getCurrentHitPosition() => feetPos;

    public float getCurrentYPos() => feetPos.y;
}
