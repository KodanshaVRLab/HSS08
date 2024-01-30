using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using Sirenix.OdinInspector;
using UnityEngine.Events;

public class JoanMusicPlayerVisualizer : MonoBehaviour
{
    private enum DurationMode
    {
        Duration,
        RemainingTime
    }

    public UnityEvent<string> onSongNameChanged = null;
    public UnityEvent<string> onTimeTextChanged = null;
    public UnityEvent<string> onDurationTextChanged = null;

    public UnityEvent<float> onTimeProgressChanged = null;
    public UnityEvent onPlay = null;
    public UnityEvent onPause = null;
    public UnityEvent onResume = null;
    public UnityEvent onStop = null;

    public UnityEvent onMuted = null;
    public UnityEvent onUnmuted = null;
    public UnityEvent<float> onVolumeChanged = null;
    public UnityEvent onMinVolume = null;
    public UnityEvent onMidVolume = null;
    public UnityEvent onMaxVolume = null;

    public UnityEvent onShuffleEnabled = null;
    public UnityEvent onShuffleDisabled = null;

    public UnityEvent onNoLoopMode = null;
    public UnityEvent OnLoopListMode = null;
    public UnityEvent onLoopSongMode = null;

    [ShowInInspector, ReadOnly]
    private DurationMode durationMode = DurationMode.Duration;

    private AudioClip currentSong = null;
    private float currentTime = 0f;
    private float duration = 0f;

    public void SongChanged(AudioClip clip)
    {
        currentSong = clip;
        onSongNameChanged?.Invoke(clip.name);
        duration = clip.length;
        onPlay?.Invoke();
        SetTime(0f);

        if (durationMode == DurationMode.Duration)
        {
            UpdateDurationTime();
        }
    }

    public void SetTime(float time)
    {
        currentTime = time;
        OnTimeChanged();
    }

    private void OnTimeChanged()
    {
        string timeText = TimeToText(currentTime);
        onTimeTextChanged?.Invoke(timeText);
        if (durationMode == DurationMode.RemainingTime)
        {
            UpdateRemainingTime();
        }

        float progress = duration > 0f
            ? Mathf.Clamp01(currentTime / duration)
            : 0f;
        onTimeProgressChanged.Invoke(progress);
    }

    private void UpdateDurationTime()
    {
        string durationText = TimeToText(duration);
        onDurationTextChanged?.Invoke(durationText);
    }

    private string TimeToText(float time)
    {
        int minutes = Mathf.FloorToInt(time / 60f);
        int seconds = Mathf.FloorToInt(time - minutes * 60f);
        string text = $"{minutes}:{seconds:D2}";
        return text;
    }

    private void UpdateRemainingTime()
    {
        string durationText = RemainingTimeToText(currentTime);
        onDurationTextChanged?.Invoke(durationText);
    }

    private string RemainingTimeToText(float time)
    {
        float remainingTime = Mathf.Max(duration - time, 0f);
        string unsignedTimeText = TimeToText(remainingTime);
        string text = $"-{unsignedTimeText}";
        return text;
    }

    public void OnPause()
    {
        onPause?.Invoke();
    }

    public void OnResume()
    {
        onResume?.Invoke();
    }

    public void OnStop()
    {
        onStop?.Invoke();
    }

    public void SetDurationMode()
    {
        if (durationMode == DurationMode.Duration)
        {
            return;
        }

        durationMode = DurationMode.Duration;
        UpdateDurationTime();
    }

    public void SetRemainingTimeMode()
    {
        if (durationMode == DurationMode.RemainingTime)
        {
            return;
        }

        durationMode = DurationMode.RemainingTime;
        UpdateRemainingTime();
    }

    public void OnMuteChanged(bool muted)
    {
        Debug.Log($"OnMuteChanged: {muted}");
        if (muted)
        {
            onMuted?.Invoke();
        }
        else
        {
            onUnmuted?.Invoke();
        }
    }

    public void OnShuffleChanged(bool shuffle)
    {
        if (shuffle)
        {
            onShuffleEnabled?.Invoke();
        }
        else
        {
            onShuffleDisabled?.Invoke();
        }
    }

    public void OnVolumeChanged(float volume)
    {
        onVolumeChanged?.Invoke(volume);

        if (volume == 0f)
        {
            onMinVolume?.Invoke();
        }
        else if (volume == 1f)
        {
            onMaxVolume?.Invoke();
        }
        else 
        {
            onMidVolume?.Invoke();
        }
    }

    public void OnLoopModeChanged(JoanMusicPlayer.LoopMode loopMode)
    {
        switch (loopMode)
        {
            case JoanMusicPlayer.LoopMode.None:
                onNoLoopMode?.Invoke();
                break;

            case JoanMusicPlayer.LoopMode.ListLoop:
                OnLoopListMode?.Invoke();
                break;

            case JoanMusicPlayer.LoopMode.SongLoop:
                onLoopSongMode?.Invoke();
                break;
        }
    }
}