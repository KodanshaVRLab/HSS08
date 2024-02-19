using System.Collections.Generic;
using UnityEngine;
using NaughtyAttributes;
using System.Threading.Tasks;
using System;

public class RythmReplay : MonoBehaviour
{
    public enum rythmState
    {
        setup,
        Waiting,
        replay,
        ending,
        loop,
        loopRepetition
    }
    
    public rythmState currentRythmState { get; private set; }
    public  event Action beatEvnt;
    public int currentLevelBeats = 5;    
    protected float currentTime, startTime;
    protected bool setupReady;
    protected int BeatIndex;
     
     public AudioSource rythmAudio;
    
    
    protected float lastTime = 0;
 
    [SerializeField]
    [ReadOnly]
    private string beatTimer;
    protected UnityEngine.Playables.PlayableDirector timeLineDirector;
    [Button]
    public void SetupAndPlay()
    {        
      //  AudioEngineMG.Instance.haptics.startAV();
        setupReady = true;
        timeLineDirector = GetComponent<UnityEngine.Playables.PlayableDirector>();
        if(timeLineDirector)
        startTrack(0);
    }

    private void Awake() => updateState(rythmState.Waiting);
   
    public void updateState(rythmState newState) => currentRythmState = newState;

    public virtual async void startTrack(int delay=2000, int index=0)
    {       
        StartAudio();      
        await Task.Delay(delay);
        // startTime = (float)timeLineDirector.time;
        // currentTime = startTime;       
        // BeatIndex =index;
        // string f = name;
        timeLineDirector.time = currentTime;
        timeLineDirector.Play();
        updateState(rythmState.replay);        
    }

    private void StartAudio()
    {
         if(rythmAudio)
        {
            rythmAudio.Stop();
             rythmAudio.Play();
        }
    }

    protected void replayData()
    {
        /*if (BeatIndex <  currentLevelBeats)
        {            
            if (BeatIndex < Settings.beats.Count)
            {
                currentTime = Time.time - startTime;
                float delta = Mathf.Abs(Settings.beats[BeatIndex].time - currentTime);
                if (delta < 0.1f)
                {
                    doBeatInteraction();
                }
                else
                {
                    beatTimer = $"next beat in:{delta}";
                }
            }
            else if(Settings.loop && currentRythmState!= rythmState.Waiting) 
            {
                 
                startTrack();//reset
            }
        }
        else 
        {
            completeTrackSequence();///finished sub loop
        }*/

    }

    protected virtual void doBeatInteraction()
    {
        
    }

    protected virtual void completeTrackSequence()
    {
                
    }

    protected virtual void BeatInteractionSucceded(beat interactionBeat)
    {

    }
   
    protected virtual void Update()
    {
        if (currentRythmState== rythmState.replay)
        {
            replayData();
        }          
    }
    public virtual void beatMSG()
    {
        if (BeatIndex < currentLevelBeats)
        {
            
        }
        else
        {
            completeTrackSequence();///finished sub loop
        }
    }
}
