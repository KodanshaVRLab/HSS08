using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PassthroughGeometryTag : MonoBehaviour
{
    public MeshRenderer targetRenderer;

    private void OnValidate()
    {
        if (targetRenderer == null)
        {
            TryGetComponent(out targetRenderer);
        }
    }


    #region Static Helpers

    static PassthroughGeometryTag[] _All;

    public static PassthroughGeometryTag[] All
    {
        get
        {
            if (_All == null || _All.Length == 0)
            {
                RefreshList();
            }
            return _All;
        }
    }

    public static void RefreshList()
    {
        _All = FindObjectsByType<PassthroughGeometryTag>(FindObjectsInactive.Include, FindObjectsSortMode.None);
    }
    #endregion
}
