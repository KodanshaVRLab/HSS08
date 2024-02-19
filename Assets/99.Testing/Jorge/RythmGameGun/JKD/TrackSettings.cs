using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName ="TrackSettings",menuName = "Settings/Audio/TrackSettings", order =0)]
public class TrackSettings : ScriptableObject

{ 
    public AudioClip audioTrack;
     
    public string TrackName;
    public string WWiseState;
    [System.Serializable]
    public struct regions
    {
        public Vector2 duration;
        public float threshold;
        public regions(Vector2 dur, float t)
        {
            duration = dur;
            threshold = t;
        }
        public void changeDuration(Vector2 v)
        {
            duration = v;
        }
        public void changeDurationX(float v)
        {
            duration.x = v;
        }
        public void changeDurationY(float v)
        {
            duration.y = v;
        }
    }

    [HideInInspector]

    public List<regions> regionz = new List<regions>();

    public float getThreshold(float time)
    {
        for (int i = 0; i < regionz.Count; i++)
        {
            if (time >= regionz[i].duration.x && time <= regionz[i].duration.y)
                return regionz[i].threshold;
        }

        return 1f;
    }

}
