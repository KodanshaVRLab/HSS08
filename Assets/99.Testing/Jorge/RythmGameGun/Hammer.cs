using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Hammer : MonoBehaviour
{
    public Transform shootPos;
    public float maxDistance = 5f;
    public LayerMask targetLayerMask;



    public List<GameObject> Enviroments;
    public bool canUse;
    public float coolOffTime;
    int currentEnv = 0;
    public OVRManager ovr;
    public GameObject moonENV;
    // Start is called before the first frame update

    private void OnTriggerEnter(Collider other)
    {
        HammerTarget hTarget;
        if (other.transform.TryGetComponent<HammerTarget>(out hTarget))
        {
            hTarget.onHit();


        }
    }
    public void toggleENV()
    {
        moonENV.SetActive(ovr && !ovr.isInsightPassthroughEnabled);
    }
    private void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawLine(shootPos.position,
            shootPos.position+ shootPos.forward * maxDistance);
    }
    
    // Update is called once per frame
    void Update()
    {
         
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
