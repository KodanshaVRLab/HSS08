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

    public float minDistance=0.3f;
    public float walkSpeed=0.1f;
    Vector3 nextTarget;

    public GameObject grabbableCollider;


    int lastAnimationState = 0;

    public Transform DistanceChecker;
    RaycastBasedController floorFinder;

    public TextMesh debugText;
    public LineRenderer debugLineRenderer;
    public enum State
    {
        animating = 0,
        editing = 1,
        walking =2
    }
    public State currentState = State.animating;

    public void ToggleGrabbaleObject(bool isOn= false)
    {
        if(grabbableCollider)
        {
            grabbableCollider.SetActive(isOn);
        }
    }

    public void updateState(State newState)
    {
        currentState = newState;
        switch (currentState)
        {
            case State.animating:
                updateAnimationState(lastAnimationState);
                break;
            case State.editing:
                updateAnimationState(0);
                break;
            case State.walking:
                updateAnimationState(3);
                break;
        }
        if (currentState == State.walking)
        {
            if (debugLineRenderer)
                debugLineRenderer.enabled = true;
        }
        else
        {
            if (debugLineRenderer)
                debugLineRenderer.enabled = false;

        }
    }
    /// <summary>
    /// update the current state of mikasa
    /// </summary>
    /// <param name="newState"> 0 animating, 1 Editing</param>
    public void updateState(int newState)
    {
        currentState = (State)newState;
        switch (currentState)
        {
            case State.animating:
                updateAnimationState(lastAnimationState);
                break;
            case State.editing:
                updateAnimationState(0);
                break;
            case State.walking:
                updateAnimationState(3);
                break;
        }
        if (currentState == State.walking)
        {
            if (debugLineRenderer)
                debugLineRenderer.enabled = true;
        }
        else
        {
            if (debugLineRenderer)
                debugLineRenderer.enabled = false;

        }
    }


    public void toggleState()
    {
        updateState(currentState == State.editing ? 0 : 1);
        if (currentState != State.editing && playerMG)
        {
            ToggleGrabbaleObject(false);
            

        }
        else
        {
            ToggleGrabbaleObject(true);
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

        if(!DistanceChecker)
        {
            DistanceChecker = transform;
        }

        floorFinder = GetComponent<RaycastBasedController>();

    }

    
    public  void WalkToPosition( Vector3 newDestination)
    {
        nextTarget = newDestination;
        Vector3 direction = newDestination - transform.position;
        direction.y = 0; // Ignore the Y component

        if (direction != Vector3.zero)
        {
            Quaternion lookRotation = Quaternion.LookRotation(direction);
            transform.rotation = Quaternion.Euler(0, lookRotation.eulerAngles.y, 0);
        }
        updateState(State.walking);
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
        
        if (anim)
        {
            lastAnimationState = anim.GetInteger("State");
            anim.SetInteger("State", newState);
        }
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
        if (floorFinder)
            floorFinder.goToFloorPosition();
    }
    // Update is called once per frame
    void Update()


    {
        test = positionOffset;
        if (Input.GetKeyDown(KeyCode.Space))
        {
            OnPlayerTouch();
        
        }
        if(currentState== State.walking)
        {
            

            if(Vector3.Distance(DistanceChecker.position,nextTarget )>minDistance)
            {
                if (floorFinder)
                    floorFinder.goToFloorPosition();
                transform.position += transform.forward * walkSpeed;
                if(debugText)
                {
                    debugText.text = Vector3.Distance(DistanceChecker.position, nextTarget) + ">"+minDistance;

                }
                if(debugLineRenderer)
                {
                    debugLineRenderer.SetPosition(0, DistanceChecker.position);
                    debugLineRenderer.SetPosition(1,nextTarget );
                }
            }
            else
            {
                updateState(State.animating);
                if (debugText)
                {
                    debugText.text ="in destination";

                }
            }
            
        }
        else
        {
            if (debugText)
            {
                debugText.text = "";

            }
        }

    }
}
