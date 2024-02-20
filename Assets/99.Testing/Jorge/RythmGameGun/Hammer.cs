using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Hammer : MonoBehaviour
{
    public Transform  shootPos;
    public float maxDistance = 5f;
    public LayerMask  targetLayerMask;

    public Transform target,player;
    public float playerToTargetDist = 1f;
    public List<GameObject> Enviroments;
    public bool canUse;
    public float coolOffTime;
    int currentEnv=0;
    // Start is called before the first frame update
    IEnumerator Start()
    {
        yield return new WaitForSeconds(2f);
        setup();
    }

    public void setup()
    {
        target.position = player.position + player.forward * playerToTargetDist;
    }
    // Update is called once per frame
    void Update()
    {
        Ray r = new Ray(shootPos.position, shootPos.forward * maxDistance);
        RaycastHit hito;
        if (Physics.Raycast(r, out hito, targetLayerMask))
        {
            Debug.Log("Raycast hit " + hito.transform.name);
            if(canUse)
            StartCoroutine(ChangeEnv());
        }
    }


    public IEnumerator ChangeEnv()
    {
        canUse = false;
        Enviroments[currentEnv].SetActive(false);
        currentEnv = (currentEnv + 1) % Enviroments.Count;
        Enviroments[currentEnv].SetActive(true);
        yield return new WaitForSeconds(coolOffTime);
        canUse = true;

    }
}
