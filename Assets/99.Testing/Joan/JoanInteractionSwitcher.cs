using Oculus.Interaction;
using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanInteractionSwitcher : MonoBehaviour
{
    public enum InteractionMode
    {
        Poke,
        Ray,
        Both
    }

    [SerializeField]
    private InteractionMode defaultMode = InteractionMode.Poke;

    [SerializeField]
    private List<GameObject> pokeInteractors = null;
    [SerializeField]
    private List<GameObject> rayInteractors = null;

    [ShowInInspector, ReadOnly]
    private InteractionMode currentMode = InteractionMode.Poke;

    private void Start()
    {
        SetInteractionMode(defaultMode);
    }

    private void SetInteractionMode(InteractionMode mode)
    {
        currentMode = mode;

        bool pokeInteractorsActive = mode == InteractionMode.Poke
            || mode == InteractionMode.Both;
        pokeInteractors.ForEach(go => go.SetActive(pokeInteractorsActive));

        bool rayInteractorsActive = mode == InteractionMode.Ray
            || mode == InteractionMode.Both;
        rayInteractors.ForEach(go => go.SetActive(rayInteractorsActive));
    }

    [Button]
    public void SetPokeInteraction()
    {
        SetInteractionMode(InteractionMode.Poke);
    }

    [Button]
    public void SetRayInteraction()
    {
        SetInteractionMode(InteractionMode.Ray);
    }
}