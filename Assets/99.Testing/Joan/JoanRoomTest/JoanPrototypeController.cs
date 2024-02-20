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

    [Button]
    private void ActivatePrototype(int index)
    {
        if (currentPrototypeIndex == index)
        {
            return;
        }

        newIndex = index;
        DeactiveCurrentPrototype();
        Invoke(nameof(ActivateNewPrototype), 0.1f);
    }

    private int newIndex = -1;

    [Button]
    private void DeactiveCurrentPrototype()
    {
        if (currentPrototype != null)
        {
            currentPrototype.Deactivate();

            currentPrototypeIndex = -1;
            currentPrototype = null;
        }
    }

    private void ActivateNewPrototype()
    {
        int index = newIndex;

        currentPrototype = prototypes[index];
        currentPrototype.Activate();

        currentPrototypeIndex = index;
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
