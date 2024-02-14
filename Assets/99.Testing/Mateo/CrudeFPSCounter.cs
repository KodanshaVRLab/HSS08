using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class CrudeFPSCounter : MonoBehaviour
{
    [SerializeField] TMP_Text counter;
    [SerializeField, Range(1, 60)] int averageRange = 5;

    private float lastFrame = 0;
    private float[] frameTimes;
    private int frameCounter = 0;

    private bool skipFrame = false;

    [SerializeField] bool debugVerbose = false;

    private void OnValidate()
    {
        if (counter == null)
        {
            if (TryGetComponent(out counter))
            {
                Debug.Log($"Auto-assigned TMP Text found in {name}!");
            }
        }

        RebuildFrameArray();
    }

    private void Awake()
    {
        RebuildFrameArray();
    }

    // Update is called once per frame
    void Update()
    {
        RecordFrame();
        UpdateCounter();
    }

    void RebuildFrameArray()
    {
        frameTimes = new float[averageRange];
        skipFrame = true;
    }

    void RecordFrame()
    {
        float thisFrame = Time.unscaledTime;
        float frameTime = thisFrame - lastFrame;

        frameTimes[frameCounter] = frameTime;

        lastFrame = thisFrame;
        frameCounter = (frameCounter + 1) % averageRange;

        if (debugVerbose)
        {
            Debug.Log($"Recorded Frame Time: {frameTime}", gameObject);
        }
    }

    void UpdateCounter()
    {
        if (skipFrame)
        {
            skipFrame = false;
            return;
        }

        if (counter  != null)
        {
            float averageTime = 0;
            for (int i = 0; i < frameTimes.Length; i++)
            {
                averageTime += frameTimes[i];
            }
            averageTime /= (float)averageRange;

            float fps = 1.0f / averageTime;

            counter.text = $"Crude FPS: {fps:F2} ({averageTime*1000:F1}ms)";
        }
    }
}
