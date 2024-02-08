using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Events;

public class JoanWallDetector : MonoBehaviour
{
    [SerializeField]
    private OVRSceneManager sceneManager = null;

    public UnityEvent<Vector3> wallFound = null;
    public UnityEvent<Quaternion> wallFound2 = null;

    [SerializeField]
    private float minWallWidth = 1.5f;

    private void Awake()
    {
        sceneManager.SceneModelLoadedSuccessfully += RoomLoaded;
    }

    private void RoomLoaded()
    {
        List<GameObject> suitableWalls = FindObjectsOfType<OVRSemanticClassification>()
                    .Where(c => c.Contains(OVRSceneManager.Classification.WallFace))
                    .Select(c => c.gameObject)
                    .Where(wall => CheckIfWallIsBigEnough(wall))
                    .ToList();

        float minDistance = float.MaxValue;
        GameObject closestWall = null;
        foreach (GameObject wall in suitableWalls)
        {
            float distance = Vector3.Distance(Camera.main.transform.position, wall.transform.position);
            if (distance < minDistance)
            {
                minDistance = distance;
                closestWall = wall;
            }
        }

        if (closestWall != null)
        {
            wallFound?.Invoke(closestWall.transform.position);
            wallFound2?.Invoke(closestWall.transform.rotation);
        }
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
}
