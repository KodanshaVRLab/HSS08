using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
 

public class Gun : MonoBehaviour
{
    public Transform projectile, shootPos;
    public float projectileSpeed = 1f;
    bool isShooting;
    float projectileMovementDelta;
    LineRenderer lr;
    Vector3 startPosition,endPosition;
    public float maxDistance=5f;
     public LayerMask layerMask;

    public Transform hairCross, hairCrossCenter;

    void Start()
    {
        lr = GetComponent<LineRenderer>();
        if (lr) lr.enabled = false;
        if (!shootPos)
        {
            shootPos = transform;
        }

    }

    


    [Button]
    public void ShootProjectile()
    {
        if (isShooting) return;
        if (lr) lr.enabled = true;
        projectileMovementDelta = 0;
        isShooting = true;
        projectile.gameObject.SetActive(true);

        startPosition = shootPos.position;
        endPosition = transform.position+transform.forward * maxDistance;
        projectile.parent = null;
        checkCollision();
    }
    public bool checkCollision()
    {
        Ray r = new Ray(shootPos.position,  shootPos.forward * maxDistance);
        RaycastHit hito;
        if (Physics.Raycast(r,out hito, layerMask))
        {
            Debug.Log("Raycast hit " + hito.transform.name);
            Enemy hitEnemy;
            if(hito.transform.TryGetComponent<Enemy>(out hitEnemy))
            {
                if(hitEnemy.isActive)
                {
                    hitEnemy.onShoot();
                }
            }
            return true;
        }
        return false;
    }
    // Update is called once per frame
    void Update()
    {
        if(hairCross && hairCrossCenter)
        {
            hairCross.localPosition = new Vector3(hairCross.localPosition.x,hairCross.localPosition.y, maxDistance);
            hairCrossCenter.localPosition = new Vector3(hairCrossCenter.localPosition.x, hairCrossCenter.localPosition.y, maxDistance);
        }

        if (isShooting && projectileMovementDelta < 1f)
        {
            if (lr)
            {
                lr.SetPosition(0, shootPos.position);
                lr.SetPosition(1, projectile.position);
            }

            projectile.position = Vector3.Lerp(startPosition, endPosition, projectileMovementDelta);
            projectileMovementDelta += Time.deltaTime * projectileSpeed;

            if (projectileMovementDelta >= 1f)
            {
                if (lr) lr.enabled = false;
                isShooting = false;
                projectile.position = shootPos.position;
                projectile.gameObject.SetActive(false);
                projectile.parent = transform;
            }
           
        }
    }
}

