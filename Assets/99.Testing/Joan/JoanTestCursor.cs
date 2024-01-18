using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanTestCursor : OVRCursor
{
    [SerializeField]
    private LineRenderer lineRenderer = null;

    private void Awake()
    {
        lineRenderer.SetPositions(new Vector3[] { Vector3.zero, Vector3.zero });
    }

    public override void SetCursorRay(Transform ray)
    {
        lineRenderer.transform.SetPositionAndRotation(ray.position, ray.rotation);
    }

    public override void SetCursorStartDest(Vector3 start, Vector3 dest, Vector3 normal)
    {
        Debug.Log($"SetCursor: {start} => {dest} ({normal})");
        lineRenderer.SetPosition(0, start);
        lineRenderer.SetPosition(1, dest);
    }
}
