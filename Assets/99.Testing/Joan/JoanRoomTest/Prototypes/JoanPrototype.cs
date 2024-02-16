using Meta.WitAi.Attributes;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class JoanPrototype : MonoBehaviour
{
    [Button]
    public abstract void Activate();
    [Button]
    public virtual void Deactivate() { }
}
