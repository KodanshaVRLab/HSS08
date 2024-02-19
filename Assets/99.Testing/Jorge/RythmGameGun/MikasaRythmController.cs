using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Animations.Rigging;

public class MikasaRythmController : MonoBehaviour
{
    public Transform shootPoint, target;
    public LineRenderer lr;
    public Rig rigController;
    // Start is called before the first frame update
    void Start()
    {
        lr = GetComponent<LineRenderer>();
        if (lr)
            lr.enabled = false;
    }

    public void updateTarget(Transform t)
    {
        rigController.weight = 1;

        if (lr)
        lr.enabled = true;
        target.position = t.position;
        if (shootPoint)
            lr.SetPosition(0, shootPoint.position);
        if (target)
            lr.SetPosition(1, target.position);
    }
    public void disablePointing()
    {
        lr.enabled = false;
        rigController.weight =0;

    }
    // Update is called once per frame
    void Update()
    {
        if (lr.enabled)
        {
            if (shootPoint)
                lr.SetPosition(0, shootPoint.position);
            if (target)
                lr.SetPosition(1, target.position);
        }
    }
}
