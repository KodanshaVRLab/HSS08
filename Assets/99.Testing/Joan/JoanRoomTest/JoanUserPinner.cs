using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanUserPinner : MonoBehaviour
{
    [SerializeField]
    private Transform userHead = null;
    [SerializeField]
    private GameObject objectToPin = null;
    [SerializeField]
    private float distance = 1f;
    [SerializeField]
    private float heightOffset = 0f;

    public void PinObject()
    {
        Vector3 position = GetBestUserPosition();
        Quaternion rotation = GetBestUserRotation();
        objectToPin.transform.SetPositionAndRotation(position, rotation);
    }

    private Vector3 GetBestUserPosition()
    {
        Vector3 userHeadPosition = userHead.position;
        Vector3 forward = GetNormalizedUserForward();
        Vector3 bestUserPosition = userHeadPosition + forward * distance;
        bestUserPosition.y += heightOffset;
        return bestUserPosition;
    }

    private Quaternion GetBestUserRotation()
    {
        Vector3 objectToUserDirection = -GetNormalizedUserForward();
        Quaternion rotation = Quaternion.LookRotation(objectToUserDirection, Vector3.up);
        return rotation;
    }

    private Vector3 GetNormalizedUserForward()
    {
        Vector3 forward = userHead.forward;
        forward.y = 0f;
        forward.Normalize();
        return forward;
    }
}
