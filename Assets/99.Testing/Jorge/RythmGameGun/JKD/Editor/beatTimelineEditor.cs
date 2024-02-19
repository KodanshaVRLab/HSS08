using UnityEngine;

using UnityEditor;
 using System.Collections.Generic;

[CustomEditor(typeof(beatTimeline))]
public class beatTimelineEditor : Editor
{

    List<string> tracks = new List<string>();

    AnimationCurve curve;
    List<Vector3> handlesPositions = new List<Vector3>();
    bool loaded = false;
    float audioTrackTime = 0;
    float offset = 0;
    bool selectionsetup = false;
    float lastOffset = -9999;

    Vector2 initialMP = Vector2.zero;
    Vector2 finalMP = Vector2.zero;

    SerializedProperty audioTrackHolder;
    SerializedProperty Loadedbeats;
    SerializedProperty edit;
    SerializedProperty EditLayers, NormalLayers;


    private void OnEnable()
    {
        audioTrackHolder = serializedObject.FindProperty("audioTrackHolder");
        Loadedbeats = serializedObject.FindProperty("loadedBeats");
        edit= serializedObject.FindProperty("edit");
        NormalLayers = serializedObject.FindProperty("NonEditorLayers");
        EditLayers = serializedObject.FindProperty("EditorLayers");
    }
    
    public void calculateGraph(beatTimeline timeline)
    {
        timeline.graphic();
        if (timeline.graphicPositions.Count > 0)
        {
            curve = AnimationCurve.Linear(0, 0, timeline.graphicPositions[timeline.graphicPositions.Count - 1].x,
                                             10);

            for (int i = 0; i < timeline.graphicPositions.Count; i++)
            {
                int x = curve.AddKey(timeline.graphicPositions[i].x, timeline.graphicPositions[i].y);
                if (x == -1)
                    curve.AddKey(timeline.graphicPositions[i].x + Random.Range(0f, 0.000001f), timeline.graphicPositions[i].y + Random.Range(0f, 0.000001f));



            }
            for (int i = 0; i < curve.length; i++)
            {
                AnimationUtility.SetKeyLeftTangentMode(curve, i, AnimationUtility.TangentMode.Constant);
                AnimationUtility.SetKeyRightTangentMode(curve, i, AnimationUtility.TangentMode.Constant);

            }

            handlesPositions.Clear();
            rectangles.Clear();
            for (int i = 4; i < timeline.graphicPositions.Count - 1; i += 8)
            {
                handlesPositions.Add(timeline.graphicPositions[i]);
                rectangles.Add(new Rect(new Vector2(timeline.graphicPositions[i].x, timeline.graphicPositions[i].y), new Vector2(0.05f, 0.05f)));
                handlesPositions.Add(timeline.graphicPositions[i + 1]);
                rectangles.Add(new Rect(new Vector2(timeline.graphicPositions[i + 1].x, timeline.graphicPositions[i + 1].y), new Vector2(0.05f, 0.05f)));


            }
        }
    }
    
