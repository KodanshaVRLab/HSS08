using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
 
public class OVRSceneManagerAddon : MonoBehaviour
{
    public OVRSceneManager sceneManager;
    // Start is called before the first frame update
    void Start()
    {
        sceneManager.SceneModelLoadedSuccessfully += OnSceneModelLoadedSuccesfully;
    }

    private void OnSceneModelLoadedSuccesfully()
    {
        StartCoroutine(AddCollidersAndFixClassifications());
    }
    private IEnumerator AddCollidersAndFixClassifications()
    {
        yield return new WaitForEndOfFrame();

        MeshRenderer[] allObjects = FindObjectsOfType<MeshRenderer>();
        foreach (var obj in allObjects)
        {
            if (obj.GetComponent<Collider>() == null)
            {
                obj.gameObject.AddComponent<BoxCollider>();
            }

        }
        OVRSemanticClassification[] allClassifications = FindObjectsOfType<OVRSemanticClassification>().Where(c => c.Contains(OVRSceneManager.Classification.Desk)).ToArray();

        foreach (var classification in allClassifications)
        {
            transform.localScale = new Vector3(transform.localScale.x, transform.localScale.y-1, transform.localScale.z );  
        }

    }
    // Update is called once per frame
    void Update()
    {
        
    }
}
