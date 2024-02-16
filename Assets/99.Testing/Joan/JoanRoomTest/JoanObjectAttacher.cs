using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanObjectAttacher : MonoBehaviour
{
    [SerializeField]
    private Transform parent = null;
    [SerializeField]
    private Transform objectToPin = null;

    [SerializeField]
    private Vector3 pinnedOffset = Vector3.zero;
    [SerializeField]
    private Vector3 pinnedRotationOffset = Vector3.zero;

    private Transform prevParent = null;

    public void AttachObject()
    {
        prevParent = objectToPin.parent;
        objectToPin.SetParent(parent, false);

        Quaternion rotation = Quaternion.Euler(pinnedRotationOffset);
        objectToPin.SetLocalPositionAndRotation(pinnedOffset, rotation);
    }

    public void DettachObject()
    {
        objectToPin.SetParent(prevParent, false);
    }
}
