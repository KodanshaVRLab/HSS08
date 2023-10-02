using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
 
public class OVRSceneManagerAddon : MonoBehaviour
{
    public OVRSceneManager sceneManager;

    public GameObject wallMarker;
    public TextMesh debugText;
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
                var col = obj.gameObject.AddComponent<BoxCollider>();
                col.size = new Vector3(col.size.x, col.size.y * 1f, col.size.z);

                if (obj.name.Contains("Desk"))
                {
                    if(debugText)
                    debugText.text += "adjusting Desk " + obj.name;
                    obj.transform.position = obj.transform.position - (Vector3.up * obj.transform.GetComponent<MeshRenderer>().bounds.extents.y*2);
                }

            }

        }
        OVRSemanticClassification[] allClassifications = FindObjectsOfType<OVRSemanticClassification>().Where(c => c.Contains(OVRSceneManager.Classification.Table)).ToArray();

        foreach (var classification in allClassifications)
        {
            classification.transform.localScale = new Vector3(transform.localScale.x, transform.localScale.y * -1, transform.localScale.z);
            if (classification.transform.GetComponent<MeshRenderer>())
            {
                classification.transform.position = transform.position - (Vector3.up * classification.transform.GetComponent<MeshRenderer>().bounds.extents.y);
                if (debugText)
                {

                    debugText.text += "is table  offseting " + classification.transform.GetComponent<MeshRenderer>().bounds.extents.y;
                }
            }
            else
            {
                if (debugText)
                {

                    debugText.text += "table no mesh renderer" + classification.transform.name;
                }
            }
        }
        allClassifications = FindObjectsOfType<OVRSemanticClassification>().Where(c => c.Contains(OVRSceneManager.Classification.Desk)).ToArray();

        foreach (var classification in allClassifications)
        {
            classification.transform.localScale = new Vector3(transform.localScale.x, transform.localScale.y * -1, transform.localScale.z);
            if (classification.transform.GetComponent<MeshRenderer>())
            {
                classification.transform.position = transform.position - (Vector3.up * classification.transform.GetComponent<MeshRenderer>().bounds.extents.y);
                if (debugText)
                {

                    debugText.text+= "is desk  offseting " + classification.transform.GetComponent<MeshRenderer>().bounds.extents.y;
                }
            }
            else
            {
                if (debugText)
                {

                    debugText.text += " desk no mesh renderer in " + classification.transform.name;
                }
            }
        }

    }
    // Update is called once per frame
    void Update()
    {
        
    }
}
