using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class DebugPlayerController : MonoBehaviour
{
    public Transform cameraT;
    // Start is called before the first frame update
    void Start()
    {
        
    }
    public void OnLeftStick(InputAction.CallbackContext obj)
    {
        Vector2 x = obj.ReadValue<Vector2>();
        transform.position += cameraT.forward * x.y;
        transform.position += cameraT.right * x.x;
    }
    // Update is called once per frame
    void Update()
    {
        
    }
}
