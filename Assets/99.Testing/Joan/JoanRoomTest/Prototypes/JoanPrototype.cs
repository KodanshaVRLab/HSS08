using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class JoanPrototype : MonoBehaviour
{
    [SerializeField]
    private GameObject menu = null;

    [Button]
    public virtual void Activate()
    {
        menu.SetActive(true);
    }

    [Button]
    public virtual void Deactivate()
    {
        menu.SetActive(false);
    }
}
