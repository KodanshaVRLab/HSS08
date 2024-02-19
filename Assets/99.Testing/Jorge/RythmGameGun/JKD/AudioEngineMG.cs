using System.Collections;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;
using NaughtyAttributes;
using System.IO;
using System;

[System.Serializable]
public class beat
{
    public float intensity;
    public float time;
    public float duration;
    
    public beat(float i, float t, float d)
    {
        intensity = i;
        time = t;
        duration = d;
    }
    
}

public class AudioEngineMG : MonoBehaviour
{
    public TrackSettings settings;
    public int track = 0;
    //TODO custom inspector All tracks list display
    public string tracksPath = "Assets/07.Data/AudioTracks/";
    [HideInInspector]
    public string currentTrackName = "WewillRockyou2ghbnvbh";
    private static AudioEngineMG instance;

    public delegate void BeatEvent();

    public BeatEvent beatDelegate;

    [ReadOnly]
    public int globalBeatCount = 0;

    public enum comboInputs
    {
        up,
        down,
        left,
        right,
        front,
        any
    }
    [System.Serializable]
    public struct comboData
    {
        public comboInputs direction;
        public float time;
        public comboData(comboInputs c, float t)
        {
            direction = c;
            time = t;
        }
    }

    public List<comboData> lastCombo;


    public void beatit()
    {
        Debug.Log("beatit");
    }
    public void Beating()
    {

    }

    public static AudioEngineMG Instance
    {
        get
        {

            if (instance == null)
            {
                instance = FindObjectOfType<AudioEngineMG>();

            }
            return FindObjectOfType<AudioEngineMG>();
        }
    }
    public AudioSource audioTrack;
     public beatTimeline timeline;
    public Transform beatStartPos;
    public GameObject beatDetectorPrefab;
     public TextMesh scoretext;
 
    float startTime;
    float currentTime;
    int nextBeat = 0;
    float timetochange = 2f;
    int delay = 10;
    public bool useUnityAudio = false;
    public bool paused;

    private void OnDestroy()
    {
        PlayerPrefs.SetInt("currentTrack", track);
    }
    private void Awake()
    {
        beatDelegate += beatit;
        instance = this;

         audioTrack = GetComponent<AudioSource>();
        timeline = GetComponent<beatTimeline>();
    }
    [Button]
    public void play()
    {
        lastCombo = new List<comboData>();
        globalBeatCount = 0;
        StartCoroutine(waitAndStart());
    }
    public void play(TrackSettings newSettings)
    {
        settings = newSettings;
      //  wwAE3D.setRythmState(settings.WWiseState);
        StartCoroutine(waitAndStart());
    }

    IEnumerator waitAndStart()
    {
        scoretext.gameObject.SetActive(true);
        int timer = 3;
        scoretext.text = "Ready?";
        while (timer > 0)
        {
            yield return new WaitForSeconds(1f);
            timer--;
            if (timer == 1)
                scoretext.text = "GO!!!";

        }


 
    }

    public AudioSource bgAudio;

    
    public void StartAudio()
    {
        if (useUnityAudio)
        {
            if(bgAudio)
            {
                bgAudio.Stop();

                bgAudio.time = 0;

                bgAudio.Play();
            }

            audioTrack.Stop();

            audioTrack.time = 0;

            audioTrack.Play();
        }
       // else
         //   wwAE3D.Play();
    }
    [Button]
   public void playaudio()
    {
        audioTrack.Play();

    }

    private void Update()
    {
        if(Input.GetKeyDown(KeyCode.R))
        {
            Reset();
        }

        if (Input.GetKeyDown(KeyCode.S))
        {
            play();
        }

        if (Input.GetKeyDown(KeyCode.D))
        {
            if(debugText)
            debugText.SetActive(!debugText.activeSelf);
        }
    }

    public GameObject debugText;
    [NaughtyAttributes.Button]
    public  void Reset()
    {
        /*RReplay.playRecording = false;

        
        RReplay.resetTrack(true);*/
        
        UnityEngine.SceneManagement.SceneManager.LoadScene(0);

       
    }
    // Update is called once per frame


    /* 
     * public void startReplay()
     {
         audioTrack.time = 0;
         nextBeat = 0;
         ADMG.loadData();
         playRecording = true;
         audioTrack.Play();
     }
     * 
     * public void addBeat(UnityEngine.UI.InputField duration)
     {
         if(playRecording)
         {
             audioTrack.Stop();

             playRecording = false;
             loadedBeats.Insert(nextBeat, new beat(1f,audioTrack.time, float.Parse( duration.text)));
             RemoveColidingBeats(); 
         }
     }
     public void removeBeat()
     {
         if (playRecording)
         {
             audioTrack.Stop();
             playRecording = false;
             loadedBeats.RemoveAt(nextBeat);
             RemoveColidingBeats();
         }
     }*/



}
