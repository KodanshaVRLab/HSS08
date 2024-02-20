using Meta.WitAi.Attributes;
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

    public UnityEvent<GameObject> onBestWallFound = null;
    public UnityEvent<Vector3> wallFound = null;
    public UnityEvent<Quaternion> wallFound2 = null;

    [SerializeField]
    private float minWallWidth = 1.5f;

    private void Awake()
    {
        //sceneManager.SceneModelLoadedSuccessfully += FindBestWall;
    }

    [Button]
    public void FindFrontWall()
    {
        List<GameObject> suitableWalls = FindObjectsOfType<OVRSemanticClassification>()
                    .Where(c => c.Contains(OVRSceneManager.Classification.WallFace))
                    .Select(c => c.gameObject)
                    .Where(wall => CheckIfWallIsBigEnough(wall))
                    .ToList();

        //Transform bestWallTransform = GetFrontestWall(suitableWalls);
        GameObject bestWall = GetFrontestWall(suitableWalls);

        if (bestWall != null)
        {
            onBestWallFound?.Invoke(bestWall);
            //wallFound?.Invoke(bestWallTransform.position);
            //wallFound2?.Invoke(bestWallTransform.rotation);
        }
        else
        {
            Debug.LogError($"No wall found!");
        }
    }
    public Transform FetchRandomWall()
    {
        List<GameObject> suitableWalls = FindObjectsOfType<OVRSemanticClassification>()
                   .Where(c => c.Contains(OVRSceneManager.Classification.WallFace))
                   .Select(c => c.gameObject)
                   .Where(wall => CheckIfWallIsBigEnough(wall))
                   .ToList();

        if (suitableWalls.Count == 0) return null;
        var Rand = Random.Range(0, suitableWalls.Count);
        return suitableWalls[Rand].transform;
    }
    public Transform FetchFrontWall()
    {
        List<GameObject> suitableWalls = FindObjectsOfType<OVRSemanticClassification>()
                    .Where(c => c.Contains(OVRSceneManager.Classification.WallFace))
                    .Select(c => c.gameObject)
                    .Where(wall => CheckIfWallIsBigEnough(wall))
                    .ToList();

        //Transform bestWallTransform = GetFrontestWall(suitableWalls);
        GameObject bestWall = GetFrontestWall(suitableWalls);

        if (bestWall != null)
        {
            onBestWallFound?.Invoke(bestWall);
            return bestWall.transform;
            //wallFound?.Invoke(bestWallTransform.position);
            //wallFound2?.Invoke(bestWallTransform.rotation);
        }
        else
        {
            Debug.LogError($"No wall found!");
        }
        return null;
    }
    private bool CheckIfWallIsBigEnough(GameObject wall)
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

    private Transform GetClosestWall(List<GameObject> walls)
    {
        GameObject bestWall = null;

        float minDistance = float.MaxValue;
        foreach (GameObject wall in walls)
        {
            float distance = Vector3.Distance(Camera.main.transform.position, wall.transform.position);
            if (distance < minDistance)
            {
                minDistance = distance;
                bestWall = wall;
            }
        }

        Transform bestWallTransform = bestWall != null
            ? bestWall.transform
            : null;
        return bestWallTransform;
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
}
