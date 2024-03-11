using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Playables;

public class WorldGridTileGizmoDebug : MonoBehaviour
{
    // Start is called before the first frame update

    Vector3 BestAxisOS(Matrix4x4 matrix, Vector3 objectScale)
    {
        Matrix4x4 mat = matrix.inverse;
        Vector3 xTrans = mat * Vector3.right; //  transform.InverseTransformVector(Vector3.right);
        xTrans = xTrans.ComponentDivide(objectScale);
        Vector3 yTrans = mat * Vector3.up; //transform.InverseTransformVector(Vector3.up);
        yTrans = yTrans.ComponentDivide(objectScale);
        Vector3 zTrans = mat * Vector3.forward; //transform.InverseTransformVector(Vector3.forward);
        yTrans = yTrans.ComponentDivide(objectScale);

        // Select least perpendicular one by comparing Y components
        float xp = Mathf.Abs(xTrans.y);
        float yp = Mathf.Abs(yTrans.y);
        float zp = Mathf.Abs(zTrans.y);

        // return first match
        float mp = Mathf.Min(xp, yp, zp);
        if (xp == mp)
        {
            return xTrans;
        }

        if (yp == mp)
        {
            return yTrans;
        }

        return zTrans;
    }

    Vector3 ProjectOnPlane(Vector3 flipDir, Vector3 scale)
    {
        Vector3 v = flipDir; //.ComponentDivide(scale);
        v.Scale(scale);
        Vector3 y = Vector3.up;
        //y = y.ComponentDivide(scale);
        y.Scale(scale);

        Vector3 proj = Vector3.Cross(v, y).ComponentDivide(scale);
        //proj.Scale(scale);
        //proj.y = 0; //Standard projection: we just yeet the Y component
        return proj;
    }

    Vector3 ExtendProjection(Vector3 flipDir, Vector3 proj)
    {
        return proj * (Vector3.Dot(flipDir, flipDir) / Vector3.Dot(proj, proj));
    }

    void DoGizmo()
    {
        // World Space Cell
        Gizmos.color = Color.white;
        Gizmos.DrawWireCube(transform.position, Vector3.one);

        Matrix4x4 matNoScale = transform.localToWorldMatrix; // Matrix4x4.TRS(transform.position, transform.rotation, Vector3.one * 0.1f);
        Gizmos.matrix = matNoScale; // transform.localToWorldMatrix;
        Vector3 objectScale = transform.localScale;
        // Plane normal
        Gizmos.color = Color.green;
        Gizmos.DrawLine(Vector3.zero, Vector3.up);

        // Flip Direction Axis
        Vector3 flipDir = BestAxisOS(matNoScale, Vector3.one);
        Gizmos.color = Color.blue;
        Gizmos.DrawLine(Vector3.zero, flipDir);

        Vector3 proj = ProjectOnPlane(flipDir, objectScale);
        Vector3 ext = ExtendProjection(flipDir, proj);
        // Extended FLip Direction
        Gizmos.color = Color.magenta;
        Gizmos.DrawLine(Vector3.zero, ext);
        // Projected Flip Direction
        Gizmos.color = Color.red;
        Gizmos.DrawLine (Vector3.zero, proj);

    }

    private void OnDrawGizmosSelected()
    {
        DoGizmo();
    }
}

public static class Vector3Extension
{
    public static Vector3 ComponentDivide(this Vector3 num, Vector3 den)
    {
        return new Vector3(num.x / den.x, num.y / den.y, num.z / den.z);
    }
}