    void selectionChanged()
    {
        beatTimeline timeline = target as beatTimeline;
        if (target && Selection.activeObject && Selection.activeObject.name == target.name )
        {
             
        }
        else
        {
            Tools.visibleLayers = timeline.NonEditorLayers;
            SceneView.lastActiveSceneView.Repaint();
        }
    }
    public override void OnInspectorGUI()
    {

        // base.OnInspectorGUI();
        EditorGUILayout.PropertyField(NormalLayers);
        EditorGUILayout.PropertyField(EditLayers);
        EditorGUILayout.PropertyField(edit);
        EditorGUILayout.PropertyField(audioTrackHolder);
        serializedObject.ApplyModifiedProperties();

        if (!Application.isPlaying && Event.current.type== EventType.Repaint)
        {
            var timeline = target as beatTimeline;
            Setup(timeline);

            if (timeline.edit)
            {
                EditorGUILayout.PropertyField(Loadedbeats);
                serializedObject.ApplyModifiedProperties();

                if (CommonEditor.settingsNames.Count > 0)
                {
                    GUILayout.BeginHorizontal();
                    GUILayout.Label("Current Track");
                    int y = EditorGUILayout.Popup(timeline.trackIndex, CommonEditor.settingsNames.ToArray());
                    if (y != timeline.trackIndex)
                    {
                        timeline.trackIndex = y;
                        timeline.Settings = CommonEditor.settings[y];
                        timeline.Load();
                        calculateGraph(timeline);

                    }
                    if (GUILayout.Button("Update Tracks"))
                    {
                        CommonEditor.getAllSettings(AudioDataMG.TrackSettingsPath);
                    }
                    GUILayout.EndHorizontal();

                }

                else
                {
                    CommonEditor.getAllSettings(AudioDataMG.TrackSettingsPath);
                }




                GUILayout.BeginHorizontal();
                if (GUILayout.Button("Load") || (timeline.edit && !loaded))
                {
                    timeline.Load();
                    calculateGraph(timeline);
                    loaded = true;
                }


                if (GUILayout.Button("Update"))
                {
                    calculateGraph(timeline);
                }
                if (GUILayout.Button("save"))
                {
                    timeline.Save();
                }
                GUILayout.EndHorizontal();

                updateCameraPosition(timeline);

                if (timeline.graphicPositions.Count > 0)
                    EditorGUILayout.CurveField(curve, Color.white, new Rect(0, 0, timeline.graphicPositions[timeline.graphicPositions.Count - 1].x, 5f), GUILayout.Height(64));
                GUI.enabled = true;
            
                
                #region segments
                if (timeline.Settings)
                    CommonEditor.drawSegments(timeline.Settings);
                #endregion





                GUILayout.Label("Time: " + timeline.currentTrackTime);

                audioTrackTime = GUILayout.HorizontalSlider(timeline.currentTrackTime, 0, timeline.audioTrackHolder.clip.length);
                if (audioTrackTime != timeline.currentTrackTime)
                {
                    if (timeline.currentAudioState == beatTimeline.audioState.playing)
                    {
                        timeline.audioTrackHolder.time = audioTrackTime;
                    }
                    else
                    {
                        timeline.audioTrackHolder.time = audioTrackTime;
                        timeline.currentTrackTime = audioTrackTime;
                    }

                }

                GUILayout.Space(20);
                GUILayout.BeginHorizontal();
                GUI.enabled = timeline.currentAudioState != beatTimeline.audioState.playing;
                if (GUILayout.Button("play"))
                {
                    timeline.playAudio();
                }
                GUI.enabled = timeline.currentAudioState == beatTimeline.audioState.playing;
                if (GUILayout.Button("Pause"))
                {
                    timeline.pauseAudio();
                }
                GUI.enabled = timeline.currentAudioState != beatTimeline.audioState.stop;
                if (GUILayout.Button("Stop"))
                {
                    timeline.StopAudio();
                }

                GUILayout.EndHorizontal();
                GUILayout.Label("Offset: " + timeline.Offset);

                GUILayout.BeginVertical();

                offset = GUILayout.HorizontalSlider(timeline.Offset, -5, 5f);
                if (offset != timeline.Offset)
                {
                    timeline.Offset = offset;

                }
                GUILayout.Space(20);

                GUILayout.BeginHorizontal();
                if (GUILayout.Button("Apply Offset"))
                {
                    lastOffset = -timeline.Offset;
                    timeline.applyOffset(timeline.Offset);

                    timeline.Save();
                    timeline.Load();
                    calculateGraph(timeline);
                    loaded = true;

                }
                GUI.enabled = lastOffset != -9999;
                if (GUILayout.Button("Undo"))
                {
                    timeline.applyOffset(lastOffset);
                    lastOffset = -9999;
                    timeline.Save();
                    timeline.Load();
                    calculateGraph(timeline);
                    loaded = true;
                }
                GUILayout.EndHorizontal();
                GUILayout.EndVertical();
                GUILayout.Space(20);
                GUILayout.BeginHorizontal();

                GUI.enabled = true;
                if (GUILayout.Button("Backup"))
                {
                    timeline.CreateBackup();
                }

                if (GUILayout.Button("Reset"))
                {
                    timeline.Reset();
                }

                GUILayout.EndHorizontal();


            }
        }
    }

