using Sirenix.OdinInspector;
using Sirenix.Utilities;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using System;

public class MikasaInteractableObjectsMG : MonoBehaviour
{
    bool setupReady = false;
    MikasaInteractableObject currentObject;
    private static MikasaInteractableObjectsMG instance;

    // Property to access the instance
    public static MikasaInteractableObjectsMG Instance
    {
        get
        {
            if (instance == null)
            {
                instance = FindObjectOfType<MikasaInteractableObjectsMG>();

                if (instance == null)
                {
                    GameObject singletonObject = new GameObject("MikasaInteractableObject");
                    instance = singletonObject.AddComponent<MikasaInteractableObjectsMG>();
                }
            }
            return instance;
        }
    }
    public void updateCurrent(MikasaInteractableObject newObject)
    {
        currentObject = newObject;
    }
    [Button]
    public void setup()
    {
        var objs = FindObjectsOfType<MikasaInteractableObject>().OrderBy(x=>x.name).ToList();
        if(objs.Count>1)
        for (int i = 1; i < objs.Count; i++)
        {
                if(objs[i-1].name.Contains(objs[i].name))
                {
                    objs[i].name += (i+1);
                }
        }
        
    }
    // Start is called before the first frame update
     

    // Update is called once per frame
    void Update()
    {
        
    }

    public bool isThisCurrentObj(MikasaInteractableObject mikasaInteractableObject)
    {
        return currentObject == mikasaInteractableObject;
    }
}
