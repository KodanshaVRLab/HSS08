using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanInteractionSwitcher : MonoBehaviour
{
    [SerializeField]
    private List<GameObject> pokeInteractors = null;
    [SerializeField]
    private List<GameObject> rayInteractors = null;

    private int availablePokeInteractables = 0;
    private int availableRayInteractables = 0;

    private void Start()
    {
        Invoke(nameof(InitializeInteractors), 1f);
    }

    private void InitializeInteractors()
    {
        if (availablePokeInteractables == 0)
        {
            DeactivatePokeInteractors();
        }
        if (availableRayInteractables == 0)
        {
            DeactivateRayInteractors();
        }
    }

    [Button]
    public void AddPokeInteractable()
    {
        availablePokeInteractables++;
        if (availablePokeInteractables == 1)
        {
            ActivatePokeInteractors();
        }
    }

    [Button]
    public void RemovePokeInteractable()
    {
        availablePokeInteractables = Mathf.Max(availablePokeInteractables - 1, 0);
        if (availablePokeInteractables == 0)
        {
            DeactivatePokeInteractors();
        }
    }

    private void ActivatePokeInteractors()
    {
        pokeInteractors.ForEach((go) => go.SetActive(true));
    }

    private void DeactivatePokeInteractors()
    {
        pokeInteractors.ForEach((go) => go.SetActive(false));
    }

    [Button]
    public void AddRayInteractable()
    {
        availableRayInteractables++;
        if (availableRayInteractables == 1)
        {
            ActivateRayInteractors();
        }
    }

    [Button]
    public void RemoveRayInteractable()
    {
        availableRayInteractables--;
        if (availableRayInteractables == 0)
        {
            DeactivateRayInteractors();
        }
    }

    private void ActivateRayInteractors()
    {
        rayInteractors.ForEach((go) => go.SetActive(true));
    }

    private void DeactivateRayInteractors()
    {
        rayInteractors.ForEach((go) => go.SetActive(false));
    }

}