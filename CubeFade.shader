Shader "Mobile-Game/CubeFade"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		[NoScaleOffset]_CubeTex ("Cube Texture", 2D) = "white" {}
		_CubeMinScale("Cube Scale", Range(0, 10)) = 1
		_CubeMaxScale("Cube Scale", Range(0, 10)) = 1
		_Progress("Progress", Range(0, 1)) = 0
		_CubeProgress("Cube Progress", Range(0, 1)) = 0
		_FadeColor("Fade Color", Color) = (0.5,0.5,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		// this pass draws the cube colony
		Pass
		{
			Cull Off

			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			#include "UnityCG.cginc"
			#include "NoiseLib.cginc"

			struct v2g
			{
				float4 pos    : POSITION;
				float3 normal : NORMAL;
				float2 uv     : TEXCOORD0;
			};

			struct g2f
			{
				float2 uv : TEXCOORD0;      // the UV of new cube
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float2 baseUv : TEXCOORD1;  // the UV of original object
			};

			float _CubeMinScale, _CubeMaxScale, _CubeProgress;
			sampler2D _MainTex, _CubeTex;
			float4 _MainTex_ST;

			g2f Zero() {
				g2f o;
				o.pos = 0;
				o.uv = 0;
				o.normal = 0;
				o.baseUv = 0;
				return o;
			}

			v2g vert(appdata_base v)
			{
				v2g o = (v2g)0;
				o.pos = v.vertex;
				o.normal = float3(0, 0, 0);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			void buildCube(float2 uv, float3 center, float3 normal, float noise, inout g2f v[36], inout TriangleStream<g2f> triStream)
			{
				// top
				v[0].pos = float4(0, 1, 0, 0);
				v[0].uv = float2(0, 0);
				v[0].baseUv = uv;
				v[0].normal = float3(0, 1, 0);

				v[1].pos = float4(1, 1, 0, 0);
				v[1].uv = float2(1, 0);
				v[1].baseUv = uv;
				v[1].normal = float3(0, 1, 0);

				v[2].pos = float4(0, 1, 1, 0);
				v[2].uv = float2(0, 1);
				v[2].baseUv = uv;
				v[2].normal = float3(0, 1, 0);

				v[3].pos = float4(1, 1, 1, 0);
				v[3].uv = float2(1, 1);
				v[3].baseUv = uv;
				v[3].normal = float3(0, 1, 0);

				// btm
				v[4].pos = float4(0, 0, 0, 0);
				v[4].uv = float2(0, 0);
				v[4].baseUv = uv;
				v[4].normal = float3(0, -1, 0);

				v[5].pos = float4(1, 0, 0, 0);
				v[5].uv = float2(1, 0);
				v[5].baseUv = uv;
				v[5].normal = float3(0, -1, 0);

				v[6].pos = float4(0, 0, 1, 0);
				v[6].uv = float2(0, 1);
				v[6].baseUv = uv;
				v[6].normal = float3(0, -1, 0);

				v[7].pos = float4(1, 0, 1, 0);
				v[7].uv = float2(1, 1);
				v[7].baseUv = uv;
				v[7].normal = float3(0, -1, 0);

				// forward
				v[8].pos = float4(0, 0, 1, 0);
				v[8].uv = float2(0, 0);
				v[8].baseUv = uv;
				v[8].normal = float3(0, 0, 1);

				v[9].pos = float4(1, 0, 1, 0);
				v[9].uv = float2(1, 0);
				v[9].baseUv = uv;
				v[9].normal = float3(0, 0, 1);

				v[10].pos = float4(0, 1, 1, 0);
				v[10].uv = float2(0, 1);
				v[10].baseUv = uv;
				v[10].normal = float3(0, 0, 1);

				v[11].pos = float4(1, 1, 1, 0);
				v[11].uv = float2(1, 1);
				v[11].baseUv = uv;
				v[11].normal = float3(0, 0, 1);

				// backward
				v[12].pos = float4(0, 0, 0, 0);
				v[12].uv = float2(0, 0);
				v[12].baseUv = uv;
				v[12].normal = float3(0, 0, -1);

				v[13].pos = float4(1, 0, 0, 0);
				v[13].uv = float2(1, 0);
				v[13].baseUv = uv;
				v[13].normal = float3(0, 0, -1);

				v[14].pos = float4(0, 1, 0, 0);
				v[14].uv = float2(0, 1);
				v[14].baseUv = uv;
				v[14].normal = float3(0, 0, -1);

				v[15].pos = float4(1, 1, 0, 0);
				v[15].uv = float2(1, 1);
				v[15].baseUv = uv;
				v[15].normal = float3(0, 0, -1);

				//left
				v[16].pos = float4(0, 0, 0, 0);
				v[16].uv = float2(0, 0);
				v[16].baseUv = uv;
				v[16].normal = float3(-1, 0, 0);

				v[17].pos = float4(0, 1, 0, 0);
				v[17].uv = float2(1, 0);
				v[17].baseUv = uv;
				v[17].normal = float3(-1, 0, 0);

				v[18].pos = float4(0, 0, 1, 0);
				v[18].uv = float2(0, 1);
				v[18].baseUv = uv;
				v[18].normal = float3(-1, 0, 0);

				v[19].pos = float4(0, 1, 1, 0);
				v[19].uv = float2(1, 1);
				v[19].baseUv = uv;
				v[19].normal = float3(-1, 0, 0);

				// right
				v[20].pos = float4(1, 0, 0, 0);
				v[20].uv = float2(0, 0);
				v[20].baseUv = uv;
				v[20].normal = float3(1, 0, 0);

				v[21].pos = float4(1, 1, 0, 0);
				v[21].uv = float2(1, 0);
				v[21].baseUv = uv;
				v[21].normal = float3(1, 0, 0);

				v[22].pos = float4(1, 0, 1, 0);
				v[22].uv = float2(0, 1);
				v[22].baseUv = uv;
				v[22].normal = float3(1, 0, 0);

				v[23].pos = float4(1, 1, 1, 0);
				v[23].uv = float2(1, 1);
				v[23].baseUv = uv;
				v[23].normal = float3(1, 1, 1);

				float4 offset = float4(random4(float4(center, _Time.x * 0.0001)).xyz, 0);
				float4 scale = lerp(_CubeMinScale, _CubeMaxScale, random3(float3(uv, 0)).x);
				scale *= saturate(noise / -0.05);
				for (int i = 0; i < 24; i++)
					v[i].pos = UnityObjectToClipPos(center 
					+ (v[i].pos - float4(0.5, 0.5, 0.5,0) 
					// random position
					+ offset * 0.2 + normal * 2
					)
					// random size
					* scale);
				triStream.Append(v[0]); triStream.Append(v[2]); triStream.Append(v[1]); triStream.RestartStrip();
				triStream.Append(v[1]); triStream.Append(v[2]); triStream.Append(v[3]); triStream.RestartStrip();
				triStream.Append(v[4]); triStream.Append(v[5]); triStream.Append(v[6]); triStream.RestartStrip();
				triStream.Append(v[5]); triStream.Append(v[7]); triStream.Append(v[6]); triStream.RestartStrip();
				triStream.Append(v[8]); triStream.Append(v[9]); triStream.Append(v[10]); triStream.RestartStrip();
				triStream.Append(v[9]); triStream.Append(v[11]); triStream.Append(v[10]); triStream.RestartStrip();
				triStream.Append(v[12]); triStream.Append(v[14]); triStream.Append(v[13]); triStream.RestartStrip();
				triStream.Append(v[13]); triStream.Append(v[14]); triStream.Append(v[15]); triStream.RestartStrip();
				triStream.Append(v[16]); triStream.Append(v[18]); triStream.Append(v[17]); triStream.RestartStrip();
				triStream.Append(v[17]); triStream.Append(v[18]); triStream.Append(v[19]); triStream.RestartStrip();
				triStream.Append(v[20]); triStream.Append(v[21]); triStream.Append(v[22]); triStream.RestartStrip();
				triStream.Append(v[21]); triStream.Append(v[23]); triStream.Append(v[22]); triStream.RestartStrip();
			}

			// from point to cube
			[maxvertexcount(72)]
			void geom(line v2g p[2], inout TriangleStream<g2f> triStream)
			{
				float noise = pnoise(float3(p[0].uv, 0), 10) * 0.5 + 0.5 - _CubeProgress;
				if (noise < 0) {
					g2f vFirstPoint[36];
					for (int initIdx = 0; initIdx < 36; initIdx++)
						vFirstPoint[initIdx] = Zero();
					buildCube(p[0].uv, p[0].pos, p[0].normal, noise, vFirstPoint, triStream);
					g2f vSecondPoint[36];
					for (int initIdx = 0; initIdx < 36; initIdx++)
						vSecondPoint[initIdx] = Zero();
					buildCube(p[1].uv, p[1].pos, p[1].normal, noise, vSecondPoint, triStream);
				}
			}

			fixed4 frag(g2f i) : SV_Target
			{
				return tex2D(_CubeTex, i.uv);
			}

			ENDCG
		}

		Pass
		{
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "NoiseLib.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			float _Progress, _TopHeight, _BtmHeight;
			sampler2D _MainTex, _CubeTex;
			float4 _MainTex_ST, _FadeColor;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float noise = pnoise(float3(i.uv, 0), 10) * 0.5 + 0.5 - _Progress;
				clip(noise);
				float4 col = tex2D(_MainTex, i.uv);
				if (noise <= 0.2)
					return lerp(_FadeColor, col, noise / 0.2);
				return col;
			}
			ENDCG
		}
	}
}
