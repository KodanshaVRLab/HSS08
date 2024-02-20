using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class JoanUIWorldArrow : MonoBehaviour
{
    [SerializeField]
    private RectTransform uiArrow = null;
    [SerializeField]
    private RectTransform arrowFrame = null;
    [SerializeField]
    private Transform worldObject = null;
    [SerializeField]
    private Transform userHead = null;

    [SerializeField]
    private float minAngleToConsiderOutOfScreen = 120f;
    [SerializeField]
    private float animationTime = 1f;
    [SerializeField]
    private AnimationCurve animationCurve = new AnimationCurve(
        new Keyframe[] { new Keyframe(0f, 0f), new Keyframe(0.5f, 1f), new Keyframe(1f, 0f)}
    );
    [SerializeField]
    private float animationDistance = 50f;

    private bool isVisible = true;
    private float animationProgress = 0f;

    private void Awake()
    {
        ForceHide();
    }

    private void ForceHide()
    {
        isVisible = true;
        Hide();
    }

    private void Update()
    {
        bool objectOutOfScreen = CheckIfObjectIsOutOfScreen();

        if (objectOutOfScreen
            && worldObject.gameObject.activeInHierarchy)
        {
            Show();
            UpdateArrowPositionAndRotation();
        }
        else
        {
            Hide();
        }
    }

    private bool CheckIfObjectIsOutOfScreen()
    {
        Vector3 userForward = userHead.forward;
        Vector3 userToObject = (worldObject.position - userHead.position).normalized;

        float dotProduct = Vector3.Dot(userForward, userToObject);
        float approximatedAngle = ApproximateAngleFromDotProduct(dotProduct);

        bool outOfScreen = approximatedAngle > minAngleToConsiderOutOfScreen;
        return outOfScreen;
    }

    private float ApproximateAngleFromDotProduct(float dotProduct)
    {
        float lerpFactor = Mathf.Clamp01(dotProduct * 0.5f + 0.5f);
        float approximatedAngle = Mathf.Lerp(360f, 0f, lerpFactor);
        return approximatedAngle;
    }

    private void Show()
    {
        if (isVisible)
        {
            return;
        }

        isVisible = true;
        uiArrow.localScale = Vector3.one;
        StartAnimation();
    }

    private void StartAnimation()
    {
        TimedActions.Start(this, "ArrowAnimation", animationTime, OnFinished: StartAnimation, OnProgress: AnimationProgress);
    }

    private void AnimationProgress(float progress)
    {
        animationProgress = animationCurve.Evaluate(progress);
    }

    private void Hide()
    {
        if (!isVisible)
        {
            return;
        }

        isVisible = false;
        uiArrow.localScale = Vector3.zero;
        StopAnimation();
    }

    private void StopAnimation()
    {
        TimedActions.Stop(this, "ArrowAnimation");
    }

    private void UpdateArrowPositionAndRotation()
    {
        Vector2 framePosition = GetFramePosition();
        Vector2 anchoredPosition = GetAnchoredPosition(framePosition);
        Vector3 eulerAngles = Get2DRotation(framePosition);

        float angle = eulerAngles.z;
        Vector2 animationMaxPosition = GetAnimationMaxAnchoredPosition(anchoredPosition, angle);
        Vector2 animatedAnchoredPosition = Vector2.Lerp(anchoredPosition, animationMaxPosition, animationProgress);

        uiArrow.anchoredPosition = animatedAnchoredPosition;
        uiArrow.localEulerAngles = eulerAngles;
    }

    private Vector2 GetFramePosition()
    {
        Vector3 userForward = userHead.forward;
        Vector3 userToObject = (worldObject.position - userHead.position).normalized;

        Vector2 horizontalUserForward = new Vector2(userForward.x, userForward.z).normalized;
        Vector2 horizontalUserToObject = new Vector2(userToObject.x, userToObject.z).normalized;
        float horizontalAngle = Vector2.SignedAngle(horizontalUserForward, horizontalUserToObject);
        float clampedHorizontalAngle = Mathf.Clamp(horizontalAngle, -minAngleToConsiderOutOfScreen, minAngleToConsiderOutOfScreen);
        float horizontalProgress = clampedHorizontalAngle / minAngleToConsiderOutOfScreen;
        float horizontalPosition = -0.5f * horizontalProgress;

        float userForwardHorizontalDistance = Mathf.Sqrt(userForward.x * userForward.x + userForward.z * userForward.z);
        Vector2 verticalUserForward = new Vector2(userForwardHorizontalDistance, userForward.y).normalized;
        float userToObjectHorizontalDistance = Mathf.Sqrt(userToObject.x * userToObject.x + userToObject.z * userToObject.z);
        Vector2 verticalUserToObject = new Vector2(userToObjectHorizontalDistance, userToObject.y).normalized;
        float verticalAngle = Vector2.SignedAngle(verticalUserForward, verticalUserToObject);
        float clampedVerticalAngle = Mathf.Clamp(verticalAngle, -minAngleToConsiderOutOfScreen, minAngleToConsiderOutOfScreen);
        float verticalProgress = clampedVerticalAngle / minAngleToConsiderOutOfScreen;
        float verticalPosition = 0.5f * verticalProgress;

        Vector2 framePosition = new Vector2(horizontalPosition, verticalPosition);
        return framePosition;
    }

    private Vector2 GetAnchoredPosition(Vector2 framePosition)
    {
        Vector2 frameSize = arrowFrame.rect.size;
        Vector2 anchoredPosition = framePosition * frameSize;
        return anchoredPosition;
    }

    private Vector3 Get2DRotation(Vector2 framePosition)
    {
        float zAngle = GetZAngleFromFramePosition(framePosition);
        Vector3 eulerAngles = new Vector3(0f, 0f, zAngle);
        return eulerAngles;
    }

    private float GetZAngleFromFramePosition(Vector2 framePosition)
    {
        Vector2 direction = framePosition.normalized;
        float zAngle = Vector2.SignedAngle(Vector2.up, direction);
        return zAngle;
    }

    private Vector2 GetAnimationMaxAnchoredPosition(Vector2 anchoredPosition, float angle)
    {
        float rad = Mathf.Deg2Rad * angle;
        Vector2 direction = new Vector2(-Mathf.Sin(rad), Mathf.Cos(rad));
        float distance = animationDistance;
        Vector2 animationAnchoredPosition = anchoredPosition - direction * distance;
        return animationAnchoredPosition;
    }
}