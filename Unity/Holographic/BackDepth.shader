Shader "Hidden/BackDepth"
{
	SubShader
	{
		Tags { "RenderType" = "Opaque" }

		Pass
		{
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float linearDepth : TEXCOORD0;
				float3 worldPos0 : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.linearDepth = COMPUTE_DEPTH_01;
				o.worldPos0 = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				return float4(i.linearDepth, 0, 0, 0);
			}
			ENDCG
		}		
	}
}
