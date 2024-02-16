using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanFrontWallPrototype : JoanPrototype
{
    [SerializeField]
    private JoanWallDetector frontWallDetector = null;

    public override void Activate()
    {
        frontWallDetector.FindFrontWall();
    }
}
