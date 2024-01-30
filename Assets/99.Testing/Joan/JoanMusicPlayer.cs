using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class JoanMusicPlayer : MonoBehaviour
{
    public enum LoopMode
    {
        None,
        ListLoop,
        SongLoop
    }

    [SerializeField]
    private List<AudioClip> musicList = new List<AudioClip>();
    [SerializeField]
    private AudioSource musicAudioSource = null;
    [SerializeField]
    private bool playOnStart = true;

    public UnityEvent<AudioClip> onSongStarted = null;
    public UnityEvent onPaused = null;
    public UnityEvent onResumed = null;
    public UnityEvent onStopped = null;
    public UnityEvent<float> onTimeChanged = null;

    public UnityEvent<float> onVolumeChanged = null;
    public UnityEvent<bool> onMuteChanged = null;
    public UnityEvent<bool> onShuffleChanged = null;

    public UnityEvent<LoopMode> onLoopModeChanged = null;

    [ShowInInspector, ReadOnly]
    private bool isPlaying = false;
    [ShowInInspector, ReadOnly]
    private bool isPaused = false;
    [ShowInInspector, ReadOnly]
    private bool isScrollingTime = false;
    [ShowInInspector, ReadOnly]
    private LoopMode loopMode = LoopMode.None;
    [ShowInInspector, ReadOnly]
    private bool shuffle = false;
    [ShowInInspector, ReadOnly]
    private int currentClipIndex = 0;
    [ShowInInspector, ReadOnly]
    private AudioClip currentClip = null;

    private readonly List<int> historic = new List<int>();
    private int historicIndex = 0;

    private void Start()
    {
        CheckVolume();
        if (playOnStart
            && currentClip == null)
        {
            Play();
        }
    }

    private void CheckVolume()
    {
        onVolumeChanged?.Invoke(musicAudioSource.volume);
    }

    [Button]
    public void Play()
    {
        if (isPlaying)
        {
            return;
        }

        PlayMusicAtIndex(currentClipIndex, true);
    }

    [Button]
    public void Pause()
    {
        if (!isPlaying
            || isPaused)
        {
            return;
        }

        isPaused = true;
        musicAudioSource.Pause();
        onPaused?.Invoke();
    }

    [Button]
    public void Resume()
    {
        isPaused = false;
        onResumed?.Invoke();

        if (isScrollingTime)
        {
            return;
        }

        musicAudioSource.UnPause();
        if (!isPlaying)
        {
            Play();
        }
    }

    [Button]
    public void Stop()
    {
        if (!isPlaying)
        {
            return;
        }

        isPlaying = false;
        musicAudioSource.Stop();
        SetTimeProgress(0f);
        onStopped?.Invoke();
    }

    [Button]
    public void SetNoLoopMode()
    {
        if (loopMode == LoopMode.None)
        {
            return;
        }

        loopMode = LoopMode.None;
        musicAudioSource.loop = false;
        onLoopModeChanged?.Invoke(LoopMode.None);
    }

    [Button]
    public void SetLoopListMode()
    {
        if (loopMode == LoopMode.ListLoop)
        {
            return;
        }

        loopMode = LoopMode.ListLoop;
        musicAudioSource.loop = false;
        onLoopModeChanged?.Invoke(LoopMode.ListLoop);
    }

    [Button]
    public void SetLoopSongMode()
    {
        if (loopMode == LoopMode.SongLoop)
        {
            return;
        }

        loopMode = LoopMode.SongLoop;
        musicAudioSource.loop = true;
        onLoopModeChanged?.Invoke(LoopMode.SongLoop);
    }

    [Button]
    public void SetVolume(float volume)
    {
        volume = Mathf.Clamp01(volume);
        if (volume == musicAudioSource.volume)
        {
            return;
        }

        musicAudioSource.volume = volume;
        Unmute();

        onVolumeChanged?.Invoke(volume);
    }

    [Button]
    public void AddVolume(float volume)
    {
        SetVolume(musicAudioSource.volume + volume);
    }

    [Button]
    public void RemoveVolume(float volume)
    {
        SetVolume(musicAudioSource.volume - volume);
    }

    [Button]
    public void Mute()
    {
        musicAudioSource.mute = true;
        onMuteChanged?.Invoke(true);
    }

    [Button]
    public void Unmute()
    {
        musicAudioSource.mute = false;
        onMuteChanged?.Invoke(false);
    }

    [Button]
    public void SetShuffle(bool shuffle)
    {
        this.shuffle = shuffle;
        onShuffleChanged?.Invoke(shuffle);
    }

    [Button]
    public void PlayNext()
    {
        if (!CanPlayNext())
        {
            return;
        }

        int nextIndex = currentClipIndex;
        bool storeInHistoric = true;
        if (!shuffle)
        {
            nextIndex++;
            if (nextIndex >= musicList.Count)
            {
                nextIndex = 0;
            }
        }
        else
        {
            if (HasNextIndexInHistoric())
            {
                nextIndex = RecoverNextIndexFromHistoric();
                storeInHistoric = false;
            }
            else
            {
                nextIndex = GetRandomIndex();
            }
        }

        PlayMusicAtIndex(nextIndex, storeInHistoric);
    }

    public bool CanPlayNext()
    {
        bool can = currentClipIndex < musicList.Count - 1
            || loopMode == LoopMode.ListLoop
            || shuffle;
        return can;
    }

    private bool HasNextIndexInHistoric()
    {
        return historicIndex < historic.Count;
    }

    private int RecoverNextIndexFromHistoric()
    {
        int index = historic[historicIndex];
        historicIndex++;
        return index;
    }

    private int GetRandomIndex()
    {
        if (musicList.Count <= 1)
        {
            return 0;
        }

        int index = Random.Range(0, musicList.Count - 1);
        if (index == currentClipIndex)
        {
            index++;
        }

        return index;
    }

    private void PlayMusicAtIndex(int index, bool storeInHistoric)
    {
        if (storeInHistoric)
        {
            AddToHistoric(index);
        }

        currentClipIndex = index;
        AudioClip newMusic = musicList[index];
        PlayMusiclip(newMusic);
    }

    private void AddToHistoric(int index)
    {
        if (historicIndex >= historic.Count)
        {
            historic.Add(index);
        }
        else
        {
            historic[historicIndex] = index;
        }

        historicIndex++;
    }

    private void PlayMusiclip(AudioClip clip)
    {
        isPlaying = true;
        currentClip = clip;
        musicAudioSource.clip = clip;
        musicAudioSource.Play();

        onSongStarted?.Invoke(clip);
    }

    [Button]
    public void PlayPrev()
    {
        if (!CanPlayPrev())
        {
            return;
        }

        int prevIndex = currentClipIndex;
        bool storeInHistoric = true;
        if (!shuffle)
        {
            prevIndex--;
            if (prevIndex < 0)
            {
                prevIndex = musicList.Count - 1;
            }
        }
        else
        {
            if (HasPrevIndexInHistoric())
            {
                prevIndex = RecoverPrevIndexFromHistoric();
                storeInHistoric = false;
            }
            else
            {
                Debug.LogError($"Can't play prev music because it's set to shuffle but it's the first music ({prevIndex + 1} of {musicList.Count})");
                return;
            }
        }

        PlayMusicAtIndex(prevIndex, storeInHistoric);
    }

    public bool CanPlayPrev()
    {
        bool can = currentClipIndex < musicList.Count - 1
            || loopMode == LoopMode.ListLoop
            || shuffle;
        return can;
    }

    private bool HasPrevIndexInHistoric()
    {
        return historicIndex > 0;
    }

    private int RecoverPrevIndexFromHistoric()
    {
        historicIndex--;
        int index = historic[historicIndex];
        return index;
    }

    private void Update()
    {
        if (!isPlaying)
        {
            return;
        }

        CheckTime();
        CheckMusicHasFinished();
    }

    private void CheckTime()
    {
        if (!musicAudioSource.isPlaying)
        {
            return;
        }

        onTimeChanged?.Invoke(musicAudioSource.time);
    }

    private void CheckMusicHasFinished()
    {
        bool hasFinished = musicAudioSource.time >= musicAudioSource.clip.length
            && !musicAudioSource.loop;

        if (hasFinished)
        {
            PlayNext();
        }
    }

    public void SetTimeProgress(float progress)
    {
        float duration = currentClip != null
            ? currentClip.length
            : 0f;
        float time = Mathf.Clamp(duration * progress, 0f, duration);
        SetTime(time);
    }

    private void SetTime(float time)
    {
        musicAudioSource.time = time;
        onTimeChanged?.Invoke(time);
    }

    public void StartScrollingTime()
    {
        if (isScrollingTime)
        {
            return;
        }

        isScrollingTime = true;
        if (!isPaused)
        {
            musicAudioSource.Pause();
        }
    }

    public void StopScrollingTime()
    {
        if (!isScrollingTime)
        {
            return;
        }

        isScrollingTime = false;
        if (!isPaused)
        {
            musicAudioSource.UnPause();
        }
    }
}