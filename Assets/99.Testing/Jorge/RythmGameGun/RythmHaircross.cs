using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class RythmHaircross : MonoBehaviour
{
    public SpriteRenderer spRenderer;
    public float maxScale, minScale;
    public int steps=4;
    public float tempo = 118;
    public bool isPaused;
    float currentScale=0f;
    int currentScaleIndex = 1;
    public float timeToChange;
    public Transform cameraTransfrom;

    public UnityEvent onBeat;
     IEnumerator animateHairCross()
    {        
        timeToChange = 1f / (tempo/60f);
        var delta=0f;
        while (!isPaused)
        {
            yield return new WaitForEndOfFrame();
            delta += Time.deltaTime;
            if (delta >= timeToChange)
            {
                onBeat.Invoke();
                Debug.Log("Beat");
                currentScaleIndex = (currentScaleIndex + 1);
                if (currentScaleIndex > steps)
                {
                   
                    currentScaleIndex = 1;
                }
                
                currentScale = (1f / (float)steps )* currentScaleIndex;
                spRenderer.transform.localScale = Vector3.Lerp(Vector3.one * maxScale, Vector3.one * minScale, currentScale);
                delta = 0f;
            }

            
        }

    }
    void Start()
    {
        StartCoroutine(animateHairCross());
    }
     
}
