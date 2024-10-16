using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class MapTileRenderer : MonoBehaviour
{
    public bool Enabled
    {
        get
        {
            return mr.enabled;
        }
        set
        {
            mr.enabled = value;   
        }
    }

    private string _tileName, _atlasName, _picName;
    public string tileName
    {
        get { return _tileName; }
        set
        {
            if (!value.Contains(":"))
                return;
            int idx = value.IndexOf(":");
            _atlasName = value.Substring(0, idx);
            _picName = value.Substring(idx + 1, value.Length - idx - 1);
            MapTileTheme.SetTile(this, _atlasName, _picName);
            _tileName = value;
        }
    }

    private MeshRenderer _mr;
    public MeshRenderer mr
    {
        get { if (_mr == null) _mr = GetComponent<MeshRenderer>(); return _mr; }
    }

    private MaterialPropertyBlock _mbp;
    public MaterialPropertyBlock mbp
    {
        get { if (_mbp == null) _mbp = new MaterialPropertyBlock(); return _mbp; }
    }

    public bool flipH, flipV;
    public Color color;
    public Vector4 rect;

    public void SetRect(Vector4 r)
    {
        rect = r;
        mbp.SetVector(MapTileTheme.RID, r);
        mr.SetPropertyBlock(mbp);
    }

    public void SetColor(Color c)
    {
        color = c;
        mbp.SetColor(MapTileTheme.CID, Color.white);
        mr.SetPropertyBlock(mbp);
    }

    public void SetFlip(bool horizon, bool vertical)
    {
        flipH = horizon;
        flipV = vertical;
        mbp.SetVector(MapTileTheme.FID, new Vector4(horizon ? -1 : 1, vertical ? - 1: 1, 1, 1));
        mr.SetPropertyBlock(mbp);
    }
    
    internal void ResetToEmpty()
    {
        flipH = false;
        flipV = false;
        color = Color.white;
        mbp.SetColor(MapTileTheme.CID, Color.white);
        mbp.SetVector(MapTileTheme.FID, Vector4.one);
        mbp.SetVector(MapTileTheme.RID, new Vector4(0, 1, 0, 1));
        mr.SetPropertyBlock(mbp);
    }
}
