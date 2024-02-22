using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class DoorFinder : MonoBehaviour
{
    public Transform target;
    // Start is called before the first frame update
    void Start()
    {
        
    }
    private void OnEnable()
    {
        List<GameObject> suitableDoors = FindObjectsOfType<OVRSemanticClassification>()
                  .Where(c => c.Contains(OVRSceneManager.Classification.DoorFrame))
                  .Select(c => c.gameObject)
                  .ToList();
        List<GameObject> suitableFloors = FindObjectsOfType<OVRSemanticClassification>()
                 .Where(c => c.Contains(OVRSceneManager.Classification.Floor))
                 .Select(c => c.gameObject)
                 .ToList();
        if (suitableDoors.Count>0 && suitableFloors.Count>0)
        {
            var newpos= suitableDoors[0].transform.position;
            newpos.y = suitableFloors[0].transform.position.y;
            transform.position = newpos;
        }
        LookAtTarget(target.position);
    }
    public void LookAtTarget(Vector3 targetPosition)
    {
        // Calculate the direction from the current object to the target position
        Vector3 directionToTarget = targetPosition - transform.position;

        // We only want the object to rotate around the Y axis, so we zero out the X and Z components
        directionToTarget.x = 0;
        directionToTarget.z = 0;

        // Check if the direction is not zero (the target is not directly above or below the object)
        if (directionToTarget != Vector3.zero)
        {
            // Calculate the rotation needed to look at the target only on the Y axis
            Quaternion targetRotation = Quaternion.LookRotation(directionToTarget);

            // Apply the rotation to the object, preserving its X and Z rotations
            transform.rotation = Quaternion.Euler(0, targetRotation.eulerAngles.y, 0);
        }
    }
}
