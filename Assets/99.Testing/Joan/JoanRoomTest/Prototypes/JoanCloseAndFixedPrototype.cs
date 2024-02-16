using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanCloseAndFixedPrototype : JoanPrototype
{
    [SerializeField]
    private JoanUserPinner userPinner = null;

    public override void Activate()
    {
        userPinner.PinObject();
    }
}