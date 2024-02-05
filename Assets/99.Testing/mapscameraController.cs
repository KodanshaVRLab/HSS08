using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
public class mapscameraController : MonoBehaviour
{
    public Vector3 speed;
    public float timeToLoadScene=60f;
    public int sceneToLoad = 1;
    // Start is called before the first frame update
    void Start()
    {
        OVRManager.suggestedGpuPerfLevel = OVRManager.ProcessorPerformanceLevel.Boost;
        OVRManager.suggestedCpuPerfLevel = OVRManager.ProcessorPerformanceLevel.Boost;
        StartCoroutine(loadScene());
    }

    IEnumerator loadScene()
    {
        yield return new WaitForSeconds(timeToLoadScene);
        SceneManager.LoadScene(sceneToLoad);
    }

    // Update is called once per frame
    void Update()
    { 
        
    }
}
