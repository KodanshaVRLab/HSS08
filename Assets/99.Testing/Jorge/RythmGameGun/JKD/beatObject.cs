using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class beatObject : MonoBehaviour
{
    // Start is called before the first frame update
    float timealive = 0;
    void Start()
    {
        GetComponent<Renderer>().material.color = Color.green;
    }

    private void OnMouseDown()
    {
       
        GetComponent<Rigidbody>().AddForce(-transform.forward * 1000);
    }
    // Update is called once per frame
    void Update()
    {
        if(timealive<1f)
        timealive += Time.deltaTime;
        GetComponent<Renderer>().material.color = Color.Lerp(Color.green,Color.red,timealive);
    }
}
