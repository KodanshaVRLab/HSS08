using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Events;

public class JoanCenterDetector : MonoBehaviour
{
    [SerializeField]
    private OVRSceneManager sceneManager = null;
    [SerializeField]
    private Transform userHead = null;
    [SerializeField]
    private float heightOffset = 0f;

    public UnityEvent<Vector3> centerFound = null;
    public UnityEvent<Vector3> bottomCenterFound = null;
    public UnityEvent<Quaternion> centerFound2 = null;

    private void Awake()
    {
        //sceneManager.SceneModelLoadedSuccessfully += DetectCenter;
    }

    public void DetectCenter()
    {
        List<GameObject> walls = FindObjectsOfType<OVRSemanticClassification>()
                    .Where(c => c.Contains(OVRSceneManager.Classification.WallFace))
                    .Select(c => c.gameObject)
                    .ToList();

        Debug.Log($"RoomLoaded successfully: walls detected {walls.Count}");

        Rect roomRect = new Rect();
        float floorY = 0f;
        foreach (GameObject wall in walls)
        {
            Vector3 wallCenter = wall.transform.position;
            Vector3 wallRight = wall.transform.right;
            Vector3 wallHalfSize = GetWallHalfSize(wall);
            float wallHalfWidth = wallHalfSize.x;

            Vector3 pointA = wallCenter - wallRight * wallHalfWidth;
            Vector3 pointB = wallCenter + wallRight * wallHalfWidth;

            float xmin = Mathf.Min(pointA.x, pointB.x);
            float xmax = Mathf.Max(pointA.x, pointB.x);
            float zmin = Mathf.Min(pointA.z, pointB.z);
            float zmax = Mathf.Max(pointA.z, pointB.z);

            roomRect.xMin = Mathf.Min(roomRect.xMin, xmin);
            roomRect.xMax = Mathf.Max(roomRect.xMax, xmax);
            roomRect.yMin = Mathf.Min(roomRect.yMin, zmin);
            roomRect.yMax = Mathf.Max(roomRect.yMax, zmax);

            floorY = pointA.y - wallHalfSize.y;
        }

        Vector3 userHeadPosition = userHead.transform.position;
        float yPosition = userHeadPosition.y + heightOffset;
        Vector3 center = new Vector3(roomRect.center.x, yPosition, roomRect.center.y);
        Vector3 direction = userHeadPosition - center;
        direction.y = 0f;
        Quaternion rotation = Quaternion.LookRotation(direction, Vector3.up);

        Debug.Log($"roomRect: {roomRect}, center {center}");

        centerFound?.Invoke(center);
        centerFound2?.Invoke(rotation);

        Vector3 bottomCenter = center;
        bottomCenter.y = floorY;
        bottomCenterFound?.Invoke(bottomCenter);
    }

    private Vector3 GetWallHalfSize(GameObject wallFace)
    {
        OVRScenePlane scenePlane = wallFace.GetComponentInChildren<OVRScenePlane>();
        return scenePlane.Dimensions * 0.5f;
    }
}
