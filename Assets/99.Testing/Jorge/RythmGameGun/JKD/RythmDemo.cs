using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RythmDemo : MonoBehaviour
{
    // Start is called before the first frame update
    public static List<RythmObject> rythmObjects = new List<RythmObject>();
 
    public static int remainingButtons;
    public static float score = 0f;
    public static TextMesh Tmesh;
    public static Renderer powerBar;
     public static void AddScore(float ammount)
    {
        score += ammount;
        score = Mathf.Min(100, Mathf.Max(0, score));
      //  AkSoundEngine.SetRTPCValue("Score1", score);
      //  AkSoundEngine.SetRTPCValue("Score2", score / 2f);
        if (Tmesh)
            Tmesh.text = score.ToString();
      //  if (powerBar)
            //powerBar.material.SetFloat("_Power", Mathf.Max(0, Mathf.Min(1,score / 100f)));
        
    }
   
    private void Start()
    {
         AddScore(0);
     //   Tmesh = GameObject.Find("SCORETM").GetComponent<TextMesh>() ;
        powerBar = GameObject.Find("powerBar").GetComponent<Renderer>();

    }
      int trys = 0;
    
    
}
