using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanHologramProjectorPrototype : JoanPrototype
{
    [SerializeField]
    private JoanObjectAttacher attacher = null;
    [SerializeField]
    private JoanTableDetector tableDetector = null;
    [SerializeField]
    private Transform projectRoot = null;

    public override void Activate()
    {
        base.Activate();
        attacher.AttachObject();
        tableDetector.DetectTable();
    }

    public override void Deactivate()
    {
        base.Deactivate();
        attacher.DettachObject();
    }

    public void TableFound(GameObject table)
    {
        Vector3 position = GetTableTopCenter(table);
        SetPosition(position);
    }

    private Vector3 GetTableTopCenter(GameObject table)
    {
        OVRSceneVolume sceneVolume = table.GetComponentInChildren<OVRSceneVolume>();
        float halfHeight = sceneVolume.Dimensions.y;
        Vector3 center = sceneVolume.transform.position;
        //Vector3 topCenter = center + Vector3.up * halfHeight;
        return center;
    }

    public void CenterFound(Vector3 center)
    {
        SetPosition(center);
    }

    private void SetPosition(Vector3 position)
    {
        projectRoot.position = position;
    }
}
