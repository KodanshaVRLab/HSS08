using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PassthroughStateProxy : MonoBehaviour
{
    [SerializeField] OVRManager ovr;

    private void OnValidate()
    {
        if (ovr == null)
        {
            ovr = FindFirstObjectByType<OVRManager>();
        }
    }

    public void SetPassthrough(bool state)
    {
        if (ovr != null)
        {
            ovr.isInsightPassthroughEnabled = state;
        }
    }

    public bool PassthroughEnabled
    {
        get
        {
            if (ovr == null)
            {
                return false;
            }

            return ovr.isInsightPassthroughEnabled;
        }

        set
        {
            SetPassthrough(value);
        }
    }
}
