using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class Gun : MonoBehaviour
{
    public Transform projectile, shootPos;
    public float projectileSpeed = 1f;
    bool isShooting;
    float projectileMovementDelta;
    LineRenderer lr;
    Vector3 startPosition,endPosition;
    public float maxDistance=5f;
     public LayerMask enemyLayerMask, envLayerMask;
     

    public Transform hairCross, hairCrossCenter;

    AudioSource aSource;
    public DecalProjector bulletHole, enemyHole;
    public float bulletHoleDuration = 5f;

    
    void Start()
    {
        aSource = GetComponent<AudioSource>();
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
        if (aSource)
            aSource.Play();
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
        if (Physics.Raycast(r, out hito, enemyLayerMask))
        {
            Debug.Log("Raycast hit " + hito.transform.name);
            Enemy hitEnemy;
            if (hito.transform.TryGetComponent<Enemy>(out hitEnemy))
            {
                if (hitEnemy.isActive)
                {
                    hitEnemy.onShoot();
                    if (Physics.Raycast(r, out hito, envLayerMask))
                    {
                        CreateHole(hito.point, hito.normal, new Vector2(0.4f, 0.8f),-1f,true);
                    }
                }  
              
            }
            else if(bulletHole)
            {
                CreateHole(hito.point,hito.normal, new Vector2(0.2f, 0.4f) ,5f);
            }



            return true;
        }
        return false;
    }

    private void CreateHole(Vector3 pos,Vector3 normal, Vector2 sizeRange, float duration=-1f, bool isEnemyHole=false)
    {
        var decal = Instantiate(isEnemyHole ? enemyHole: bulletHole, pos, Quaternion.identity);
        float size = Random.Range(sizeRange.x, sizeRange.y);
        float angle = Random.Range(-180, 180);

        decal.transform.position = pos;
        decal.transform.LookAt(pos - normal);
        Quaternion rot = Quaternion.AngleAxis(angle, decal.transform.forward);
        decal.transform.rotation = rot * decal.transform.rotation;

        // TODO: Why no work
        decal.size = new Vector3(size, size, 1);
        if(duration>0)
        Destroy(decal, duration);
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

