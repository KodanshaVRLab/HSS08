using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class JoanPrototypeController : MonoBehaviour
{
    [SerializeField]
    private OVRSceneManager sceneManager = null;

    [SerializeField]
    private List<JoanPrototype> prototypes = new List<JoanPrototype>();
    [SerializeField]
    private int defaultPrototypeIndex = 0;

    [ShowInInspector, ReadOnly]
    private int currentPrototypeIndex = -1;
    [ShowInInspector, ReadOnly]
    private JoanPrototype currentPrototype = null;

    public UnityEvent<string> onPrototypeChanged = null;

    private void Awake()
    {
        sceneManager.SceneModelLoadedSuccessfully += ActivateDefaultPrototype;
    }

    private void ActivateDefaultPrototype()
    {
        ActivatePrototype(defaultPrototypeIndex);
    }

    private void ActivatePrototype(int index)
    {
        if (currentPrototypeIndex == index)
        {
            return;
        }

        if (currentPrototype != null)
        {
            currentPrototype.Deactivate();
            currentPrototypeIndex = -1;
            currentPrototype = null;
        }

        currentPrototypeIndex = index;
        currentPrototype = prototypes[currentPrototypeIndex];

        currentPrototype.Activate();
        onPrototypeChanged?.Invoke(currentPrototype.name);
    }

    [Button]
    public void NextPrototype()
    {
        int newIndex = currentPrototypeIndex + 1;
        if (newIndex >= prototypes.Count)
        {
            newIndex = 0;
        }

        ActivatePrototype(newIndex);
    }

    [Button]
    public void PrevPrototype()
    {
        int newIndex = currentPrototypeIndex - 1;
        if (newIndex < 0)
        {
            newIndex = prototypes.Count - 1;
        }

        ActivatePrototype(newIndex);
    }
}
