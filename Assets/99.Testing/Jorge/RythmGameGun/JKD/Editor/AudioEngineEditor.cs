using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
[CustomEditor(typeof(AudioEngineMG))]
public class AudioEngineEditor : Editor
{
    private void OnEnable()
    {
      
        y = PlayerPrefs.GetInt("currentTrack");
        (target as AudioEngineMG).track = y;
    }
    private void OnDisable()
    {
        
        PlayerPrefs.SetInt("currentTrack",y);
       
    }
    //  int y = 0;
    List<string> tracks= new List<string>();
    private static int y=5;
    public override void OnInspectorGUI()
    {
        var mg = target as AudioEngineMG;



        base.OnInspectorGUI();

        if (tracks.Count> 0)
        {
            y = EditorGUILayout.Popup(mg.track, tracks.ToArray());
            if (y != mg.track)
            {
                if (y > CommonEditor.settings.Count)
                {
                    CommonEditor.getAllSettings(AudioDataMG.TrackSettingsPath);
                }
                if (y < CommonEditor.settings.Count)
                {
                    mg.track = y;
                    mg.currentTrackName = tracks[y];
                    mg.settings = CommonEditor.settings[y];
                    mg.audioTrack.clip = mg.settings.audioTrack;
                }
                else
                    Debug.LogWarning("OUT OF BOUNDS");

            }
        }
        else
        {
            tracks = AudioDataMG.getAllTracks(mg.tracksPath);
        }

        if (GUILayout.Button("Update Tracks"))
        {
            AudioDataMG.getAllTracks(mg.tracksPath);
        }
        if (GUILayout.Button("play"))
        {
            mg.play();
        }
        if (GUILayout.Button("Reset"))
        {
            mg.Reset();
        }


    }
}
