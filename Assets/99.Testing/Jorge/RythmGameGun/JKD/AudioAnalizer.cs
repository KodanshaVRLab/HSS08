using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using NaughtyAttributes;
public class AudioAnalizer : MonoBehaviour
{public TrackSettings settings;
    bool analyze = false;
    float[] spectrum = new float[1024];
  
    [SerializeField] List<beat> beats = new List<beat>();
    [SerializeField] List<beat> finalbeats = new List<beat>();
    [Range(-0.3f, 0.3f)]
    public float beatsOffset = -0.1f;
    public bool debug = false;

   
    public bool analyzeOnAwake = false;
    public AudioSource audioTrackHolder;
    

    [ProgressBar("Analysis",100,EColor.Green)]
    public int AnalysisProgress=0;

    [Button]
    public void StartAnalysis()
    {
        beats.Clear();
        audioTrackHolder = GetComponent<AudioSource>();
        audioTrackHolder.clip = settings.audioTrack;
        PlayerPrefs.SetInt("Analize", 1);
#if UNITY_EDITOR

        if (!Application.isPlaying)
        {

            UnityEditor.EditorApplication.EnterPlaymode();
            analyzeOnAwake = true;

        }
#endif
        if (Application.isPlaying)
        {
            setup();
        }
    }
    IEnumerator doit()
    {
        yield return new WaitForSeconds(5f);
        setup();
    }
    private void Awake()
    {
        
        if (analyzeOnAwake)
        {
            StartCoroutine(doit());
            PlayerPrefs.SetInt("Analize", 0);
        }
    }

    void setup()
    {        
        audioTrackHolder.Play();
        analyze = true;
    }
    void analyzeAudio()
    {
        audioTrackHolder.GetSpectrumData(spectrum, 0, FFTWindow.BlackmanHarris);
        float av = 0;
        for (int i = 1; i < spectrum.Length - 1; i++)
        {
            av += spectrum[i];
            if (debug)
            {
                drawDebugVisualizer(i);
            }
        }
        if (av > settings.getThreshold(audioTrackHolder.time))
        {
            if(beats.Count==0)
            {
                beats.Add(new beat(av, audioTrackHolder.time, 0));
            }
            else if (beats.Count > 0 && beats[beats.Count - 1].time != audioTrackHolder.time)
            {
                beats.Add(new beat(av, audioTrackHolder.time, 0));
            }
            
        }
        if (!audioTrackHolder.isPlaying)
        {
            FinishAnalysis();
        }
    }

    private void FinishAnalysis()
    {
        analyzeOnAwake = false;
        analyze = false;
        joinCloseBeats();
        RemoveColidingBeats();
        AudioDataMG.save(finalbeats, settings.TrackName);
        finalbeats = AudioDataMG.loadDatafromLocation(settings.TrackName);
        Debug.Log("FINISHED");
#if UNITY_EDITOR
        if (Application.isPlaying)
        {
           
            UnityEditor.EditorApplication.ExitPlaymode();

        }
#endif
    }
   
    private void drawDebugVisualizer(int i)
    {
        Debug.DrawLine(new Vector3(i - 1, spectrum[i] + 10, 0), new Vector3(i, spectrum[i + 1] + 10, 0), Color.red);
        Debug.DrawLine(new Vector3(i - 1, Mathf.Log(spectrum[i - 1]) + 10, 2), new Vector3(i, Mathf.Log(spectrum[i]) + 10, 2), Color.cyan);
        Debug.DrawLine(new Vector3(Mathf.Log(i - 1), spectrum[i - 1] - 10, 1), new Vector3(Mathf.Log(i), spectrum[i] - 10, 1), Color.green);
        Debug.DrawLine(new Vector3(Mathf.Log(i - 1), Mathf.Log(spectrum[i - 1]), 3), new Vector3(Mathf.Log(i), Mathf.Log(spectrum[i]), 3), Color.blue);
    }

    [Button]
    public List<beat> joinCloseBeats()
    {
        List<beat> tmpbeats = new List<beat>();
        finalbeats.Clear();
        foreach (var item in beats)
        {

            if ((tmpbeats.Count > 0 && item.time - tmpbeats[tmpbeats.Count - 1].time > 0.1f))
            {
                addJoinedBeats(tmpbeats);
                tmpbeats.Add(item);
            }
            else
            {
                tmpbeats.Add(item);
            }
        }

        if (tmpbeats.Count > 0)
        {
            addJoinedBeats(tmpbeats);
        }
         
        return finalbeats;
    }

    private void addJoinedBeats(List<beat> tmpbeats)
    {
        float time = tmpbeats[0].time;
        float avgintensity = 0;
        float duration = (tmpbeats.Count == 1) ? 0 : tmpbeats[tmpbeats.Count - 1].time - tmpbeats[0].time;
        for (int i = 0; i < tmpbeats.Count; i++)
        {
            avgintensity += tmpbeats[i].intensity;
        }

        avgintensity /= tmpbeats.Count;

        tmpbeats.Clear();
        finalbeats.Add(new beat(avgintensity, time, duration));
    }

    [Button]
    public void applyOffset()
    {
        if (finalbeats.Count == 0)
        {
           finalbeats= AudioDataMG.loadDatafromLocation(settings.TrackName);

        }
        for (int i = 0; i < finalbeats.Count; i++)
        {
            finalbeats[i].time += beatsOffset;
        }
        AudioDataMG.save(finalbeats, settings.TrackName);
        finalbeats = AudioDataMG.loadDatafromLocation(settings.TrackName);
    }
    [Button]
    public void RemoveColidingBeats()
    {
        if (finalbeats.Count == 0)
            finalbeats= AudioDataMG.loadDatafromLocation(settings.TrackName);

        for (int i = 0; i < finalbeats.Count - 1; i++)
        {
            if (checkCollision(finalbeats[i], finalbeats[i + 1]))
            {
                finalbeats[i].duration = (finalbeats[i + 1].time+   finalbeats[i + 1].duration)- finalbeats[i].time;
                finalbeats.Remove(finalbeats[i + 1]);
                i--;
            }

        }
    }
    bool checkCollision(beat a, beat b)
    {
        return b.time<a.time+a.duration;
    }
    void Update()
    {
        if (analyze)
        {
            analyzeAudio();
          
            AnalysisProgress = (int)(audioTrackHolder.time / settings.audioTrack.length * 100f);
            
        }
    }
}
