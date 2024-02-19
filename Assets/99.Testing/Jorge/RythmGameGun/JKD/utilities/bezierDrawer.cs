using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif
public class bezierDrawer : MonoBehaviour
{
    // Start is called before the first frame update
    public Transform[] child;

#if UNITY_EDITOR

    private void OnDrawGizmos()
    {
        if (child.Length>0)
        {
            for (int i = 0; i < child.Length; i++)
            {
                float halfHeight = (transform.position.y - child[i].position.y) * 0.5f;
                Vector3 offset = Vector3.up * halfHeight;
                Handles.DrawBezier(transform.position, child[i].position, transform.position - offset, child[i].position + offset, Color.red, Texture2D.whiteTexture, 0.61f);

            }
        }
    }
#endif
}
