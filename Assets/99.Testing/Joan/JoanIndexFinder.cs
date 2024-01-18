using Sirenix.OdinInspector;
using Sirenix.Utilities;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.EventSystems;

public class JoanIndexFinder : MonoBehaviour
{
    [SerializeField]
    private OVRSkeleton handSkeleton = null;
    [SerializeField]
    private OVRInputModule inputModule = null;

    [ShowInInspector, ReadOnly]
    private readonly string indexName = "Hand_IndexTip";

    public UnityEvent<Transform> OnIndexTipFound = null;

    private void Start()
    {
        StartCoroutine(TryToInitialize());
    }

    private IEnumerator TryToInitialize()
    {
        while (true)
        {
            bool succeed = true;
            try
            {
                FindIndex();
            }
            catch
            {
                succeed = false;
            }

            if (succeed)
            {
                break;
            }

            yield return null;
        }
    }

    [Button]
    private void FindIndex()
    {
        OVRBone indexTip = handSkeleton.Bones.First(bone => bone.Id == OVRSkeleton.BoneId.Hand_IndexTip);
        if (indexTip != null)
        {
            OnIndexTipFound?.Invoke(indexTip.Transform);
            Debug.Log("Index tip found!");
            inputModule.rayTransform = indexTip.Transform;
        }
    }
}
