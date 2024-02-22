using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Hammer : MonoBehaviour
{
    public Transform shootPos;
    public float maxDistance = 5f;
    public LayerMask targetLayerMask;


    public Transform leftHand, rightHand;
    public float maxHandDist = 0.35f;
    public List<GameObject> Enviroments;
    public bool canUse;
    public float coolOffTime;
    int currentEnv = 0;
    public VConteManager ovr;
    public GameObject moonENV;
    bool doCheck=false;
    public List<GameObject> meshes;
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
        moonENV.SetActive(ovr && !ovr.isPassthrough);
    }
    private void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawLine(shootPos.position,
            shootPos.position+ shootPos.forward * maxDistance);
    }
    private void OnEnable()
    {
        doCheck = true;
    }
    // Update is called once per frame
    void Update()
    {
         if(doCheck && leftHand && rightHand)
        {
            
            foreach (var item in meshes)
            {
                item.SetActive(rightHand.InverseTransformPoint(leftHand.position).y < 0 && CalculateDistanceIgnoreY(leftHand.position, rightHand.position) < maxHandDist);
            }
            
            
        }
    }

    float CalculateDistanceIgnoreY(Vector3 positionA, Vector3 positionB)
    {
        // Set Y components to be the same, effectively ignoring height differences
        positionA.y = 0;
        positionB.y = 0;
        
        // Calculate and return the distance
        return Vector3.Distance(positionA, positionB);
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
