using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanSingleWallPrototype : JoanPrototype
{
    private enum Mode
    {
        Front,
        Close
    }

    [SerializeField]
    private JoanWallDetector wallDetector = null;
    [SerializeField]
    private JoanWallPinner wallPinner = null;
    [SerializeField, OnValueChanged("OnModeChanged")]
    private Mode mode = Mode.Front;

#if UNITY_EDITOR
    private void OnModeChanged()
    {
        name = $"{mode} Wall";
    }
#endif

    public override void Activate()
    {
        base.Activate();

        GameObject wall = null;
        if (mode == Mode.Front)
        {
            wall = wallDetector.GetFrontWall();
        }
        else if (mode == Mode.Close)
        {
            wall = wallDetector.GetClosestWall();
        }

        if (wall != null)
        {
            wallPinner.PinToWall(wall);
        }
    }
}
