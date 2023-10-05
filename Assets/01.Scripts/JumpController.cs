using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JumpController : MonoBehaviour
{
    public enum JumpState
    {
        idle,
        goingUp,
        startGoingDown,
        goingDown

    }
    public JumpState currentState;
    public float upSpeed = 0.005f;
    public float fwdSpeed = 0.005f;
    public Transform transformController;
    public Animator anim;
    bool isJumping;
    public RaycastBasedController jumpRaycastController;
    public float landingPosition;
    public MikasaController mkController;

    // Start is called before the first frame update
    void Start()
    {
        if (!transformController)
            transformController = transform;
        currentState = JumpState.idle;
    }

    // Update is called once per frame
    void Update()
    {
        if (isJumping)
            switch (currentState)
            {
                case JumpState.idle:
                    if (anim)
                        anim.SetInteger("State", 3);
                    isJumping = false;
                    break;
                case JumpState.goingUp:
                    transform.position += transformController.forward * fwdSpeed + transformController.up * upSpeed;
                    break;
                case JumpState.startGoingDown:

                    if (anim)
                        anim.SetInteger("State", 5);
                    goToPosition(landingPosition);
                    currentState = JumpState.goingDown;
                    //transform.position -= transformController.up * speed;
                    break;
            }
    }

    public void goToPosition(float pos)
    {
        StartCoroutine(LerpToHitPosition(pos));
    }
    public IEnumerator LerpToHitPosition(float ypos, float duration = 0.7f)
    {
        Vector3 originalPos = transformController.position;
        var delta = 0f;
        while (duration > delta)
        {
            transformController.position = Vector3.Lerp(originalPos, new Vector3(transformController.position.x, ypos, transformController.position.z), delta/duration);
            yield return new WaitForEndOfFrame();
            delta += Time.deltaTime;
        }
        transformController.position = Vector3.Lerp(originalPos, new Vector3(transformController.position.x, ypos, transformController.position.z), 1f);
        if(mkController)
        {
            mkController.updateState(MikasaController.State.walking);
        }
    }
    public void GoUp()
    {
        isJumping = true;
        print("Go Up");
        currentState = JumpState.goingUp;

    }
    public void GoDown()
    {
        print("Going Down");
        currentState = JumpState.startGoingDown;
    }
    public void EndJump()
    {
        print("Jump Ended");
        currentState = JumpState.idle;
    }
}