    private void Setup(beatTimeline timeline)
    {
        if (!selectionsetup)
        {
            selectionsetup = true;
            Selection.selectionChanged += selectionChanged;

        }




        // timeline.edit = GUILayout.Toggle(timeline.edit, "Edit");
        if (!timeline.edit)
        {

            Tools.visibleLayers = timeline.NonEditorLayers;
            SceneView.lastActiveSceneView.Repaint();



        }
        else
        {
            Tools.visibleLayers = timeline.EditorLayers;
            SceneView.lastActiveSceneView.Repaint();


        }
    }

    public void updateCameraPosition(beatTimeline tl)
    {
        Vector3 newpos = tl.graphicPositions[0];

      

        float dpos = audioTrackTime* (1f / tl.audioTrackHolder.clip.length);
        newpos.x = Mathf.Lerp(tl.graphicPositions[0].x, 
                              tl.graphicPositions[tl.graphicPositions.Count - 1].x,
                              dpos);
        newpos.z = SceneView.lastActiveSceneView.pivot.z;
        newpos.y = SceneView.lastActiveSceneView.pivot.y;

        SceneView.lastActiveSceneView.pivot = newpos;
        Vector3 refpointPos = new Vector3(tl.currentTrackTime, 0, tl.graphicPositions[0].z);
        Handles.color = Color.red;
        Handles.SphereHandleCap(-1,refpointPos, Quaternion.identity, 0.2f,EventType.MouseDown);
        
       
    }
    private void OnValidate()
    {
        
    }
    
