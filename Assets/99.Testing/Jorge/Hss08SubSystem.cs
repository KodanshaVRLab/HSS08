using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class Hss08SubSystem : MonoBehaviour
{
    public UnityEvent onSystemStart;
    private void OnEnable()
    {
        onSystemStart.Invoke();
    }
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
