using Sirenix.OdinInspector;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class MikasaController : MonoBehaviour
{
    // Start is called before the first frame update
    public Transform modelTransform, feetTransform;
    public Vector3 positionOffset { get { return feetTransform ? -transform.InverseTransformPoint(feetTransform.position) : Vector3.zero; } set { } }
    public Animator anim;

    public Vector3 test;
    public AudioSource audioSource;


    public bool isCharacterPlaced;
    public Transform currentParent;

    public UnityEvent onMikasaPlaced;
    public PlayerMG playerMG;

    public GameObject blobShadow;

    Vector3 originalScale;
    Quaternion originalRotation;
    Transform originalParent;
    RuntimeAnimatorController originalAnimator;

    public enum State
    {
        animating = 0,
        editing = 1
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
        if (currentState != State.editing && playerMG)
        {
            playerMG.disableGizmos();
            blobShadow.SetActive(false);
        }
        else
        {
            playerMG.enableGizmos();
            blobShadow.SetActive(true);
        }


    }
    public void PlayAudioClip(AudioClip newClip)
    {
        if (audioSource)
        {
            audioSource.Stop();
            audioSource.clip = newClip;
            audioSource.Play();

        }
    }
    private void Start()
    {

        anim = GetComponentInChildren<Animator>();
        originalScale = transform.localScale;
        originalRotation = transform.rotation;
        originalAnimator = anim ? anim.runtimeAnimatorController : null;
        originalParent = transform.parent;
        modelTransform.localPosition = Vector3.zero;
        modelTransform.localRotation = Quaternion.identity;


        resetPosition(transform.parent, false);


    }

    
    public  void WalkToPosition( Vector3 destination)
    {
        Vector3 direction = destination - transform.position;
        direction.y = 0; // Ignore the Y component

        if (direction != Vector3.zero)
        {
            Quaternion lookRotation = Quaternion.LookRotation(direction);
            transform.rotation = Quaternion.Euler(0, lookRotation.eulerAngles.y, 0);
        }
    }

    [Button]
    public  void WalkToPosition(Transform destinationTransform)
    {
        WalkToPosition(destinationTransform.position);
    }

    public void ResetScale()
    {
        transform.parent = originalParent;
        transform.rotation = originalRotation;
        if (anim) anim.SetInteger("State", 0);
        transform.localScale = originalScale;
    }
    public void OnPlayerTouch()
    {
        anim = GetComponentInChildren<Animator>();
        if (anim)
        {
            anim.SetTrigger("touch");
        }
    }
    public void updateAnimationState(int newState)
    {
        if (anim) anim.SetInteger("State", newState);
    }
    [Button]
    public void resetPosition(Transform newParent, bool placingCharacter)
    {
        currentParent = newParent;
        transform.parent = currentParent;
        transform.localPosition = Vector3.zero;
        transform.localRotation = Quaternion.identity;
        if (placingCharacter)
            transform.localScale = Vector3.one;



        Vector3 oldPos = transform.position;
        modelTransform.parent = null;
        transform.parent = feetTransform;
        transform.localPosition = Vector3.zero;
        transform.parent = newParent;
        modelTransform.parent = transform;
        transform.position = oldPos;
        isCharacterPlaced = placingCharacter;
        if (placingCharacter)
            onMikasaPlaced.Invoke();


    }
    public void setPosition(Vector3 position)
    {
        transform.position = position;
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
