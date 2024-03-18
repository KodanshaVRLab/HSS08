using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MaterialKeywordSetter : MonoBehaviour
{
    [SerializeField] Material[] targets;
    [SerializeField] string keyword = "MY_KEYWORD";

    public string Keyword
    {
        get { return keyword; }
    }

    public void SetKeyword(bool state)
    {
        if (state)
        {
            EnableKeyword();
        } else
        {
            DisableKeyword();
        }
    }

    public void EnableKeyword()
    {
        if (targets != null)
        {
            foreach (var target in targets) {
                target.EnableKeyword(keyword);
            }
        }
    }

    public void DisableKeyword()
    {
        if (targets != null)
        {
            foreach (var target in targets)
            {
                target.DisableKeyword(keyword);
            }
        }
    }
    
}
