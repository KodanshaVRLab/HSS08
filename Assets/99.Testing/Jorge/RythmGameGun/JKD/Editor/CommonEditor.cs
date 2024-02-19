using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
public class CommonEditor : Editor
{
   public static List<TrackSettings> settings = new List<TrackSettings>();
 public   static List<string> settingsNames = new List<string>();

    public static void drawSegments(TrackSettings timeline)
    {
        #region segments
        GUILayout.Label("segments");
        GUILayout.BeginHorizontal();
        if(timeline.audioTrack)
        for (int i = 0; i < timeline.regionz.Count; i++)
        {
            Vector2 newpos = timeline.regionz[i].duration;
            Vector2 minmax = new Vector2((i == 0 ? 0 : timeline.regionz[i - 1].duration.y),
                                          (i == timeline.regionz.Count - 1 ? timeline.audioTrack.length : timeline.regionz[i + 1].duration.x));
            float width = (Screen.width - 55) * ((minmax.y - minmax.x) / timeline.audioTrack.length);
            GUILayout.BeginVertical();
                GUILayout.Label((int)minmax.x + "-" + (int)minmax.y);
            EditorGUILayout.MinMaxSlider(ref newpos.x, ref newpos.y,
                 minmax.x, minmax.y, GUILayout.Width(width));
            float x = EditorGUILayout.Slider(timeline.regionz[i].threshold, 0, 10, GUILayout.Width(width));
            if (x != timeline.regionz[i].threshold)
            {
                timeline.regionz[i] = new TrackSettings.regions(timeline.regionz[i].duration, x);
            }
            GUILayout.EndVertical();
            if (newpos.x != timeline.regionz[i].duration.x)
            {



                timeline.regionz[i] = new TrackSettings.regions(new Vector2(newpos.x, timeline.regionz[i].duration.y), timeline.regionz[i].threshold);
                if (i != 0)
                {
                    timeline.regionz[i - 1] = new TrackSettings.regions(new Vector2(timeline.regionz[i - 1].duration.x, newpos.x), timeline.regionz[i - 1].threshold);
                }

            }
            if (newpos.y != timeline.regionz[i].duration.y)
            {



                timeline.regionz[i] = new TrackSettings.regions(new Vector2(timeline.regionz[i].duration.x, newpos.y), timeline.regionz[i].threshold);
                if (i + 1 != timeline.regionz.Count)
                {
                    timeline.regionz[i + 1] = new TrackSettings.regions(new Vector2(newpos.y, timeline.regionz[i + 1].duration.y), timeline.regionz[i + 1].threshold);
                }

            }
        }
        GUILayout.EndHorizontal();

        #endregion
    }

    public static void drawSettingsDropDown()
    {
        if (settingsNames.Count == 0 || settings.Count==0)
            getSettings();
        
        if(settings.Count ==settingsNames.Count)
        {

        }

    }
    public static void getSettings()
    {

    }
    public static void getAllSettings(string path)
    {
        settings.Clear();
        settingsNames.Clear();

        settingsNames.AddRange(System.IO.Directory.GetFiles(path));
        for (int i = 0; i < settingsNames.Count; i++)
        {


            settingsNames[i] = settingsNames[i].Remove(0, path.Length);
            var item = settingsNames[i];
            if (!item.Contains(".asset") || item.Contains("meta"))
            {
                settingsNames.Remove(item);
                i--;
            }
            else
            {
                settings.Add(AssetDatabase.LoadAssetAtPath(AudioDataMG.TrackSettingsPath+item, typeof(TrackSettings)) as TrackSettings);

            }
        }

       


    }
}
