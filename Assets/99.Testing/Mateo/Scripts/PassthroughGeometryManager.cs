using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PassthroughGeometryManager : MonoBehaviour
{

    public void SetRenderers(bool active)
    {
        var passthruAll = PassthroughGeometryTag.All;

        if (passthruAll == null )
        {
            return;
        }

        foreach (var passthrough in passthruAll)
        {
            var r = passthrough.targetRenderer;
            if (r != null)
            {
                r.enabled = active;
            }
        }
    }

    public void EnableRenderers()
    {
        SetRenderers(true);
    }

    public void DisableRenderers()
    {
        SetRenderers(false);
    }
}
