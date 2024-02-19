using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using UnityEngine.UI;

[ExecuteAlways]
public class beatTimeline : MonoBehaviour
{
    [HideInInspector]
    public TrackSettings Settings;

    
    [HideInInspector]
    public int trackIndex = 0;
     
    int currentBeat = 0;
    float xposOffset = 0;
    [HideInInspector]
    public float Offset = 3f;
    [HideInInspector]
    public List<Vector3> graphicPositions = new List<Vector3>();
    [HideInInspector]
    public Slider timelineControl;
    public AudioSource audioTrackHolder;
    public List<beat> loadedBeats;

    bool updateSliderPosition =true;
   
    // public  AudioEngineMG AudioEngineMG;
   
    public bool edit = false;
  [HideInInspector]
    public float currentTrackTime = 0;
    bool updating = false;
     
    public LayerMask EditorLayers,NonEditorLayers;



    private void Awake()
    {
        edit = false;
#if UNITYEDITOR
        UnityEditor.Tools.visibleLayers = NonEditorLayers; 
#endif
    }
    public enum audioState
    {
        stop,
        playing,
        pause
    }
    [HideInInspector]
   public audioState currentAudioState= audioState.stop;
     public void updatePosition()
    {
        audioTrackHolder.time = (timelineControl.value * audioTrackHolder.clip.length); 
    }
    public void sliderSelected(bool isSelected)
    {
        updateSliderPosition = isSelected;
    }
    // Start is called before the first frame update
    void Start()
    {
        audioTrackHolder = GetComponent<AudioSource>();
        //AudioEngineMG = GetComponent<AudioEngineMG>();
    }


    public void playAudio()
    {

        currentAudioState = audioState.playing;
        audioTrackHolder.time = currentTrackTime;
        audioTrackHolder.Play();
    }
    public void pauseAudio()
    {
        currentAudioState = audioState.pause;
        audioTrackHolder.Pause();

    }
    public void StopAudio()
    {
        currentAudioState = audioState.stop;
        currentTrackTime = 0;
        audioTrackHolder.Stop();


    }
    private void OnValidate()
    {

        if (!edit)
        {
            StopAudio();
            updating = false;
#if UNITYEDITOR
            UnityEditor.EditorApplication.update -= Update;
#endif
        }
        else if (!updating)
        {
            updating = true;
            #if UNITYEDITOR

            UnityEditor.EditorApplication.update += Update;
#endif
        }
    }

    public void graphic()
    {
        if (loadedBeats == null)
        {
            loadedBeats = new List<beat>();
        }
        if( loadedBeats.Count>0 && audioTrackHolder)
        {
            currentBeat = 0;
            graphicPositions.Clear();

            Vector3 lastPos = Vector3.zero;
            Vector3 nextPos = new Vector3(loadedBeats[currentBeat].time, 0, 0);

            //0,1
           
            graphicPositions.Add(lastPos);  

            graphicPositions.Add(nextPos);

            /*
                2-----3
                |     |
             0--1     4-----F
             */
            for (int i = 0; i < loadedBeats.Count- 1; i++)
            {
                float yPos0 = loadedBeats[currentBeat].intensity ;
                float xpos = loadedBeats[currentBeat].time;
                //1
                  lastPos = nextPos;
                //2
                nextPos = new Vector3(xpos, yPos0, 0);

                //1,2
                
                graphicPositions.Add(lastPos);

                graphicPositions.Add(nextPos);
                //2
                lastPos = nextPos;
                //3
                nextPos = nextPos + (Vector3.right * loadedBeats[currentBeat].duration);
                //2,3
                
                graphicPositions.Add(lastPos);

                graphicPositions.Add(nextPos);

                //3
                lastPos = nextPos;
                //4
                nextPos = new Vector3(nextPos.x, 0, 0);

                //3,4
            
                graphicPositions.Add(lastPos);

                graphicPositions.Add(nextPos);


                currentBeat++;
                //4
                lastPos = nextPos;
                //5
                nextPos = new Vector3(loadedBeats[currentBeat].time, 0, 0);
                //4,5
              
                graphicPositions.Add(lastPos);

                graphicPositions.Add(nextPos);


            }

        }
    }
    
    public void addBeat(int pos)
    {
        if(pos>0 && loadedBeats.Count-1>pos)
        {
            beat nBeat = new beat(loadedBeats[pos].intensity, (loadedBeats[pos - 1].time + loadedBeats[pos].time) * 0.5f, 0f);

            loadedBeats.Insert(pos,nBeat);
        }
    }
    public void removeBeat(int pos)
    {
        loadedBeats.RemoveAt(pos);
    }

    public void CreateBackup()
    {
        if (loadedBeats.Count == 0)
            Load();
        string name = Settings.TrackName;
        if (name.Contains(".txt"))
        {
            name.Replace(".txt", "");
        }
        name = name + "BU" + ".txt";

        AudioDataMG.save(loadedBeats, name);

    }
    public void Reset()
    {
        string name = Settings.TrackName;
        if (name.Contains(".txt"))
        {
            name.Replace(".txt", "");
        }
        name = name + "BU" + ".txt";
        loadedBeats = AudioDataMG.loadDatafromLocation(name);
        Save();
        Load();
    }
    void Update()
    {

        if (currentAudioState == audioState.playing)
        {
            currentTrackTime = audioTrackHolder.time;
        } 
         if (updateSliderPosition)
        {
            if (timelineControl)
            timelineControl.value =( 1f / audioTrackHolder.clip.length) * audioTrackHolder.time;
        }
    }

    public void Load()
    {
        currentTrackTime = 0;
        if(Settings)
        loadedBeats = AudioDataMG.loadDatafromLocation(Settings.TrackName);
    }
    public void Save()
    {
        AudioDataMG.save(loadedBeats, Settings.TrackName);

         
    }

    public void applyOffset(float offseto)
    {
        for (int i = 0; i < loadedBeats.Count; i++)
        {
            loadedBeats[i].time =Mathf.Max(0, loadedBeats[i].time + offseto);
        }
         
        
    }
}
