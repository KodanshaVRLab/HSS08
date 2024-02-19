using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using NaughtyAttributes;
using System.IO;

public class AudioDataMG 
{

    public static string TrackSettingsPath = "Assets/07.Data/Settings/Tracks/";
    public static string TrackAudioAnalysisPath = "Assets/07.Data/AudioTracks/";
    [Button]
    public static List<beat> loadDatafromLocation(string fileName)
    {
        fileName = TrackAudioAnalysisPath + fileName + (fileName.Contains(".txt") ? "" : ".txt");
        List<beat> loadedBeats = new List<beat>();
        if (File.Exists(fileName))
        {
            var Data = File.ReadAllLines(fileName);
            foreach (var item in Data)
            {
                loadedBeats.Add(JsonUtility.FromJson<beat>(item));
            }
            return loadedBeats;
        }
        Debug.LogWarning("FILE NOT FOUND!");
        return null;
    }

    public static List<beat> loadDataFromFile(TextAsset data)
    {
        List<beat> beats = new List<beat>();         
        foreach (var item in data.text.Split('\n'))
        {
            var b = JsonUtility.FromJson<beat>(item);
            if(b!=null)
            beats.Add(b);
        }
        return beats;
    }
    public static void save(List<beat> dataToSave, string fileName)
    {
        List<string> data = new List<string>();
        foreach (var item in dataToSave) 
        {
            data.Add(JsonUtility.ToJson(item));
        }
        if (!Directory.Exists("Assets/07.Data/AudioTracks/"))
        {
            Directory.CreateDirectory("Assets/07.Data/AudioTracks/");

        }
        fileName = fileName + (fileName.Contains(".txt") ? "" : ".txt");


        File.WriteAllLines("Assets/07.Data/AudioTracks/" + fileName
            
            
            
            
            
            
           
            
            
            
            
            
            
            
            
          , data);
    }

    public static List<string>  getAllTracks(string path)
    {
        List<string> tracks = new List<string>();
        tracks.AddRange(Directory.GetFiles(path));
        for (int i = 0; i < tracks.Count; i++)
        {


            tracks[i]= tracks[i].Remove(0, path.Length);
            var item = tracks[i];
            if (!item.Contains(".txt") || item.Contains("meta"))
            {
                tracks.Remove(item);
                i--;
            }
        }
        return tracks;


    }
}
