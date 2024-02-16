using KVRL.KVRLENGINE.Utilities;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanCloseAndFollowPrototype : JoanPrototype
{
    [SerializeField]
    private JoanObjectAttacher attacher = null;

    public override void Activate()
    {
        attacher.AttachObject();
    }

    public override void Deactivate()
    {
        attacher.DettachObject();
    }
}
