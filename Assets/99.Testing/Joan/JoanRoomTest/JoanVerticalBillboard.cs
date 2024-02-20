using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanVerticalBillboard : MonoBehaviour
{
    [SerializeField]
    private Transform target = null;

    private void Update()
    {
        UpdateRotation();
    }

    private void UpdateRotation()
    {
        Vector3 direction = target.position - transform.position;
        direction.y = 0f;
        direction.Normalize();

        if (direction == Vector3.zero)
        {
            direction = -target.forward;
            direction.y = 0f;
            direction.Normalize();
        }

        Quaternion newRotation = Quaternion.LookRotation(direction, Vector3.up);
        transform.rotation = newRotation;
    }
}
