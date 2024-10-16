Shader "Learn/FlowMap-Learn"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		[NoScaleOffset]_FlowMap("FlowMap", 2D) = "green" {}
		_NormalMap("NormalMap", 2D) = "bump" {}
		_Interval("Interval", Range(0.001, 30)) = 3
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _FlowMap;
		sampler2D _NormalMap;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
		half _Interval;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

		float3 GetUVW(float2 uv, float2 flowVec, float time, float interval, bool b)
		{
			float3 res;
			if (b) 
			{
				time += 0.5 * interval;
			}
			float progress = frac(time / interval);
			res.xy = uv - flowVec * progress;
			res.z = 1 - abs(1 - progress * 2);
			return res;
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float2 flow = tex2D(_FlowMap, IN.uv_MainTex).rg * 2 - 1;
			float3 uvw1 = GetUVW(IN.uv_MainTex, flow, _Time.y, _Interval, false);
			float3 uvw2 = GetUVW(IN.uv_MainTex, flow, _Time.y, _Interval, true);
            // Albedo comes from a texture tinted by color
            fixed4 c1 = tex2D (_MainTex, uvw1.xy) * _Color;
			fixed4 c2 = tex2D (_MainTex, uvw2.xy) * _Color;
			o.Albedo = c1.rgb * uvw1.z + c2.rgb * uvw2.z;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c1.a * uvw1.z + c2.a * uvw2.z;
			o.Normal = UnpackNormal(tex2D(_NormalMap, uvw1.xy)) * uvw1.z
				     + UnpackNormal(tex2D(_NormalMap, uvw2.xy)) * uvw2.z;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
