using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using static UnityEngine.InputSystem.InputAction;

public class InputMG: MonoBehaviour
{
    public UnityEvent onLeftTrigger, onRightTrigger;
    public void onRightTriggerPressed(CallbackContext context)
    {
        if(context.phase== UnityEngine.InputSystem.InputActionPhase.Performed)
        onRightTrigger.Invoke();
    }
    public void onLeftTriggerPressed(CallbackContext context)
    {
        if (context.phase == UnityEngine.InputSystem.InputActionPhase.Performed)
            onLeftTrigger.Invoke();
    }

}