    private void OnSceneGUI()
    {
        if (!Application.isPlaying)
        {

            beatTimeline timeline = target as beatTimeline;
            if (timeline.edit && Selection.activeGameObject != timeline.gameObject)
            {
                timeline.edit = false;
                Tools.visibleLayers = timeline.NonEditorLayers;
                SceneView.lastActiveSceneView.Repaint();
            }
            else
            {

            }
            if (timeline.edit)
            {
                HandleUtility.AddDefaultControl(GUIUtility.GetControlID(FocusType.Passive));
            }
            else
            {
                loaded = false;
            }
            if (timeline.edit)
            {
                drawGraph(timeline);
                if (Event.current.type == EventType.MouseDown)
                {
                    if (Event.current.button == 2)
                    {
                        Debug.Log("Middle Click");
                        initialMP = SceneView.lastActiveSceneView.pivot;
                    }
                }
                if (Event.current.type == EventType.MouseDrag || Event.current.type == EventType.MouseDown || Event.current.type == EventType.Used)
                {
                    updatePositions = true;
                    var e = Event.current;
                    if (e.button == 0 && e.isMouse)
                    {
                        for (int i = 0; i < rectangles.Count; i++)
                        {
                            if (rectangles[i].Contains(HandleUtility.GUIPointToWorldRay(e.mousePosition).origin))
                            {
                                if (e.button == 0 && e.shift)
                                {
                                    Debug.Log("RemoveBeat");
                                    int offset = i % 2 != 0 ? 1 : 0;
                                    int pos = (i - offset) / 2;
                                    timeline.removeBeat(pos);
                                    calculateGraph(timeline);
                                }
                                else if (e.button == 0 && e.control)
                                {
                                    Debug.Log("AddBeat");
                                    if (i % 2 != 0)
                                    {
                                        int offset = i % 2 != 0 ? 1 : 0;
                                        int pos = (i - offset) / 2 + 1;
                                        timeline.addBeat(pos);
                                        calculateGraph(timeline);


                                    }

                                }

                            }
                        }
                    }
                    else if (e.button == 1)
                    {


                    }
                    

                }
                else if (Event.current.type == EventType.MouseUp)
                {

                    updatePositions = false;
                    if (isEditing)
                    {
                        calculateGraph(target as beatTimeline);
                        isEditing = false;
                    }
                    if (Event.current.button == 2)
                    {
                        
                        finalMP = SceneView.lastActiveSceneView.pivot;
                        Vector2 delta = (finalMP - initialMP);
                        Debug.Log("Middle Click up"+ delta);
                        timeline.currentTrackTime += delta.x;
                    }

                }

                drawHandlse(timeline);
 
            }
        }
    }
    bool updatePositions = false;
    bool isEditing = false;
    void drawGraph(beatTimeline timeline)
    {
        Handles.color = Color.green;

        for (int i = 0; i < timeline.graphicPositions.Count - 1; i++)
        {
            Handles.DrawLine(timeline.graphicPositions[i], timeline.graphicPositions[i + 1]);
        }
        
    }
    public List<Rect> rectangles = new List<Rect>();
    void drawHandlse(beatTimeline timeline)
    {
        Handles.color = Color.black;
        for (int i = 0; i < rectangles.Count; i++)
        {
            Handles.DrawWireCube( new Vector3(rectangles[i].x, rectangles[i].y), new Vector3(rectangles[i].width, rectangles[i].height));
        }
        for (int i = 0; i < handlesPositions.Count - 1; i +=2)
        {
            
            Handles.color = Color.cyan;
             
            var fmh_451_75_638437567692308197 = Quaternion.identity; Vector3 newpos= Handles.FreeMoveHandle(handlesPositions[i]  , 0.02f, Vector3.one * 0.1f, Handles.CylinderHandleCap);
           
                if (updatePositions && newpos != handlesPositions[i])
                {
                Undo.RecordObject(this, "Move Beat"); 

                handlesPositions[i] = newpos;
                handlesPositions[i + 1] = new Vector3(handlesPositions[i + 1].x, newpos.y, handlesPositions[i + 1].z);
                isEditing = true;
                timeline.loadedBeats[i/2].time = handlesPositions[i].x;
                timeline.loadedBeats[i / 2].intensity = handlesPositions[i].y;
                timeline.loadedBeats[i / 2].duration = Mathf.Abs(handlesPositions[i + 1].x - handlesPositions[i].x);


            }
            Handles.color = Color.red;

             Handles.DrawDottedLine(handlesPositions[i]  , handlesPositions[i + 1], 0.12f);
           

            Handles.color = Color.magenta;

              var fmh_473_72_638437567692345414 = Quaternion.identity; newpos = Handles.FreeMoveHandle(handlesPositions[i+1]  , 0.02f, Vector3.one * 0.1f,
                  Handles.CylinderHandleCap);
            if (updatePositions && newpos != handlesPositions[i+1])
            {
                Undo.RecordObject(this, "Move Beat");

                handlesPositions[i] = new Vector3(handlesPositions[i].x, newpos.y, handlesPositions[i].z);
                handlesPositions[i + 1] = newpos;
                 isEditing = true;
                timeline.loadedBeats[i / 2].time = handlesPositions[i].x;
                timeline.loadedBeats[i / 2].intensity = handlesPositions[i].y;
                timeline.loadedBeats[i / 2].duration = Mathf.Abs( handlesPositions[i + 1].x - handlesPositions[i].x);


            }

             

            

        }
    }
    void checkInput(Event e)
    {

        Vector2 mpos = HandleUtility.GUIPointToWorldRay(e.mousePosition).origin;
        for (int i = 0; i < handlesPositions.Count; i ++)
        {

           
            float dist = Vector2.Distance(mpos, handlesPositions[i]);
            if (new Vector3(mpos.x, mpos.y, handlesPositions[i].z) == handlesPositions[i])
            {
                Debug.Log("found" + i + " " + dist);
                break;
            }
            else
                Debug.Log(i + " is " + dist + " apprt");
             
        }
    }
}
