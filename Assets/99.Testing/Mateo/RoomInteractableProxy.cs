using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    public class RoomInteractableProxy : MonoBehaviour
    {
        public GameObject proxyPrefab;

        // Start is called before the first frame update
        void Start()
        {
            if (proxyPrefab != null)
            {
                Instantiate(proxyPrefab, transform, false);
            }
        }
    }
}
