using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class RaycastBasedController : MonoBehaviour
{
    public float maxHeight, headOffset;
    public Transform  headPos;
    public float heigthAdjustmentSpeed=3f;
    public  float goal;

    Vector3 feetPos;   
    bool useGravity;
    public LayerMask layerMask;

    [ReadOnly]
    public string currentHit;
    public bool raycastSystemEnabled;
    public LineRenderer debugLine;
    // Start is called before the first frame update
    void Start()
    {
        
        if(headPos)
        headOffset = transform.position.y - headPos.position.y;
        useGravity = false;
        raycastSystemEnabled = true;
    }


    // Update is called once per frame
    void Update()
    {

        if (!raycastSystemEnabled)
            return;
        Ray r = new Ray(headPos.position, (headPos.position-transform.up )- headPos.position );
        RaycastHit outHit;
        if (Physics.Raycast(r, out outHit, maxHeight,layerMask))
        {
            currentHit = outHit.transform.name;
            feetPos = outHit.point;
            useGravity = false;
             
           
            

        }
        else 
        {
            currentHit = "None";
            feetPos = headPos.position - transform.up * maxHeight;
            useGravity = true;
            
            
        }
        Debug.DrawLine(headPos.position, feetPos);

        if (debugLine)
        {
            debugLine.SetPosition(0, headPos.position);
            debugLine.SetPosition(1, feetPos);
        }


       // goal = feetPos.y + maxHeight + headOffset;
         //transform.position = new Vector3(transform.position.x, Mathf.Lerp(transform.position.y,goal, Time.deltaTime*heigthAdjustmentSpeed),transform.position.z);
        
        
    }
    private void OnDrawGizmos()
    {
        Gizmos.color = Color.yellow;
        Gizmos.DrawCube(feetPos, 0.2f * Vector3.one);

        Gizmos.DrawCube(headPos.position, 0.2f * Vector3.one);

    }

    [Button]
    public void goToFloorPosition()
    {
        if(currentHit!= "None")
        transform.position = new Vector3(transform.position.x, feetPos.y,transform.position.z);
    }
}
