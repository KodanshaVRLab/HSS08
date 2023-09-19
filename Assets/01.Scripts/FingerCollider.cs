using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FingerCollider : MonoBehaviour
{

    public float maxLaserDistance=3f;
    public Transform mikasa;
    LineRenderer lr;

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
        lr.SetPosition(1, transform.position - transform.right* maxLaserDistance);
    }

    public Vector3 getLaserPointingPoint() => lr ? lr.GetPosition(1) : Vector3.zero;

    public void setMikasaPosition()
    {
         
        if(mikasa)
        {
            mikasa.position = getLaserPointingPoint();
        }
    }
}
