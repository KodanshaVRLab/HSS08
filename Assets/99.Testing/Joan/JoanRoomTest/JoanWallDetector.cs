using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Events;

public class JoanWallDetector : MonoBehaviour
{
    [SerializeField]
    private OVRSceneManager sceneManager = null;
    [SerializeField]
    private Transform userHead = null;

    [SerializeField]
    private float minWallWidth = 1.5f;

    [Button]
    public GameObject GetFrontWall()
    {
        List<GameObject> suitableWalls = GetSuitableWalls();
        GameObject frontWall = GetFrontestWall(suitableWalls);
        return frontWall;
    }

    public List<GameObject> GetSuitableWalls()
    {
        return FindObjectsOfType<OVRSemanticClassification>()
                    .Where(c => c.Contains(OVRSceneManager.Classification.WallFace))
                    .Select(c => c.gameObject)
                    .Where(wall => IsWallBigEnough(wall))
                    .ToList();
    }

    private bool IsWallBigEnough(GameObject wall)
    {
        Vector2 wallSize = GetWallBounds(wall);
        Debug.Log($"Wall {wall.name}'s size: {wallSize}");
        return wallSize.x >= minWallWidth;
    }

    private Vector2 GetWallBounds(GameObject wallFace)
    {
        OVRScenePlane scenePlane = wallFace.GetComponentInChildren<OVRScenePlane>();
        return scenePlane.Dimensions;
    }

    public GameObject GetClosestWall()
    {
        List<GameObject> walls = GetSuitableWalls();

        GameObject closestWall = null;
        float minDistance = float.MaxValue;

        foreach (GameObject wall in walls)
        {
            float distance = Vector3.Distance(userHead.position, wall.transform.position);
            if (distance < minDistance)
            {
                minDistance = distance;
                closestWall = wall;
            }
        }

        return closestWall;
    }

    private GameObject GetFrontestWall(List<GameObject> walls)
    {
        GameObject bestWall = null;

        float maxDotProduct = -float.MaxValue;
        Vector3 userFrontDirection = GetUserFrontDirection();
        foreach (GameObject wall in walls)
        {
            Vector3 wallPostion = wall.transform.position;
            Vector3 userToWall = GetUserToWallDirection(wallPostion);

            float dotProduct = Vector3.Dot(userFrontDirection, userToWall);
            if (dotProduct > maxDotProduct)
            {
                maxDotProduct = dotProduct;
                bestWall = wall;
            }
        }

        return bestWall;
    }

    private Vector3 GetUserFrontDirection()
    {
        Vector3 vector = userHead.transform.forward;
        vector.y = 0f;
        Vector3 direction = vector.normalized;
        return direction;
    }
    private Vector3 GetUserToWallDirection(Vector3 wallPosition)
    {
        Vector3 vector = wallPosition - userHead.position;
        vector.y = 0f;
        Vector3 direction = vector.normalized;
        return direction;
    }

    public List<GameObject> GetWallsClockwiseFromFrontest()
    {
        List<GameObject> suitableWalls = GetSuitableWalls();
        List<(int, float)> indexAnglePairs = new List<(int, float)>();

        Debug.Log($"User pos: {userHead.position}");
        Debug.Log($"Suitable walls:");
        for (int i = 0; i < suitableWalls.Count; ++i)
        {
            GameObject wall = suitableWalls[i];
            float angle = GetWallAngle(wall);
            float clockwiseAngle = -angle;
            indexAnglePairs.Add((i, clockwiseAngle));

            Debug.Log($"Wall {i}: '{wall.name}', pos {wall.transform.position}, angle {angle}");
        }
        Debug.Log($"> end");

        indexAnglePairs.Sort((a, b) => a.Item2.CompareTo(b.Item2));

        int startIndex = 0;
        float minAngle = float.MaxValue;
        Debug.Log($"Sorted walls:");
        for (int i = startIndex; i < indexAnglePairs.Count; ++i)
        {
            (int, float) indexAnglePair = indexAnglePairs[i];
            float angle = indexAnglePair.Item2;
            float absAngle = Mathf.Abs(angle);
            if (absAngle < minAngle)
            {
                minAngle = absAngle;
                startIndex = i;
            }
            
            GameObject wall = suitableWalls[indexAnglePair.Item1];
            Debug.Log($"Wall {i}: '{wall.name}', pos {wall.transform.position}, angle {angle}");
        }
        Debug.Log($"> end");
        Debug.Log($"Start Index");

        List<GameObject> walls = new List<GameObject>();
        for (int i = startIndex; i < indexAnglePairs.Count; ++i)
        {
            (int, float) indexAnglePair = indexAnglePairs[i];
            int index = indexAnglePair.Item1;
            walls.Add(suitableWalls[index]);
        }
        for (int i = 0; i < startIndex; ++i)
        {
            (int, float) indexAnglePair = indexAnglePairs[i];
            int index = indexAnglePair.Item1;
            walls.Add(suitableWalls[index]);
        }

        return walls;
    }

    private float GetWallAngle(GameObject wall)
    {
        Vector3 userFrontDirection = GetUserFrontDirection();
        Vector3 wallPostion = wall.transform.position;
        Vector3 userToWall = GetUserToWallDirection(wallPostion);

        Vector2 userForward2D = new Vector2(userFrontDirection.x, userFrontDirection.z).normalized;
        Vector2 userToWall2D = new Vector2(userToWall.x, userToWall.z).normalized;

        float angle = Vector2.SignedAngle(userForward2D, userToWall2D);
        float normalizedAngle = NormalizeAngle180(angle);
        return normalizedAngle;
    }

    [Button]
    private float NormalizeAngle180(float angle)
    {
        float angleSign = Mathf.Sign(angle);
        float loopedAngle = Mathf.Repeat(Mathf.Abs(angle), 360f);

        float loopedSignedAngle = loopedAngle * angleSign;

        float normalizedAngle = loopedSignedAngle;
        if (loopedSignedAngle > 180f)
        {
            normalizedAngle = loopedSignedAngle - 360f;
        }
        else if (loopedSignedAngle < -180f)
        {
            normalizedAngle = 360 + loopedSignedAngle;
        }

        return normalizedAngle;
    }

    public Transform FetchRandomWall()
    {
        List<GameObject> suitableWalls = GetSuitableWalls();
        if (suitableWalls.Count == 0)
        {
            return null;
        }

        int randomWallIndex = Random.Range(0, suitableWalls.Count);
        return suitableWalls[randomWallIndex].transform;
    }

    public Transform FetchFrontWall()
    {
        List<GameObject> suitableWalls = GetSuitableWalls();

        GameObject bestWall = GetFrontestWall(suitableWalls);

        if (bestWall != null)
        {
            return bestWall.transform;
        }
        else
        {
            Debug.LogError($"No wall found!");
        }
        return null;
    }
}