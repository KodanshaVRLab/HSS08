using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using Sirenix.OdinInspector;

public class EnemyMG : MonoBehaviour
{
    public float lapseTime = 5f;
    public List<Enemy> enemies;
    [ShowInInspector]
    public Queue<Enemy> lastRoundEnemies=new Queue<Enemy>();

    [ReadOnly]
    public bool isPlayerRound;
    int currentBeatIndex, currentEnemyIndex;
    float delta;

    public AudioSource audioHolder;
    
    public List<beat> beats;
    public string beatsDataPath;

    public MikasaRythmController mRC;

    public float minBeatDuration = 5f;
    private IEnumerator Start()
    {
        yield return new WaitForSeconds(5f);
        audioHolder.Play();
        isPlayerRound = false;
        foreach (var enemy in enemies)
        {
            enemy.enemyMG = this;
        }
    }
    [Button]
    public void LoadData()
    {
        if (beatsDataPath != string.Empty)
        {
            beats = loadDatafromLocation(beatsDataPath);
        }
    }
    public static List<beat> loadDatafromLocation(string fileName)
    {
        
        fileName = "Assets/07.Data/AudioTracks/" + fileName + (fileName.Contains(".txt") ? "" : ".txt");
        Debug.Log("Loading from " + fileName);
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

    // Update is called once per frame
    void Update()
    {
        if(audioHolder.isPlaying)
        {
            if(currentBeatIndex>=0 && currentBeatIndex<beats.Count-3)
            {
                if (audioHolder.time >= beats[currentBeatIndex].time)
                {
                    if (lastRoundEnemies.Count >= 4)
                    {

                        isPlayerRound = true;
                    }
                    else if (lastRoundEnemies.Count == 0)
                    {
                        isPlayerRound = false;
                    }
                    Enemy nextEnemy;
                    if (!isPlayerRound)
                    {
                        nextEnemy =  getRandomEnemy();
                        Debug.Log("adding enemy " + nextEnemy.name+ "To mikasa enemies");
                        lastRoundEnemies.Enqueue(nextEnemy);
                        mRC.updateTarget(nextEnemy.transform);
                        
                    }
                    else
                    {
                        if (mRC)
                            mRC.disablePointing();
                        nextEnemy = lastRoundEnemies.Dequeue();
                        Debug.Log("gettinh enemy " + nextEnemy.name + "from mikasa enemies");

                       
                    }
                    nextEnemy.beatEnemy((minBeatDuration+ beats[currentBeatIndex+3].time)-beats[currentBeatIndex].time, isPlayerRound);
                    currentBeatIndex=getNextIndex();
                    
                }
            }
        }
        
    }
    int getNextIndex()
    {
        for (int i = currentBeatIndex; i < beats.Count; i++)
        {
            if(beats[i].time> beats[currentBeatIndex].time+beats[currentBeatIndex].duration+minBeatDuration)
            {
                return i;
            }
        }

        return -1;
    }

    public Enemy getRandomEnemy()
    {
        int random = Random.Range(0, enemies.Count);
        if (!enemies[random].isActive)
            return enemies[random];
        else
            return getRandomEnemy();
    }
}
