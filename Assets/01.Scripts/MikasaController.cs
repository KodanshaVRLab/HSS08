using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MikasaController : MonoBehaviour
{
    // Start is called before the first frame update
    public Transform cameraTransform;
    public Vector3 positionOffset;
    public Animator anim;

   
    private void Start()
    {
        anim = GetComponent<Animator>();
    }

    
    public void OnPlayerTouch()
    {
        if(anim )
        {
            anim.SetTrigger("touch");
        }
    }
    
    // Update is called once per frame
    void Update()
    {
        
    }
}
