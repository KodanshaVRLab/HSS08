using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class runtimeAudioAnalysis : MonoBehaviour
{
    public AudioSource audioTrackHolder;
    float[] spectrum = new float[1024];
    [Range(0f,0.1f)]
    public float threshold=0.05f;
    [Range(0f, 0.1f)]
    public float delaybetweenSound = 0.5f;
     public UnityEvent beatEvent;
    public bool analyze  = true;
    bool available = true;
    private void Update()
    {
        if (analyze && audioTrackHolder)
            analyzeAudio();
    }
    void analyzeAudio()
    {
        audioTrackHolder.GetSpectrumData(spectrum, 0, FFTWindow.BlackmanHarris);
        float av = 0;
        for (int i = 1; i < spectrum.Length - 1; i++)
        {
            av += spectrum[i];
            
        }
        if (av > threshold)
        {
            if (available)
            {
                available = false;
                StartCoroutine(coolOff());
                beatEvent.Invoke();
            }

        }
        if (!audioTrackHolder.isPlaying)
        {
            FinishAnalysis();
        }
    }
    IEnumerator coolOff()
    {
        yield return new WaitForSeconds(delaybetweenSound);
        available = true;
    }
    public void testBeat()
    {
        Debug.Log("beat");
    }
    private static void FinishAnalysis()
    {
      //  Debug.Log("AudioFinished");
    }
}
