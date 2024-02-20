using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanSpreadBetweenWallsPrototype : JoanPrototype
{
    [SerializeField]
    private List<RectTransform> menuRoots = new List<RectTransform>();
    [SerializeField]
    private JoanWallDetector wallDetector = null;
    [SerializeField]
    private JoanWallPinner wallPinner = null;
    [SerializeField]
    private float wallCoverageFactor = 0.75f;

    private List<GameObject> walls = new List<GameObject>();

    public override void Activate()
    {
        base.Activate();

        walls = wallDetector.GetWallsClockwiseFromFrontest();
        PinEachPartToEachWall();
    }

    private void PinEachPartToEachWall()
    {
        int menuIndex = 0;
        int wallCount = walls.Count;

        while (menuIndex < menuRoots.Count)
        {
            int wallIndex = menuIndex % wallCount;
            GameObject wall = walls[wallIndex];
            RectTransform menuRoot = menuRoots[menuIndex];

            wallPinner.PinToWall(menuRoot, wall);
            //ExpandRectToWall(menuRoot, wall);

            menuIndex++;
        }
    }

    private void ExpandRectToWall(RectTransform rectTransform, GameObject wall)
    {
        Vector2 wallSize = wallPinner.GetWallSize(wall);
        Vector3 rectSize = wallSize * wallCoverageFactor;
        Debug.Log($"Wall size: {wallSize} => rect size {rectSize}");
        Vector3 scale = rectTransform.lossyScale;
        Vector2 scaledRectSize = new Vector2(
            rectSize.x / scale.x,
            rectSize.y / scale.y
        );
        rectTransform.sizeDelta = scaledRectSize;
    }
}
