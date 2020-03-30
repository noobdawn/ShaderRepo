Shader "Mobile-Game/DitherWhenCloser"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_MaxDistanceFromCamera("Max Distance", float) = 1
		_MinDistanceFromCamera("Min Distance", float) = 0.5
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD1;
			};

			float _Alpha, _MaxDistanceFromCamera, _MinDistanceFromCamera;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}

			
			fixed4 frag (v2f i) : SV_Target
			{
				float dist = length(i.worldPos - _WorldSpaceCameraPos);
				dist = clamp(dist, _MinDistanceFromCamera, _MaxDistanceFromCamera);
				float p = abs((dist - _MinDistanceFromCamera) / (_MaxDistanceFromCamera - _MinDistanceFromCamera));
				fixed4 col = tex2D(_MainTex, i.uv);
				float2 srcPos = ComputeScreenPos(i.vertex);
				srcPos = floor(srcPos / 0.0005) * 0.0005;
				float a = frac(sin(dot(srcPos, float2(114.5, 141.9)) + dot(srcPos, float2(364.3, 648.8))) * 643.1);
				clip(a - 1 + p);
				return col;
			}
			ENDCG
		}
	}
}