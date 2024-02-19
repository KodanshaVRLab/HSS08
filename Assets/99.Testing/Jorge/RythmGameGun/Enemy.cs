using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Enemy : MonoBehaviour
{
    [MinMaxSlider(0f, 3f)]
    public Vector2 scaleMinMax = new Vector2(0f, 1f);

    public bool isActive;

    public float beatDuration;
    Coroutine activateCO;

    public GameObject onHitFX;
    [Button]
    public void onShoot()
    {
        if (activateCO != null)
        {
            StopCoroutine(activateCO);
        }
        transform.localScale = Vector3.one * Mathf.Lerp(scaleMinMax.x, scaleMinMax.y, 0f);
        isActive = false;
        if (onHitFX)
            Destroy(Instantiate(onHitFX, transform.position, Quaternion.identity), 0.5f);
    }
    public void beatEnemy(float duration)
    {
        beatDuration = duration;
        if (!isActive)
          activateCO=  StartCoroutine(activate());
    }
    IEnumerator activate()
    {
        isActive = true;
        var delta = 0f;
        while (delta < beatDuration)
        {
            delta += Time.deltaTime;
            transform.localScale = Vector3.one * Mathf.Lerp(scaleMinMax.x, scaleMinMax.y, delta / beatDuration);
            yield return new WaitForEndOfFrame();
        }
        transform.localScale = Vector3.one * Mathf.Lerp(scaleMinMax.x, scaleMinMax.y, 0f);
        activateCO = null;
        isActive = false;
    }
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
