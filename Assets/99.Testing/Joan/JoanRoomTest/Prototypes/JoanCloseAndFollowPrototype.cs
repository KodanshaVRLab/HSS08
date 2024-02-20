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
        base.Activate();
        attacher.AttachObject();
    }

    public override void Deactivate()
    {
        base.Deactivate();
        attacher.DettachObject();
    }
}
