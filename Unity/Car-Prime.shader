Shader "Mobile-Game/Car-Prime"
{
	Properties
	{
		_MainTex("Main Color", 2D) = "red" {}
		_MatCap("MatCap (反射材质)", 2D) = "white" {}
		_ReflectScale("Reflect Scale(反射强度)", Range(0, 2)) = 0.2
		_ReflectSharpness("Reflect Sharpness(反射锐化，用于凸显亮的区域)", Range(1, 5)) = 2
		_LightDir("Light Direction(假光源)", Vector) = (-1, -1, -1)
	}

		Subshader
	{
		Tags { "RenderType" = "Opaque" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos  : SV_POSITION;
				float2 cap  : TEXCOORD0;
				float3 uvd : TEXCOORD1;
			};

			sampler2D _MainTex;
			sampler2D _MatCap;
			half _ReflectScale;
			int _ReflectSharpness;
			float3 _LightDir;

			v2f vert(appdata_base v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.pos = UnityObjectToClipPos(v.vertex);
				float4 worldNorm = normalize(mul(unity_ObjectToWorld, v.normal));
				float3 lightDir = normalize(_LightDir);
				o.uvd.xy = v.texcoord;
				o.uvd.z = saturate(dot(worldNorm, lightDir)) * 0.5 + 0.5;
				worldNorm = mul(UNITY_MATRIX_V, worldNorm);
				o.cap.xy = worldNorm.xy * 0.5 + 0.5;
				return o;
			}

			float4 frag(v2f i) : COLOR
			{
				//half-lambert
				float4 diff = tex2D(_MainTex, i.uvd.xy) * i.uvd.z;
				float4 spec = pow(tex2D(_MatCap, i.cap), _ReflectSharpness);
				float4 col = diff  + spec * _ReflectScale;
				col.a = 1;
				return col;
			}
			ENDCG
		}
	}

		Fallback "VertexLit"
}