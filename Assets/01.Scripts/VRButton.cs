using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class VRButton : MonoBehaviour
{
    public UnityEvent OnClick;
    public float coolOffTime = 3f;
    public bool available = true;
    // Start is called before the first frame update
    void Start()
    {
        
    }
    public void Click()
    {
        if(available)
        {
            OnClick.Invoke();
            StartCoroutine(coolDown());
        }
    }

    IEnumerator coolDown()
    {
        available = false;
        yield return new WaitForSeconds(coolOffTime);
        available = true;
    }
    // Update is called once per frame
    void Update()
    {
        
    }
}
