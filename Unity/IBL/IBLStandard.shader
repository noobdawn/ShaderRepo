Shader "Custom/IBL-Diffuse" {
Properties {
    _MainTex ("Base (RGB)", 2D) = "white" {}
    _IrradianceTex("Irradiance", CUBE) = "white" {}
}
SubShader {
    Tags { "RenderType"="Opaque" }
    LOD 150

CGPROGRAM

samplerCUBE _IrradianceTex;

inline fixed4 LightingIBL (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
{
    fixed4 c;
    fixed3 n = s.Normal;
    c.rgb = s.Albedo * texCUBE(_IrradianceTex, n);
    c.a = s.Alpha;
    return c;
}

#pragma surface surf IBL noforwardadd

sampler2D _MainTex;

struct Input {
    float2 uv_MainTex;
};

void surf (Input IN, inout SurfaceOutput o) {
    fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
    o.Albedo = c.rgb;
    o.Alpha = c.a;
}
ENDCG
}

Fallback "Mobile/VertexLit"
}
