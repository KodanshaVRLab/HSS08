using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public class HammerTarget : MonoBehaviour
{
    public float duration = 3f;
    public int hitAmount=5;
    public int currentHits = 0;
    public Image hitGauge;
    public Transform hairCrossT;
    bool isActive;
    public Vector2 hitAmountRange= new Vector2(3f,15f);
    public Vector2 hairCrossSize = new Vector2(0f, 4f);

    public UnityEvent onTargetDestroyed;
    public Transform target, player;
    public float playerToTargetDist = 0.231f;
    LineRenderer lr;
    AudioSource source;
    AudioClip hitClip;
    public void setup()
    {
        
        target = transform;
        target.position = player.position + player.forward * playerToTargetDist- player.up*playerToTargetDist;
        StartCoroutine(activateTarget());
    }
    [Button]
    public void onHit()
    {
        if (isActive)
        {
            float delta = currentHits / (float)hitAmount;
            hitGauge.fillAmount = delta;
            hitGauge.color = Color.Lerp(Color.red, Color.green, delta);
            if (delta >= 1f)
            {
                onTargetDestroyed.Invoke();
                Destroy(gameObject);
            }
            if (source && hitClip)
                source.PlayOneShot(hitClip);
            currentHits++;
        }
        

    }
    public void Activate()
    {
        setup();
    }
    public IEnumerator activateTarget()
    {
        isActive = true;
        
        currentHits = 0;
        var delta = 0f;
        while(delta<duration)
        {
            delta += Time.deltaTime;
            yield return new WaitForEndOfFrame();
            hairCrossT.localScale = Vector3.Lerp(Vector3.one* hairCrossSize.y, Vector3.one* hairCrossSize.x, delta / duration);


        }
        currentHits = 0;
        isActive = false;
        gameObject.SetActive(false);
    }
    // Start is called before the first frame update
    void Start()
    {
        lr = GetComponent<LineRenderer>();
        hitAmount = (int) Random.Range(hitAmountRange.x, hitAmountRange.y);
        source = GetComponent<AudioSource>();
    }

    // Update is called once per frame
    void Update()
    {
        if(lr)
        {
            lr.SetPosition(0, transform.position);
            if(player)
            lr.SetPosition(1, player.position);
        }
    }
}
