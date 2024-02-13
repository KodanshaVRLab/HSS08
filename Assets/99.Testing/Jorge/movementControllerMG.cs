using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class movementControllerMG : MonoBehaviour
{
    public GameObject movingCharacterPrefab;
    public GameObject currentChar;
    public Transform initialPos;
    
    // Start is called before the first frame update
    void Start()
    {
        
    }
    public void updateXpos(float x)
    {
        initialPos.position = Vector3.right* x;
    }
    public void updateYpos(float x)
    {
        initialPos.position = Vector3.up * x;
    }
    public void updateZpos(float x)
    {
        initialPos.position = Vector3.forward* x;
    }
    [Button]
    public void resetCharacter()
    {
        if(currentChar)
        {
            Destroy(currentChar);

        }
        currentChar= Instantiate(movingCharacterPrefab, initialPos.position, initialPos.rotation);
    }
    // Update is called once per frame
    void Update()
    {
        
    }
}
