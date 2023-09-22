using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MikasaController : MonoBehaviour
{
    // Start is called before the first frame update
    public Transform modelTransform, feetTransform;
    public Vector3 positionOffset { get { return feetTransform? -transform.InverseTransformPoint(feetTransform.position):Vector3.zero; } set { } }
    public Animator anim;

    public Vector3 test;
    public AudioSource audioSource;

    
    
    public void PlayAudioClip(AudioClip newClip)
    {
        if(audioSource)
        {
            audioSource.Stop();
            audioSource.clip = newClip;
            audioSource.Play();
           
        }
    }
    private IEnumerator Start()
    {
        yield return new WaitForSeconds(1f);
        anim = GetComponent<Animator>();
        
        resetPosition();

    }

    
    public void OnPlayerTouch()
    {
        anim = GetComponent<Animator>();
        if (anim )
        {
            anim.SetTrigger("touch");
        }
    }

    public void resetPosition()
    {
        transform.localPosition = Vector3.zero;
        transform.localRotation = Quaternion.identity;
        transform.localScale = Vector3.one;
        var oldParent = transform.parent;
        Vector3 oldPos = transform.position;
        modelTransform.parent= null;
        transform.parent = feetTransform;
        transform.localPosition = Vector3.zero;
        transform.parent = oldParent;
        modelTransform.parent = transform;
        transform.position = oldPos;
        
    }
    // Update is called once per frame
    void Update()
    {
        test = positionOffset;
        if (Input.GetKeyDown(KeyCode.Space))
        {
            resetPosition();
        }

    }
}
