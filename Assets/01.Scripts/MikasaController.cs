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


    public bool isCharacterPlaced;
    public Transform currentParent;
   
    public enum State
    {
        animating=0,
        editing=1
    }
    public State currentState = State.animating;

    public void updateState(State newState)
    {
        currentState = newState;
    }
    /// <summary>
    /// update the current state of mikasa
    /// </summary>
    /// <param name="newState"> 0 animating, 1 Editing</param>
    public void updateState(int newState)
    {
        currentState = (State)newState;
    }
    public void toggleState()
    {
        updateState(currentState == State.editing ? 0 : 1);
    }
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
       
        anim = GetComponentInChildren<Animator>();
        
        yield return new WaitForSeconds(1f);
        resetPosition(transform.parent,false);

    }

    
    public void OnPlayerTouch()
    {
        anim = GetComponentInChildren<Animator>();
        if (anim )
        {
            anim.SetTrigger("touch");
        }
    }

    public void resetPosition(Transform newParent, bool placingCharacter)
    {
        currentParent = newParent;
        transform.parent = currentParent;
        transform.localPosition = Vector3.zero;
        transform.localRotation = Quaternion.identity;
        transform.localScale = Vector3.one;
         
        
        
        Vector3 oldPos = transform.position;
        modelTransform.parent= null;
        transform.parent = feetTransform;
        transform.localPosition = Vector3.zero;
        transform.parent = newParent;
        modelTransform.parent = transform;
        transform.position = oldPos;
        isCharacterPlaced = placingCharacter;
        
    }
    // Update is called once per frame
    void Update()
    {
        test = positionOffset;
        if (Input.GetKeyDown(KeyCode.Space))
        {
            OnPlayerTouch();
        }

    }
}
