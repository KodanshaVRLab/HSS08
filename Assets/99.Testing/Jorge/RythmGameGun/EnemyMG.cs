using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using Sirenix.OdinInspector;
using KVRL.KVRLENGINE.Utilities;
using System.Linq;

public class EnemyMG : MonoBehaviour
{
    public float lapseTime = 5f;
    public List<Enemy> enemies;
    [ShowInInspector]
    public Queue<Enemy> lastRoundEnemies = new Queue<Enemy>();

    [ReadOnly]
    public bool isPlayerRound;
    int currentBeatIndex, currentEnemyIndex;
    float delta;

    public AudioSource audioHolder;

    public List<beat> beats;
    public string beatsDataPath;

    public MikasaRythmController mRC;

    public float minBeatDuration = 5f;

    public bool IgnoreMikasa;
    public JoanWallDetector wallDetector;
    public float distFromWall = 0.3f;
    public float roundDuration = 5f;
    public float mikasaShiftDuration = 1f;
    public bool changedWall;
    public Transform mikasa;
    public Transform player;
    public Vector3 mikasaOffset= new Vector3(-0.5f,0f,0.5f);
    public JoanWallPinner pinner;
    public GameObject testObj;
    public List<Transform> availableAnchors= new List<Transform>();

    private IEnumerator Start()
    {

        yield return new WaitForSeconds(5f);
        List<GameObject> suitableWalls = FindObjectsOfType<OVRSemanticClassification>()
                   .Where(c => c.Contains(OVRSceneManager.Classification.WallFace))
                   .Select(c => c.gameObject)                   
                   .ToList();

        foreach (var pared in suitableWalls)
        {
            if (testObj)
            {
               var x= Instantiate(testObj, pared.transform.position, pared.transform.rotation);
                availableAnchors.Add(x.transform);
                x.transform.parent = pared.transform;
                x.AddComponent<WallAchor>();
            }
        }

        if(availableAnchors.Count>0)
        {
            transform.SetPositionAndRotation(availableAnchors[0].position, availableAnchors[0].rotation);
        }
        var wall = wallDetector.FetchRandomWall();        
        StartCoroutine(changePos());
        audioHolder.Play();
        isPlayerRound = false;
        foreach (var enemy in enemies)
        {
            enemy.enemyMG = this;
        }
    }

    IEnumerator moveMikasa(Transform finalPos)
    {
        Vector3 fPos= finalPos.position + mikasaOffset;
        
        fPos.y = player.position.y;
        Vector3 initialpos = mikasa.position;
        var delta = 0f;
        while (delta < mikasaShiftDuration)
        {
            mikasa.position = Vector3.Lerp(initialpos, fPos, delta/mikasaShiftDuration);
            delta += Time.deltaTime;
            yield return new WaitForEndOfFrame();
        }

        
        mikasa.LookAt(player);

    }
    public AudioSource changePosSound;
    IEnumerator changePos()
    {
        changePosSound.Play();
        yield return new WaitForSeconds(roundDuration);
        var wall = wallDetector.FetchRandomWall();
        yield return moveMikasa(wall);
        updatePosition(wall);
        StartCoroutine(changePos());
    }

    public void updatePosition(Transform wall)
    {       
        if (wall && pinner)
        {
            var anchor = wall.GetComponentInChildren<WallAchor>();
            if (!anchor)
                return;

            transform.position = anchor.transform.position+(anchor.transform.forward*distFromWall);
            transform.rotation = anchor.transform.rotation;
            
            
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
                        if(!IgnoreMikasa)
                        mRC.updateTarget(nextEnemy.transform);
                        
                    }
                    else
                    {
                        if (mRC)
                            mRC.disablePointing();
                        nextEnemy = lastRoundEnemies.Dequeue();
                        Debug.Log("gettinh enemy " + nextEnemy.name + "from mikasa enemies");

                       
                    }
                    nextEnemy.beatEnemy((minBeatDuration + beats[currentBeatIndex + 3].time) - beats[currentBeatIndex].time, isPlayerRound || IgnoreMikasa) ;
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
