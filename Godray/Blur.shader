Shader "Hidden/GodRay_DS"
{
    Properties
    {
        [PreRenderData]_MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always


        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            sampler2D _MainTex;
			float4 _SunScreenPos;

            #include "UnityCG.cginc"

			fixed4 frag (v2f_img i) : SV_Target
            {
				fixed4 col = tex2D(_MainTex, i.uv);
				float2 d = i.uv - _SunScreenPos.xy;
				float limit = 1 - saturate(saturate(length(d) / 1.414) * 2);
				limit = pow(limit, 3);
				fixed l = col.r * .299 + col.g * .587 + col.b * .114;
				fixed4 pixel = lerp(0, col, smoothstep(0.4, 0.5, l));
				return min(pixel, lerp(0, col, limit));
            }
            ENDCG
        }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			sampler2D _MainTex;
			float4 _SunScreenPos, _MainTex_TexelSize;
			int _SampleDistance;
#if HQ
#define SC 16.0
#elif MQ
#define SC 12.0
#else
#define SC 8.0
#endif

			#include "UnityCG.cginc"

			fixed4 frag(v2f_img i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				float2 d = i.uv - _SunScreenPos.xy;
				float p = 0.01;
				float2 uvd = d * p * _SampleDistance / SC;
				for (int idx = 1; idx <= SC; idx++) {
					col += tex2D(_MainTex, i.uv - uvd * idx);
				}
				col /= (SC + 1);
				return col;
			}
			ENDCG
		}


        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"
			
            sampler2D _MainTex, _BluredTexture, _MaskedTexture;
			float4 _SunScreenPos, _SunColor;
			float _Attenuation;
			
            fixed4 frag (v2f_img i) : SV_Target
            {
				fixed4 origin = tex2D(_MainTex, i.uv);
				fixed4 blured = tex2D(_BluredTexture, i.uv);
				fixed mask = tex2D(_MaskedTexture, i.uv).r;
				return fixed4(origin.rgb + blured.rgb * _Attenuation * (1 - mask), origin.a);
            }
            ENDCG
        }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			sampler2D _MainTex;
			float4 _SunScreenPos;

			#include "UnityCG.cginc"

			fixed4 frag(v2f_img i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed l = col.r * .299 + col.g * .587 + col.b * .114;
				return fixed4(l, 0, 0, 0);
			}
			ENDCG
		}
    }
}