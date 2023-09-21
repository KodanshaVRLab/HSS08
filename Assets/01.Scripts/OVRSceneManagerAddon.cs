using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
 
public class OVRSceneManagerAddon : MonoBehaviour
{
    public OVRSceneManager sceneManager;

    public GameObject wallMarker;
    // Start is called before the first frame update
    void Start()
    {
        sceneManager.SceneModelLoadedSuccessfully += OnSceneModelLoadedSuccesfully;
      

        //Check if the boundary is configured
        bool configured = OVRManager.boundary.GetConfigured();
 
        if (configured)
        {
            //Grab all the boundary points. Setting BoundaryType to OuterBoundary is necessary
            Vector3[] boundaryPoints = OVRManager.boundary.GetGeometry(OVRBoundary.BoundaryType.OuterBoundary);
         
             //Generate a bunch of tall thin cubes to mark the outline
            foreach (Vector3 pos in boundaryPoints)
            {        
                Instantiate(wallMarker, pos, Quaternion.identity);
}
            }

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
