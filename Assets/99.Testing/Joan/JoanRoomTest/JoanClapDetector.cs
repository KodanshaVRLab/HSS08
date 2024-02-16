using Oculus.Interaction.Input;
using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class JoanClapDetector : MonoBehaviour
{
    [SerializeField]
    private Transform head = null;
    [SerializeField]
    private Hand leftHand = null;
    [SerializeField]
    private Hand rightHand = null;
    [SerializeField]
    private float clapDistance = 0.1f;
    [SerializeField]
    private float clapRecoveryDistance = 0.5f;
    [SerializeField]
    private float minDistanceFromHead = 1f;
    [SerializeField]
    private float angleRangeFromHeadForward = 60f;

    public UnityEvent OnClap = null;

    [ShowInInspector, ReadOnly]
    private bool clapAvailable = false;

    private void Update()
    {
        CheckClap();
    }

    private void CheckClap()
    {
        bool clap = false;

        bool left = leftHand.IsTrackedDataValid;
        bool right = rightHand.IsTrackedDataValid;
        //Debug.Log($"Left {left}, right {right}");

        if (left && right)
        {
            leftHand.GetRootPose(out var pose);
            Vector3 leftPosition = pose.position;
            rightHand.GetRootPose(out pose);
            Vector3 rightPosition = pose.position;

            Vector3 headPosition = head.position;
            
            float distanceBetweenPalms = Vector3.Distance(leftPosition, rightPosition);
            float distanceToHead = Vector3.Distance(leftPosition, headPosition);

            Vector3 headForward = head.forward;
            Vector3 headToHand = (leftPosition - headPosition).normalized;
            float dotProduct = Vector3.Dot(headForward, headToHand);

            float lerpFactor = Mathf.Clamp01(dotProduct * 0.5f + 0.5f);
            float approximatedAngle = Mathf.Lerp(360f, 0f, lerpFactor);

            //Debug.Log($"distance between hands {distanceBetweenPalms}, from head {distanceToHead}, angle {approximatedAngle}");

            bool clapCondition = distanceBetweenPalms <= clapDistance
                && distanceToHead > minDistanceFromHead
                && approximatedAngle <= angleRangeFromHeadForward;

            if (clapCondition)
            {
                if (clapAvailable)
                {
                    clap = true;
                }
            }
            else
            {
                bool palmsAreFarEnough = distanceBetweenPalms > clapRecoveryDistance;
                if (palmsAreFarEnough)
                {
                    clapAvailable = true;
                }
            }
        }

        if (clap)
        {
            Clap();
        }
    }

    private void Clap()
    {
        clapAvailable = false;
        OnClap?.Invoke();
    }
}