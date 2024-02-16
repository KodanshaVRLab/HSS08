using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Events;

public class JoanTableDetector : MonoBehaviour
{
    [SerializeField]
    private Transform user = null;
    [SerializeField]
    private OVRSceneManager sceneManager = null;

    public UnityEvent<GameObject> onTableFound = null;
    public UnityEvent onTableNotFound = null;

    [Button]
    public void DetectTable()
    {
        List<GameObject> tables = FindObjectsOfType<OVRSemanticClassification>()
                    .Where(c => c.Contains(OVRSceneManager.Classification.Table))
                    .Select(c => c.gameObject)
                    .ToList();

        GameObject bestTable = GetFrontestTable(tables);

        if (bestTable != null)
        {
            onTableFound?.Invoke(bestTable);
        }
        else
        {
            onTableNotFound?.Invoke();
        }
    }

    private GameObject GetFrontestTable(List<GameObject> tables)
    {
        GameObject frontestTable = null;

        Vector3 userPosition = user.position;

        float minDistance = float.MaxValue;
        foreach (GameObject table in tables)
        {
            float distance = Vector3.Distance(table.transform.position, userPosition);
            if (distance < minDistance)
            {
                frontestTable = table;
                minDistance = distance;
            }
        }

        return frontestTable;
    }
}
