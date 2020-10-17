Shader "Mobile-Game/Hair-Prime"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_MainColor("Hair Color(头发颜色)", Color) = (1,1,1,1)
		_SpecularShift("Hair Shifted Texture(头发渐变灰度图)", 2D) = "white" {}
		_SpecularColor_1("Hair Spec Color Primary(主高光颜色)", Color) = (1,1,1,1)
		//_SpecularColor_2("Hair Spec Color Seconary(次高光颜色)", Color) = (1,1,1,1)
		_SpecularWidth("Specular Width(高光收敛)", Range(0, 1)) = 1
		_PrimaryShift("Primary Shift(主高光偏移)", Range(-5, 5)) = 0
		//_SecondaryShift("Secondary Shift(次高光偏移)", Range(-5, 5)) = 0
		_SpecularScale("_Specular Scale(高光强度)", Range(0, 2)) = 1
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
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent :TANGENT;

			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				//float3 tangent :TEXCOORD1;
				float3 normal : TEXCOORD2;
				float3 bitangent : TEXCOORD3;
				float3 pos : TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _MainColor;
			float4 _SpecularColor_1;
			sampler2D _SpecularShift;
			float4 _SpecularShift_ST;
			fixed _PrimaryShift;
			float _SpecularWidth;
			fixed _SpecularScale;
			
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
				o.bitangent = cross(v.normal, v.tangent) * v.tangent.w * unity_WorldTransformParams.w;
				o.pos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			half3 ShiftedTangent(float3 t, float3 n, float shift) {
				return normalize(t + shift * n);
			}

			float StrandSpecular(float3 T, float3 V, float3 L, int exponent)
			{
				float3 H = normalize(L + V);
				float dotTH = dot(T, H);
				float sinTH = sqrt(1.0 - dotTH * dotTH);
				float dirAtten = smoothstep(-_SpecularWidth, 0, dotTH);
				return dirAtten * pow(sinTH, exponent) * _SpecularScale;
			}

			float HairSpecular(float3 t, float3 n, float3 l, float3 v, float2 uv)
			{
				float shiftTex = tex2D(_SpecularShift, uv * _SpecularShift_ST.xy + _SpecularShift_ST.zw) - 0.5;
				float3 t1 = ShiftedTangent(t, n, _PrimaryShift + shiftTex);
				float3 specular = _SpecularColor_1 * StrandSpecular(t1, v, l, 20);
				return specular;
			}

			float GGXAnisotropicNormalDistribution(float anisotropic, float roughness, float NdotH, float HdotX, float HdotY, float SpecularPower, float c)
			{
				float aspect = sqrt(1.0 - 0.9 * anisotropic);
				float roughnessSqr = roughness * roughness;
				float NdotHSqr = NdotH * NdotH;
				float ax = roughnessSqr / aspect;
				float ay = roughnessSqr * aspect;
				float d = HdotX * HdotX / (ax * ax) + HdotY * HdotY / (ay * ay) + NdotHSqr;
				return 1 / (3.14159 * ax * ay * d * d);
			}

			float sqr(float x) {
				return x * x;
			}

			float WardAnisotropicNormalDistribution(float anisotropic, float NdotL, float NdotV, float NdotH, float HdotX, float HdotY) {
				float aspect = sqrt(1.0h - anisotropic * 0.9h);
				float roughnessSqr = (1 - 0.5);
				roughnessSqr *= roughnessSqr;
				float X = roughnessSqr / aspect;
				float Y = roughnessSqr * aspect;
				float exponent = -(sqr(HdotX / X) + sqr(HdotY / Y)) / sqr(NdotH);
				float Distribution = 1.0 / (4.0 * 3.14159265 * X * Y * sqrt(NdotL * NdotV));
				Distribution *= exp(exponent);
				return Distribution;
			}
	
			fixed4 frag (v2f i) : SV_Target
			{
				//diffuse color
				fixed3 diff = tex2D(_MainTex, i.uv).rgb * _MainColor;
				//specular
				float3 n = normalize(i.normal);
				//float3 t = normalize(i.tangent);
				float3 b = normalize(i.bitangent);
				float3 v = normalize(UnityWorldSpaceViewDir(i.pos));
				float3 l = normalize(UnityWorldSpaceLightDir(i.pos));
				//float3 h = normalize(l + v);
				float3 spec = HairSpecular(b, n, l, v, i.uv);
				//spec = GGXAnisotropicNormalDistribution(1, 0.3, dot(n, h), dot(t, h), dot(b, h), 5, 0.1);
				//spec = WardAnisotropicNormalDistribution(1, dot(n, l), dot(n, v), dot(n, h), dot(t, h), dot(b, h));
				fixed4 col = float4(_LightColor0 * (spec + diff), 1);
				return col;
			}
			ENDCG
		}
	}
}
