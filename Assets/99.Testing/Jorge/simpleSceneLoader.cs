using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class simpleSceneLoader : MonoBehaviour
{
    public int nextScene = 0;
    // Start is called before the first frame update
    void Start()
    {

    }
    public void loadScene()
    {
        UnityEngine.SceneManagement.SceneManager.LoadSceneAsync(nextScene);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
