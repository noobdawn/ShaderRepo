using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class GodRay_DS : MonoBehaviour
{
    enum Quality
    {
        Low,
        Medium,
        High,
    }
    
    [SerializeField]
    private Quality quality;
    private Shader godRayShader;
    private Camera camera;
    [SerializeField]
    private Light Sun;
    [SerializeField]
    private float SampleDistance = 25f;
    [SerializeField]
    private float GodRayAttenuation = 0.5f;
    private Material godRayMaterial;

    [SerializeField]
    private RenderTexture rtBuffer_0, rtBuffer_1, rtBuffer_2;

#if UNITY_EDITOR
    private void OnValidate()
    {
        OnEnable();  
    }
#endif

    private void OnEnable()
    {
        if (camera == null)
            camera = gameObject.GetComponent<Camera>();
        camera.depthTextureMode = DepthTextureMode.Depth;
        if (godRayShader == null)
            godRayShader = Shader.Find("Hidden/GodRay_DS");
        if (godRayMaterial == null)
            godRayMaterial = new Material(godRayShader);
        if (rtBuffer_0)
        {
            RenderTexture.ReleaseTemporary(rtBuffer_0);
        }
        if (rtBuffer_1)
        {
            RenderTexture.ReleaseTemporary(rtBuffer_1);
        }
        if (rtBuffer_2)
            RenderTexture.ReleaseTemporary(rtBuffer_2);
        rtBuffer_0 = RenderTexture.GetTemporary(Screen.width, Screen.height, 24, RenderTextureFormat.ARGB32);
        rtBuffer_1 = RenderTexture.GetTemporary(Screen.width, Screen.height, 24, RenderTextureFormat.ARGB32);
        rtBuffer_2 = RenderTexture.GetTemporary(Screen.width, Screen.height, 24, RenderTextureFormat.R8);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (godRayMaterial == null || godRayShader == null)
            OnEnable();
        if (godRayMaterial == null || godRayShader == null || Sun == null)
        {
            Graphics.Blit(source, null as RenderTexture);
            return;
        }
        Vector3 sunScreenPos, pos;
        if (Sun.type == LightType.Directional)
        {
            pos = transform.position + Sun.transform.forward * camera.farClipPlane;
            sunScreenPos = camera.WorldToScreenPoint(pos);
        }
        else
        {
            pos = transform.position;
            sunScreenPos = camera.WorldToScreenPoint(pos);
        }
        Shader.SetGlobalVector("_SunScreenPos", new Vector4(sunScreenPos.x / camera.pixelWidth, sunScreenPos.y / camera.pixelHeight, 0, 0));
        Graphics.Blit(source, rtBuffer_0, godRayMaterial, 0);
        Graphics.Blit(rtBuffer_0, rtBuffer_2, godRayMaterial, 3);
        switch (quality)
        {
            case Quality.High:
                godRayMaterial.DisableKeyword("LQ");
                godRayMaterial.DisableKeyword("MQ");
                godRayMaterial.EnableKeyword("HQ");
                break;
            case Quality.Medium:
                godRayMaterial.DisableKeyword("LQ");
                godRayMaterial.DisableKeyword("HQ");
                godRayMaterial.EnableKeyword("MQ");
                break;
            default:
                godRayMaterial.DisableKeyword("HQ");
                godRayMaterial.DisableKeyword("MQ");
                godRayMaterial.EnableKeyword("LQ");
                break;
        }
        godRayMaterial.SetFloat("_SampleDistance", SampleDistance);
        Graphics.Blit(rtBuffer_0, rtBuffer_1, godRayMaterial, 1);
        godRayMaterial.SetFloat("_SampleDistance", SampleDistance * 2);
        Graphics.Blit(rtBuffer_1, rtBuffer_0, godRayMaterial, 1);
        godRayMaterial.SetFloat("_SampleDistance", SampleDistance * 4);
        Graphics.Blit(rtBuffer_0, rtBuffer_1, godRayMaterial, 1);
        
        godRayMaterial.SetTexture("_BluredTexture", rtBuffer_1);
        godRayMaterial.SetTexture("_MaskedTexture", rtBuffer_2);
        godRayMaterial.SetFloat("_Attenuation", GodRayAttenuation);
        Graphics.Blit(source, null as RenderTexture, godRayMaterial, 2);
    }
}