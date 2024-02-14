using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class movementControllerMG : MonoBehaviour
{
    public GameObject movingCharacterPrefab;
    public ShikiriAnimationController currentChar;
    public Transform initialPos;
    
    // Start is called before the first frame update
    void Start()
    {
        
    }
    public void updateXpos(float x)
    {
        initialPos.position = new Vector3(x, initialPos.position.y, initialPos.position.z); ;
    }
    public void updateYpos(float x)
    {
        initialPos.position = new Vector3(initialPos.position.x,x, initialPos.position.z);
    }
    public void updateZpos(float x)
    {
        initialPos.position = new Vector3(initialPos.position.x,initialPos.position.y, x); ;
    }
    public void updateMaxDist(float x)
    {

        if (currentChar)
            currentChar.maxRayDist = x;
    }
    public void updateMaxSpeed(float x)
    {

        if (currentChar)
            currentChar.maxSpeed= x;
    }
    [Button]
    public void resetCharacter()
    {
        if(currentChar)
        {
            Destroy(currentChar.gameObject);

        }
        currentChar = Instantiate(movingCharacterPrefab, initialPos.position, initialPos.rotation).GetComponent<ShikiriAnimationController>() ;
    }
    // Update is called once per frame
    void Update()
    {
        
    }
}
