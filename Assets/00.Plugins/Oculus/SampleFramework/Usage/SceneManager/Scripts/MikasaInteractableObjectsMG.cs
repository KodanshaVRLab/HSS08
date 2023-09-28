using Sirenix.OdinInspector;
using Sirenix.Utilities;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;
public class MikasaInteractableObjectsMG : MonoBehaviour
{
    bool setupReady = false;
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
}
