using System.Collections;
using System.Collections.Generic;
using System;
using UnityEngine;
using TMPro;
using Sirenix.OdinInspector;

public class JoanWatchVisualizer : MonoBehaviour
{
    [SerializeField]
    private TMP_Text watchText = null;

    private void Update()
    {
        UpdateText();
    }

    [Button]
    private void UpdateText()
    {
        string currentTime = GetCurrentTimeAsText();
        watchText.text = currentTime;
    }

    private string GetCurrentTimeAsText()
    {
        DateTime now = DateTime.Now;
        string text = now.ToString();
        return text;
    }
}
