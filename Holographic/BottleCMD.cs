using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class BottleCMD : MonoBehaviour
{
    public List<Renderer> renderers;
    public Camera overlookCamera;
    [Range(0, 1)]
    public float weightPerLayer;
    private Camera camera;
    private CommandBuffer cb;
    
    private void Initialize()
    {
        var backShader = Shader.Find("Hidden/BackDepth");
        var frontShader = Shader.Find("Hidden/FrontDepth");
        var backMat = new Material(backShader);
        var frontMat = new Material(frontShader);
        if (!camera)
            camera = gameObject.GetComponent<Camera>();
        if (renderers == null)
            renderers = new List<Renderer>();
        camera.depthTextureMode = DepthTextureMode.None;
        if (cb != null)
            Clear();
        cb = new CommandBuffer();
        cb.name = "Overlook";
        int _backRT = Shader.PropertyToID("_BackDepthTex");
        int _frontRT = Shader.PropertyToID("_FrontDepthTex");
        int _copyRT = Shader.PropertyToID("_CopyTex");
        cb.GetTemporaryRT(_backRT, 1024, 1024, 0, FilterMode.Point, RenderTextureFormat.RFloat);
        cb.GetTemporaryRT(_frontRT, 1024, 1024, 0, FilterMode.Point, RenderTextureFormat.RFloat);
        cb.GetTemporaryRT(_copyRT, 1024, 1024, 24, FilterMode.Point, RenderTextureFormat.ARGB32);
        // 出前后深度
        cb.SetRenderTarget(_backRT);
        cb.ClearRenderTarget(true, true, Color.clear);
        foreach (var renderer in renderers)
            cb.DrawRenderer(renderer, backMat);
        cb.SetRenderTarget(_frontRT);
        cb.ClearRenderTarget(true, true, Color.clear);
        foreach (var renderer in renderers)
            cb.DrawRenderer(renderer, frontMat);
        cb.SetGlobalTexture("_BackDepthTex", _backRT);
        cb.SetGlobalTexture("_FrontDepthTex", _frontRT);
        if (overlookCamera)
        {
            if (overlookCamera.targetTexture == null)
                overlookCamera.targetTexture = new RenderTexture(64, 64, 0);
            overlookCamera.cullingMask = 0;
            overlookCamera.AddCommandBuffer(CameraEvent.AfterEverything, cb);
        }
    }

    public void OnPreRender()
    {
        Shader.SetGlobalFloat("_LayerWeight", weightPerLayer);
        Shader.SetGlobalColor("_Color", Color.white);
        Shader.SetGlobalVector("_OverlookProjectionParams",
            new Vector4(
                1,
                overlookCamera.nearClipPlane,
                overlookCamera.farClipPlane,
                1f / overlookCamera.farClipPlane));
        Shader.SetGlobalMatrix("_Overlook_Matrix_V", overlookCamera.worldToCameraMatrix);
        Shader.SetGlobalMatrix("_Overlook_Matrix_P", GL.GetGPUProjectionMatrix(overlookCamera.projectionMatrix, true));
    }

    private void Clear()
    {
        if (overlookCamera && cb != null)
            overlookCamera.RemoveCommandBuffer(CameraEvent.AfterEverything, cb);
        cb.Clear();
        cb = null;
    }

    #region Mono
    private void OnValidate()
    {
        Initialize();
    }

    private void OnEnable()
    {
        Initialize();
    }

    private void OnDisable()
    {
        Clear();
    }
    #endregion
}
