using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanWallPinner : MonoBehaviour
{
    [SerializeField]
    private GameObject objectToPin = null;
    [SerializeField]
    private float objectMinWidth = 1.5f;
    [SerializeField]
    private float objectWallMargin = 0.5f;
    [SerializeField]
    private float objectWallSeparation = 0.01f;
    [SerializeField]
    private Transform userHead = null;
    [SerializeField]
    private float heightOffset = 0f;

    [SerializeField]
    private bool flip = false;

    [Button]
    public void PinToWall(GameObject wall)
    {
        if (wall == null)
        {
            Debug.LogError($"PinToWall failed: given wall is NULL!");
            return;
        }

        PinToWall(objectToPin.transform, wall);
    }

    [Button]
    public void PinToWall(Transform objectToPin, GameObject wall)
    {
        Transform wallTransform = wall.transform;
        Vector3 position = GetWallBestPosition(wallTransform);
        Quaternion rotation = GetWallRotation(wallTransform);
        objectToPin.transform.SetPositionAndRotation(position, rotation);
    }

    private Vector3 GetWallBestPosition(Transform wallTransform)
    {
        float wallHalfWidth = GetWallHalfWidth(wallTransform.gameObject);
        Vector3 wallRight = wallTransform.right;
        Vector3 wallForward = wallTransform.forward;
        Vector3 userForward = userHead.forward;

        Vector2 wallPosition2D = new Vector2(wallTransform.position.x, wallTransform.position.z);
        Vector2 wallRight2D = new Vector2(wallRight.x, wallRight.z);
        Vector2 userPosition2D = new Vector2(userHead.position.x, userHead.position.z);
        //Vector2 userForward2D = new Vector2(userForward.x, userForward.z);
        Vector2 wallForward2D = new Vector2(wallForward.x, wallForward.z);

        Vector2 crossPoint = GetCrossPoint2D(wallPosition2D, wallRight2D, userPosition2D, wallForward2D);

        Vector2 wallToCrossPosition2D = wallPosition2D - crossPoint;
        float distanceFromWallCenter = wallToCrossPosition2D.magnitude;
        float dot = Vector2.Dot(wallToCrossPosition2D, wallRight2D);
        if (dot > 0f)
        {
            distanceFromWallCenter = -distanceFromWallCenter;
        }
        float objectHalfWidth = objectMinWidth * 0.5f;
        float limit = Mathf.Max(wallHalfWidth - objectHalfWidth - objectWallMargin, 0f);
        float clampedDistance = Mathf.Clamp(distanceFromWallCenter, -limit, limit);

        Vector2 bestPosition2D = wallPosition2D + wallRight2D * clampedDistance;

        Debug.Log($"WallPinner: distance {distanceFromWallCenter} => clamped {clampedDistance} [{-limit}, {limit}]");
        Debug.Log($"WallPinner: cross point {crossPoint} => best position {bestPosition2D}");

        float bestY = userHead.position.y + heightOffset;
        Vector3 bestPosition = new Vector3(bestPosition2D.x, bestY, bestPosition2D.y);
        
        bestPosition += wallTransform.forward * objectWallSeparation;

        return bestPosition;
    }

    private float GetWallHalfWidth(GameObject wallFace)
    {
        OVRScenePlane scenePlane = wallFace.GetComponentInChildren<OVRScenePlane>();
        return scenePlane.Dimensions.x * 0.5f;
    }

    public Vector2 GetWallSize(GameObject wallFace)
    {
        OVRScenePlane scenePlane = wallFace.GetComponentInChildren<OVRScenePlane>();
        return scenePlane.Dimensions;
    }

    [Button]
    private Vector2 GetCrossPoint2D(Vector2 pointA, Vector2 vectorA, Vector2 pointB, Vector2 vectorB)
    {
        if ((vectorA.x == 0f && vectorB.x == 0f)
            || (vectorA.y == 0f && vectorB.y == 0f)
            || (vectorA.x == vectorB.x && vectorA.y == vectorB.y))
        {
            return Vector2.zero;
        }

        if (vectorA.x == 0f)
        {
            float a = vectorB.y / vectorB.x;
            float b = pointB.y - pointB.x * a;

            float x = pointA.x;
            float y = a * x + b;
            return new Vector2(x, y);
        }
        else if (vectorA.y == 0f)
        {
            float a = vectorB.x / vectorB.y;
            float b = pointB.x - pointB.y * a;

            float y = pointA.y;
            float x = a * y + b;
            return new Vector2(x, y);
        }
        else if (vectorB.x == 0f)
        {
            float a = vectorA.y / vectorA.x;
            float b = pointA.y - pointA.x * a;

            float x = pointB.x;
            float y = a * x + b;
            return new Vector2(x, y);
        }
        else if (vectorB.y == 0f)
        {
            float a = vectorA.x / vectorA.y;
            float b = pointA.x - pointA.y * a;

            float y = pointB.y;
            float x = a * y + b;
            return new Vector2(x, y);
        }
        else
        {
            float aA = vectorA.y / vectorA.x;
            float bA = pointA.y - pointA.x * aA;

            float aB = vectorB.y / vectorB.x;
            float bB = pointB.y - pointB.x * aB;

            float x = (bB - bA) / (aA - aB);
            float y = x * aA + bA;

            return new Vector2(x, y);
        }
    }

    private Quaternion GetWallRotation(Transform wallTransform)
    {
        Vector3 wallForward = wallTransform.forward;
        wallForward.y = 0f;
        Quaternion rotation = Quaternion.LookRotation(wallForward, Vector3.up);
        if (flip)
        {
            rotation *= Quaternion.Euler(0f, 180f, 0f);
        }
        return rotation;
    }
}
