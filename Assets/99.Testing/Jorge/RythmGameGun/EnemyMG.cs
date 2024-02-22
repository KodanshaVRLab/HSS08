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
    public int currentBeatIndex, currentEnemyIndex;
    float delta;

    public VConteManager VCmg;

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
    public Vector3 mikasaOffset = new Vector3(-0.5f, 0f, 0.5f);
    public JoanWallPinner pinner;
    public GameObject testObj;
    public List<Transform> availableAnchors = new List<Transform>();

    private void OnEnable()
    {
        currentBeatIndex = -1;
        List<GameObject> suitableWalls = FindObjectsOfType<OVRSemanticClassification>()
                  .Where(c => c.Contains(OVRSceneManager.Classification.WallFace))
                  .Select(c => c.gameObject)
                  .ToList();

        foreach (var pared in suitableWalls)
        {
            if (testObj)
            {
                var x = Instantiate(testObj, pared.transform.position, pared.transform.rotation);
                availableAnchors.Add(x.transform);
                x.transform.parent = pared.transform;
                x.AddComponent<WallAchor>();
            }
        }

        if (availableAnchors.Count > 0)
        {
            transform.SetPositionAndRotation(availableAnchors[0].position, availableAnchors[0].rotation);
        }
        var wall = wallDetector.FetchRandomWall();
        StartCoroutine(changePos());

        isPlayerRound = false;
        foreach (var enemy in enemies)
        {
            enemy.enemyMG = this;
        }
    }

    IEnumerator moveMikasa(Transform finalPos)
    {
        if (finalPos)
        {
            List<GameObject> suitableFloors = FindObjectsOfType<OVRSemanticClassification>()
                .Where(c => c.Contains(OVRSceneManager.Classification.Floor))
                .Select(c => c.gameObject)
                .ToList();
            Vector3 fPos = finalPos.position + mikasaOffset;
            fPos.y = suitableFloors.Count > 0 ? suitableFloors[0].transform.position.y : fPos.y;
            
            Vector3 initialpos = mikasa.position;
            var delta = 0f;
            while (delta < mikasaShiftDuration)
            {
                mikasa.position = Vector3.Lerp(initialpos, fPos, delta / mikasaShiftDuration);
                delta += Time.deltaTime;
                yield return new WaitForEndOfFrame();
            }

           
            
             LookAtTarget(mikasa, player.position);
        }

    }
    public void LookAtTarget(Transform owner, Vector3 targetPosition)
    {
        // Calculate the direction from the current object to the target position
        Vector3 directionToTarget = targetPosition - owner.position;

        // We only want the object to rotate around the Y axis, so we zero out the X and Z components
        directionToTarget.x = 0;
        directionToTarget.z = 0;

        // Check if the direction is not zero (the target is not directly above or below the object)
        if (directionToTarget != Vector3.zero)
        {
            // Calculate the rotation needed to look at the target only on the Y axis
            Quaternion targetRotation = Quaternion.LookRotation(directionToTarget);

            // Apply the rotation to the object, preserving its X and Z rotations
            owner.rotation = Quaternion.Euler(0, targetRotation.eulerAngles.y, 0);
        }
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

            transform.position = anchor.transform.position + (anchor.transform.forward * distFromWall);
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
        if (VCmg.isSongPlaying())
        {
            if(currentBeatIndex<0)
            {
                currentBeatIndex = getStartIndex();
            }
            if (currentBeatIndex >= 0 && currentBeatIndex < beats.Count - 3)
            {
                Debug.Log(VCmg.currentSongTime);
                if ( VCmg.currentSongTime >= beats[currentBeatIndex].time)
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
                        nextEnemy = getRandomEnemy();
                        if (nextEnemy == null) return;
                        
                        lastRoundEnemies.Enqueue(nextEnemy);
                        if (!IgnoreMikasa)
                            mRC.updateTarget(nextEnemy.transform);

                    }
                    else
                    {
                        if (mRC)
                            mRC.disablePointing();
                        nextEnemy = lastRoundEnemies.Dequeue();
                        


                    }
                    nextEnemy.beatEnemy((minBeatDuration + beats[currentBeatIndex + 3].time) - beats[currentBeatIndex].time, isPlayerRound || IgnoreMikasa);
                    currentBeatIndex = getNextIndex();

                }
            }
        }

    }
    int getStartIndex()
    {
        for (int i = 0; i < beats.Count; i++)
        {
            if (beats[i].time >= VCmg.currentSongTime)
            {
                return i;
            }
        }
        return -1;
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
    int tries = 0;
    public Enemy getRandomEnemy()
    {
        int random = Random.Range(0, enemies.Count);
        if (!enemies[random].isActive)
        {
            tries = 0;
            return enemies[random];
        }
        else if (tries < 4)
        {
            tries++;
            return getRandomEnemy();
        }
        else
            return null;
        
    }
}
