using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[SerializeField]
public struct interactableData
{
    public string id;
    public Vector3 position;
    public Quaternion rotation;
    public Vector3 scale;
    
    public interactableData(string id, Vector3 position, Quaternion rotation, Vector3 scale)
    {
        this.id = id;
        this.position = position;
        this.rotation = rotation;
        this.scale = scale;
    }
}
public class MikasaInteractableObject : MonoBehaviour
{
    // Start is called before the first frame update

    public Transform mikasaTransformController;
    public AudioClip audioClip;
    public int animControllerId;
    public TextMesh debugText;
    public interactableData data;

   

 


    [Button]
    public void saveData()
    {
        data = new interactableData(name, mikasaTransformController.position, mikasaTransformController.rotation, mikasaTransformController.localScale);
        var dataString = JsonUtility.ToJson(data);
        PlayerPrefs.SetString(name + "_Data", dataString);
    }
    [Button]
    public void LoadData()
    {
        data = JsonUtility.FromJson<interactableData>(PlayerPrefs.GetString(name + "_Data"));
        Debug.Log("loaded " + data.id);
    }

    [Button]
    public void debugSetupMikasa()
    {
        var x = FindObjectOfType<MikasaController>();
        if (x)
        {
            SetupMikasa(x);
        }
        else
        {
            Debug.LogError("Mikasa not found");
        }
    }
    public void SetupMikasa(MikasaController mikasa)
    {
        if (mikasa && mikasaTransformController)
        {
            if (animControllerId >= 0)
            {
                StartCoroutine(switchAnimator(mikasa));

            }
            else
            {
                mikasa.resetPosition(mikasaTransformController, true);
                if (audioClip)
                {
                    mikasa.PlayAudioClip(audioClip);

                }
            }



        }
    }

    public void SetupMikasa(MikasaController mikasa,Vector3 position)
    {
     /*  if(!MikasaInteractableObjectsMG.Instance.isFirstObject)
        {
            mikasa.WalkToPosition(position);
            MikasaInteractableObjectsMG.Instance.updateCurrent(this);
        }
        else
        {
            mikasa.updateAnimationState(0);
            MikasaInteractableObjectsMG.Instance.updateCurrent(this);
            mikasa.setPosition(position);
        }*/
        

    }

    public IEnumerator switchAnimator(MikasaController mikasa)
    {
        if (mikasa.GetComponentInChildren<Animator>())
            mikasa.GetComponentInChildren<Animator>().SetInteger("State",animControllerId);
        yield return new WaitForEndOfFrame();
        
        mikasa.resetPosition(mikasaTransformController,true);
        if (audioClip)
        {
            mikasa.PlayAudioClip(audioClip);

        }
    }

    public void updateDebugText(string status)
    {
        if(debugText)
        {
            debugText.text = $"updating{status} pos {mikasaTransformController.localPosition}\n rot{mikasaTransformController.localRotation.eulerAngles}\n scale{mikasaTransformController.localScale} \n";
        }
    }

    public void changePositionX(float offset)
    {
        if(mikasaTransformController)
        {
            mikasaTransformController.localPosition += Vector3.right* offset;
        }
        updateDebugText("update pos");
    }
    public void changePositionY(float offset)
    {
        if (mikasaTransformController)
        {
            mikasaTransformController.localPosition += Vector3.up * offset;
        }
        updateDebugText("update pos");
    }
    public void changePositionZ(float offset)
    {
        if (mikasaTransformController)
        {
            mikasaTransformController.localPosition += Vector3.forward* offset;
        }
        updateDebugText("update pos");
    }
    public void changeRotationX(float offset)
    {
        updateDebugText("try update rot");
        if (mikasaTransformController)
        {
            mikasaTransformController.Rotate(offset, 0,0);
        }
        updateDebugText("updated rot");
    }
    /*
     .15-.66  2.04
    1-1 1
     
     */
    public void changeRotationY(float offset)
    {
        updateDebugText("try update rot");
        if (mikasaTransformController)
        {
            mikasaTransformController.Rotate(0, offset, 0);
        }
        updateDebugText("updated rot");
    }
    public void changeRotationZ(float offset)
    {
        updateDebugText("try update rot");
        if (mikasaTransformController)
        {
            mikasaTransformController.Rotate(0, 0, offset);
        }
        updateDebugText("updated rot");
    }
    public void changeScale(float offset)
    {
        if (mikasaTransformController)
        {
            mikasaTransformController.localScale+= Vector3.one * offset;
        }
        updateDebugText("update scale");
    }
    void Start()
    {
        
    }

    


    // Update is called once per frame
    void Update()
    {
        if(Input.GetKeyDown(KeyCode.Z))
        {
            changeRotationZ(5F);
        }

        if (Input.GetKeyDown(KeyCode.X))
        {
            changeRotationZ(-5F);
        }

        if (Input.GetKeyDown(KeyCode.Y))
        {
            changeRotationY(5F);
        }

        if (Input.GetKeyDown(KeyCode.U))
        {
            changeRotationY(-5F);
        }

        if (Input.GetKeyDown(KeyCode.F))
        {
            changeRotationX(5F);
        }

        if (Input.GetKeyDown(KeyCode.G))
        {
            changeRotationX(-5F);
        }
    }
}
