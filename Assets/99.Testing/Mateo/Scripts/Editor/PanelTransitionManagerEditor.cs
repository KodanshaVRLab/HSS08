using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace KVRL.HSS08.Testing
{
    [CustomEditor(typeof(PanelTransitionManager))]
    public class PanelTransitionManagerEditor : Editor
    {
        protected virtual void OnSceneGUI()
        {
            PanelTransitionManager manager = (PanelTransitionManager)target;

            EditorGUI.BeginChangeCheck();
            Vector3 newPos = Handles.PositionHandle(manager.transitionCenter, Quaternion.identity);
            float newRadius = Handles.RadiusHandle(Quaternion.identity, manager.transitionCenter, manager.transitionRadius);

            if (EditorGUI.EndChangeCheck())
            {
                Undo.RecordObject(manager, "Change Transition Settings");
                manager.transitionCenter = newPos;
                manager.transitionRadius = newRadius;
            }
        }
    }
}
