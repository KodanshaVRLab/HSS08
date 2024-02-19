using System;
using System.Collections;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

public class RythmObject : MonoBehaviour,IRythmObject
{
    public float InteractionDuration = 2f;
    MaterialPropertyBlock mpb, circleMBP;
    static readonly int shaderColor = Shader.PropertyToID("_Color");

    private void OnEnable() => RythmDemo.rythmObjects.Add(this);
    private void OnDisable() => RythmDemo.rythmObjects.Remove(this);
    CancellationTokenSource ctKn, lerpColorCTKN;

    int colorDelta;
    int circleDelta;
    void Start()
    {
        setColor(Color.red);
        if (useCircle && quad)
        {
            colorDelta = Shader.PropertyToID("_DeltaColor");
            circleDelta = Shader.PropertyToID("_InnerRadius");
            circleMBP = new MaterialPropertyBlock();
            circleMBP.SetFloat(colorDelta, 0);
            circleMBP.SetFloat(circleDelta, 0);
            quad.SetPropertyBlock(circleMBP);
        }

    }
    void setColor(Color newColor)
    {
        mpb = new MaterialPropertyBlock();
        mpb.SetColor(shaderColor, newColor);
        GetComponentInChildren<Renderer>().SetPropertyBlock(mpb);
    }
    [NaughtyAttributes.Button]
    public virtual void setOn()
    {
        if (ctKn == null)
        {
            ctKn = new CancellationTokenSource();
            setOff((int)(InteractionDuration*1000));
        }
        else
        {
            ctKn.Cancel();
        }

       // setColor(Color.green);
       
    }
    [NaughtyAttributes.Button]
    public virtual void interaction()
    {
        
        if (ctKn != null)
        {
            ctKn.Cancel();

        }
    }
    private void OnDestroy()
    {
        if (ctKn != null)
        {
            ctKn.Cancel();

        }
        if (lerpColorCTKN != null)
        {
            lerpColorCTKN.Cancel();

        }
    }


    public async virtual void setOff(int duration)
    { 
        try
        {
            changecolor((duration/1000f)/2f);
            await Task.Delay(duration, ctKn.Token);
            
        }
        catch (OperationCanceledException)
        {
            
            setColor(Color.red);
            if(lerpColorCTKN!=null)
            {
                lerpColorCTKN.Cancel();
            }

        }
        finally
        {
 
            ctKn = null;
            
        }
        
    }
    [Range(0.1f,10f)]
    public float duration = 2;

    [Range(1, 1000)]
    public int stepDuration = 2;

    [NaughtyAttributes.Button]
    public void changecolor()
    {
        if (lerpColorCTKN != null)
        {
            lerpColorCTKN.Cancel();
        }
        else
        {
            lerpColorCTKN = new CancellationTokenSource();
            lerpColor(Color.red, Color.green, duration, stepDuration, () => doshit("cac"));

        }
    }
    public void changecolor(float Lduration, bool loop=true)
    {
        if (lerpColorCTKN != null)
        {
            lerpColorCTKN.Cancel();
        }
        else
        {

            lerpColorCTKN = new CancellationTokenSource();
        }
        Action ac=null;
        if(loop)
        {
            if (lerpColorCTKN == null)
            {
                lerpColorCTKN = new CancellationTokenSource();
            }
            ac = () => lerpColor(Color.green, Color.red, Lduration, stepDuration, null,false);
        }
         
        lerpColor(Color.red, Color.green, Lduration, stepDuration,ac);
    }
    void doshit(string x)
    {
        Debug.Log(x);
    }
    public float totalDuration;
  public float remainingtime;
  public  Renderer quad;
    public bool useCircle = true;
    public async void lerpColor(Color startColor, Color EndColor, float duration, int stepDuration = 10, Action onEnd=null, bool On=true)
    {
         totalDuration =duration * 1000;
         float lerpTime = Time.time;
         remainingtime = Time.time+duration;
         Color newColor = startColor;
        
        while (remainingtime >Time.time)
        {
            try
            {
                await Task.Delay(stepDuration, lerpColorCTKN.Token);
                float delta = (Time.time - lerpTime) / duration;
                newColor = Color.Lerp(startColor, EndColor, delta);
                if (useCircle && On && quad && circleMBP != null)
                {
                    circleMBP.SetFloat(colorDelta, delta);
                    circleMBP.SetFloat(circleDelta, 1 - delta);
                    quad.SetPropertyBlock(circleMBP);
                }

                setColor(newColor);
            }
            catch(OperationCanceledException)
            {
 
                setColor(Color.red);
                remainingtime = 0;
                if (useCircle && On && quad && circleMBP != null)
                {
                    circleMBP.SetFloat(colorDelta, 0);
                    circleMBP.SetFloat(circleDelta, 0);
                    quad.SetPropertyBlock(circleMBP);
                }
                break;

            }
            finally
            {
               
                

            }

         
        }
        
        if(onEnd!=null)
        {
            onEnd.Invoke();
        }
        else
        lerpColorCTKN = null;
    }
    // Update is called once per frame



}
