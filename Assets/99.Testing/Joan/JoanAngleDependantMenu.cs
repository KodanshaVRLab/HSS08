using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class JoanAngleDependantMenu : MonoBehaviour
{
    [System.Flags]
    private enum Axis
    {
        X = 1,
        Y = 1 << 1,
        Z = 1 << 2
    }

    private enum State
    {
        Open,
        Closed
    }

    [SerializeField, EnumToggleButtons]
    private Axis axisToCheck = 0;
    [SerializeField]
    private float minValue = 0.4f;

    public UnityEvent onOpen = null;
    public UnityEvent onClosed = null;

    [ShowInInspector, ReadOnly]
    private State state = State.Closed;

    private void FixedUpdate()
    {
        CalculateVisibility();
    }

    private void CalculateVisibility()
    {
        float currentValue = GetDotProduct();
        bool shouldBeOpen = currentValue > minValue;
        SetVisibility(shouldBeOpen);
    }

    private void SetVisibility(bool shouldBeOpen)
    {
        if (shouldBeOpen)
        {
            if (state == State.Closed)
            {
                Open();
            }
        }
        else
        {
            if (state == State.Open)
            {
                Close();
            }
        }
    }

    private void Open()
    {
        state = State.Open;
        onOpen?.Invoke();
    }

    private void Close()
    {
        state = State.Closed;
        onClosed?.Invoke();
    }

    private float GetDotProduct()
    {
        Vector3 normal = transform.forward;
        Vector3 fromCamera = transform.position - Camera.main.transform.position;
        
        if (!axisToCheck.HasFlag(Axis.X))
        {
            normal.x = 0f;
            fromCamera.x = 0f;
        }

        if (!axisToCheck.HasFlag(Axis.Y))
        {
            normal.y = 0f;
            fromCamera.y = 0f;
        }

        if (!axisToCheck.HasFlag(Axis.Z))
        {
            normal.z = 0f;
            fromCamera.z = 0f;
        }

        float angle = Vector3.Dot(normal.normalized, fromCamera.normalized);
        return angle;
    }
}
