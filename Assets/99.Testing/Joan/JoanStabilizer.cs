using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanStabilizer : MonoBehaviour
{
    [SerializeField]
    private int maxSamples = 10;

    private Vector3 startPositionOffset = Vector3.zero;
    private Quaternion startRotationOffset = Quaternion.identity;

    private readonly List<Vector3> lastPositions = new List<Vector3>();
    private readonly List<Quaternion> lastRotations = new List<Quaternion>();

    private int nextIndex = 0;

    private void Awake()
    {
        startPositionOffset = transform.localPosition;
        startRotationOffset = transform.localRotation;

        InitializeLastSamples();
    }

    [Button]
    private void InitializeLastSamples()
    {
        lastPositions.Clear();
        Vector3 parentPosition = transform.parent.position;
        for (int i = 0; i < maxSamples; i++)
        {
            lastPositions.Add(parentPosition);
        }

        lastRotations.Clear();
        Quaternion parentRotation = transform.parent.rotation;
        for (int i = 0; i < maxSamples; i++)
        {
            lastRotations.Add(parentRotation);
        }
    }

    private void Update()
    {
        if (nextIndex >= maxSamples)
        {
            nextIndex = 0;
        }

        UpdatePosition();
        UpdateRotation();

        nextIndex++;
    }

    private void UpdatePosition()
    {
        lastPositions[nextIndex] = transform.parent.position;
        Vector3 meanParentPosition = GetParentMeanPosition();
        transform.position = meanParentPosition + startPositionOffset;
    }

    private Vector3 GetParentMeanPosition()
    {
        Vector3 meanPosition = Vector3.zero;
        foreach (Vector3 position in lastPositions)
        {
            meanPosition += position;
        }
        meanPosition /= maxSamples;
        return meanPosition;
    }

    private void UpdateRotation()
    {
        lastRotations[nextIndex] = transform.parent.rotation;
        Quaternion meanParentRotation = GetParentMeanRotation();
        transform.rotation = meanParentRotation * startRotationOffset;
    }

    private Quaternion GetParentMeanRotation()
    {
        Vector4 addedRotation = Vector4.zero;
        Quaternion meanRotation = Quaternion.identity;
        int added = 0;
        foreach (Quaternion rotation in lastRotations)
        {
            added++;
            float addF = 1f / added;

            addedRotation.x += rotation.x;
            addedRotation.y += rotation.y;
            addedRotation.z += rotation.z;
            addedRotation.w += rotation.w;

            Vector4 rotationValues = new Vector4(addedRotation.x, addedRotation.y, addedRotation.z, addedRotation.w) * addF;
            float D = 1f / Mathf.Sqrt(rotationValues.x * rotationValues.x + rotationValues.y * rotationValues.y + rotationValues.z * rotationValues.z + rotationValues.w * rotationValues.w);
            rotationValues *= D;

            meanRotation = new Quaternion(rotationValues.x, rotationValues.y, rotationValues.z, rotationValues.w);
        }

        return meanRotation;
    }
}
