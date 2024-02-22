using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VConteManager : MonoBehaviour
{
    public AudioSource songContainer;

    public List<float> pointsOfInterest;
    public List<GameObject> systems;
    public int currentPoint = 0;
    public float startTime, currentTime, songStartTime;
    public bool isSongPlaying() => songContainer && songContainer.isPlaying;
    public TMPro.TextMeshPro debugLabel;
    public float timeScale = 4f;
    bool isFFWD;

    public OVRManager ovr;
    bool isPassthrough;
    public float currentSongTime { get { return isSongPlaying() ? songContainer.time-62f : -1; } private set { } }
    bool canFFWD;
    public void ToggleCanFFwd(bool value)
    {
        canFFWD = value;
    }
    public void TogglePassTroughState()
    {
        isPassthrough = !isPassthrough;

        ovr.isInsightPassthroughEnabled = isPassthrough;
    }
    public void SetPassTroughState(bool value)
    {
        isPassthrough = value;

        ovr.isInsightPassthroughEnabled = isPassthrough;
    }

    // Start is called before the first frame update
    void Start()
    {
        canFFWD = true;
        if (!songContainer || pointsOfInterest.Count != systems.Count)
            Destroy(this);

        startTime = Time.time;
        StartMusic();
    }

    public void StartMusic()
    {
        songStartTime = Time.time;
        songContainer.Play();

    }
    public void activateNextSystem()
    {

        if (currentPoint==0)
        {
            systems[0].SetActive(true);
            currentPoint++;
            return;
        }

        systems[currentPoint-1].SetActive(false);        
        if(currentPoint<systems.Count)
        systems[currentPoint].SetActive(true);
        currentPoint++;
    }
    [Button]
    public void FFWD()
    {
        if (!canFFWD) return;
        Time.timeScale = Time.timeScale == 1 ? timeScale : 1;
        isFFWD = Time.timeScale != 1;
    }
    // Update is called once per frame
    void Update()
    {
        Debug.Log(currentSongTime);
        if (isFFWD)
        {
            if (songContainer.clip.length > Time.time - songStartTime)
                songContainer.time = Time.time - songStartTime;
        }
        currentTime = Time.time;
        if(currentPoint<pointsOfInterest.Count)
        if (currentTime > pointsOfInterest[currentPoint])
        {
            activateNextSystem();
        }

        if (debugLabel)
        {
            if(currentPoint>=1  && currentPoint<systems.Count)
            debugLabel.text = "Current Time" + (int)currentTime + "Current Scene" + systems[currentPoint-1].name;
        }
    }
}
