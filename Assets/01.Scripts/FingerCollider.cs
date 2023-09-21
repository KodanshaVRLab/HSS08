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

    // Start is called before the first frame update
    void Start()
    {
        GetComponent<Renderer>().material.color = Color.green;
        lr = GetComponent<LineRenderer>();
    }
    private void OnTriggerEnter(Collider other)
    {
        GetComponent<Renderer>().material.color = Color.red;
        VRButton button;
        
        if (other.TryGetComponent<VRButton>(out button))
        {
            button.Click();
        }
        
        

    }
    private void OnTriggerExit(Collider other)
    {
        GetComponent<Renderer>().material.color = Color.green;
    }
    // Update is called once per frame
    void Update()
    {
        if (!lr) return;
        lr.SetPosition(0, transform.position);
        Ray r = new Ray(transform.position,transform.position-transform.right*maxLaserDistance);
       
        if(Physics.Raycast(r,out hito, maxLaserDistance, layerMask))
        {
            lr.SetPosition(1,hito.point );
            lr.material.color = Color.green;
            hasTarget = true;
        }
        else
        {
            lr.SetPosition(1, transform.position - transform.right * maxLaserDistance);
            lr.material.color = Color.red;
            hasTarget = false;
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
