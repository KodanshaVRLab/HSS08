using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    [CreateAssetMenu(fileName = "New Interaction Data", menuName = "HSS08/Interaction Data")]
    public class InteractionData : ScriptableObject
    {
        public ValidInteractions interactions = ValidInteractions.None;
        public bool allow = true;
    }

    [System.Flags]
    public enum ValidInteractions
    {
        None        = 0b00000000,
        PortalDecal = 0b00000001,
        EnvSwap     = 0b00000010,
        MikaMark    = 0b00000100
    }
}
