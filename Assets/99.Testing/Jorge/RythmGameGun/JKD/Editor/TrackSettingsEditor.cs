using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

//[CustomEditor(typeof(TrackSettings))]
public class TrackSettingsEditor : Editor
{

    public override void OnInspectorGUI()
    {
        TrackSettings tSettings = target as TrackSettings;
        base.OnInspectorGUI();
        CommonEditor.drawSegments(tSettings);
        if(GUILayout.Button("Add New Segment"))
        {
            Vector2 v = Vector2.zero;
            if (tSettings.regionz.Count > 0)
            {
                var x = tSettings.regionz[tSettings.regionz.Count - 1];
                if (x.duration.y == tSettings.audioTrack.length)
                {
                    x.duration.y = tSettings.audioTrack.length - 15;
                    tSettings.regionz[tSettings.regionz.Count - 1] = x;
                }
                v.x = tSettings.regionz[tSettings.regionz.Count - 1].duration.y;
                v.y = tSettings.audioTrack.length;
            }
            else
                v.y = tSettings.audioTrack.length;
            tSettings.regionz.Add(new TrackSettings.regions(v, 0.5f));
        }
    }
}
