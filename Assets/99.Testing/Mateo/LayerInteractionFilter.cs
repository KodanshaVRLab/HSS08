using Oculus.Interaction;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    public class LayerInteractionFilter : MonoBehaviour, IGameObjectFilter
    {
        public LayerMask validLayers;
        public bool Filter(GameObject gameObject)
        {
            int otherLayer = gameObject.layer;
            int otherMask = 1 << otherLayer;
            
            return (validLayers & otherMask) != 0;
        }
    }
}
