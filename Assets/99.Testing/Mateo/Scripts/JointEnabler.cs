using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JointEnabler : MonoBehaviour
{
    public GameObject[] boundObjects;

    public bool bindActivation = true;
    public bool bindDisabling = true;

    private void OnEnable()
    {
        if (bindActivation)
        {
            JointSetActive(true);
        }
    }

    private void OnDisable()
    {
        if (bindDisabling)
        {
            JointSetActive(false);
        }
    }

    public void JointSetActive(bool active)
    {
        if (boundObjects != null)
        {
            for (int i = 0; i < boundObjects.Length; i++)
            {
                boundObjects[i].SetActive(active);
            }
        }
    }
}
