using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HandInteractor : MonoBehaviour
{
    public GameObject sphereCollider,vrButton;
    public OVRSkeleton skeleton;
    OVRHand hand;
    // Start is called before the first frame update
     
    IEnumerator Start()
    {
        yield return new WaitForSeconds(3f);
        skeleton = GetComponent<OVRSkeleton>();
        hand = GetComponent<OVRHand>();
        if(!skeleton || !sphereCollider || !hand)
        {
            Destroy(this);
        }

        if (skeleton.Bones.Count > 0 && vrButton)
        {
            vrButton.transform.parent = skeleton.Bones[0].Transform;
            vrButton.transform.localPosition = Vector3.zero;
            vrButton.transform.localRotation = Quaternion.identity;
            vrButton.SetActive(true);
        }
        if (skeleton.Bones.Count >= 20) 
        {
            var IndexTransform = skeleton.Bones[20].Transform;
            if (IndexTransform)
            {
                sphereCollider.transform.parent= IndexTransform;
                sphereCollider.transform.localPosition = Vector3.zero;
                sphereCollider.transform.localRotation = Quaternion.identity;
                sphereCollider.SetActive(true);
            }

        }
        

       
    }

    // Update is called once per frame
    void Update()
    {
        if(Input.GetKeyDown(KeyCode.Space))
        {
            StartCoroutine(Start());
        }
    }
}
