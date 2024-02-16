using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyMG : MonoBehaviour
{
    public float lapseTime = 5f;
    public List<Enemy> enemies;
    int currentIndex;
    float delta;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        delta += Time.deltaTime;
        if(delta>lapseTime)
        {
            delta = 0;
            enemies[currentIndex].transform.localScale = Vector3.Lerp(Vector3.zero, Vector3.one, 0);

            currentIndex = (currentIndex + 1) % enemies.Count;
        }
        enemies[currentIndex].transform.localScale = Vector3.Lerp(Vector3.zero, Vector3.one, delta / lapseTime);
    }
}
