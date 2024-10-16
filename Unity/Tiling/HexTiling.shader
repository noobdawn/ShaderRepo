Shader "Unlit/HexTiling"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _EdgePower ("Hex Edge Power", Range(8, 18)) = 8
        _BlurEdge ("Blur Edge", Range(0, 1)) = 0
        _Rotation ("Rotation", Range(0, 180)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex, _NoiseTex;
            float4 _MainTex_TexelSize;
            float4 _MainTex_ST;
            float _EdgePower;
            float _BlurEdge;
            float _Rotation;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

             // 从整数坐标中生成红绿蓝三颜色
            float3 getcolorfromint(int2 p)
            {
                int m = p.x + p.y * 2; 
                int n = abs(m) % 3;  
                if (m < 0)
                {             
                    if (n == 0)
                        return float3(1, 0, 0);
                    else if (n == 1)
                        return float3(0, 1, 0);
                    else
                        return float3(0, 0, 1);
                }
                else
                {
                    if (n == 0)
                        return float3(1, 0, 0);
                    else if (n == 1)
                        return float3(0, 0, 1);
                    else
                        return float3(0, 1, 0);
                }
            }

            float2 hash2( float2 p)
            {
                float2 r = mul(float2x2(127.1, 311.7, 269.5, 183.3), p);
                return frac(sin(r) * 43758.5453);
            }

            float3 hash3(float3 p)
            {
                float3 r = mul(float3x3(127.1, 311.7, 269.5, 183.3, 246.1, 124.6, 357.2, 235.4, 321.7), p);
                return frac(sin(r) * 43758.5453);
            }

            float2x2 rot2(int2 p)
            {                
                float angle = _Rotation / 180 * 3.1415926 + abs(p.x * p.y) + abs(p.x + p.y);
                float cs = cos(angle);
                float sn = sin(angle);
                float2x2 matRot = float2x2(
                    cs, -sn,
                    sn, cs
                );
                return matRot;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 dx = ddx(i.uv);
                float2 dy = ddy(i.uv);
                // 将uv转移到三角形空间
                float2 puv = floor(i.uv / _MainTex_TexelSize.xy) * _MainTex_TexelSize.xy;
                float2 uv = (i.uv) / sqrt(3) * 2;
                const float2x2 matToTri = float2x2(
                    1, -1 / sqrt(3),
                    0, 2 / sqrt(3)
                );
                float2 triuv = mul(matToTri, uv);
                // 找到三角形的三个顶点的整数坐标
                float2 vertex1 = float2(floor(triuv));
                float2 vertex2 = vertex1 + float2(1, 0);
                float2 vertex3 = vertex1 + float2(0, 1);
                float2 ftriuv = frac(triuv);
                if (ftriuv.x + ftriuv.y > 1)
                    vertex1 += 1;
                // 将这三个整数坐标转化为uv坐标
                const float2x2 matToUv = float2x2(
                    1, 0.5,
                    0, sqrt(3) / 2
                );
                float2 vertexUv1 = mul(matToUv, vertex1);
                float2 vertexUv2 = mul(matToUv, vertex2);
                float2 vertexUv3 = mul(matToUv, vertex3);
                // 把uv基于上述内容进行旋转
                float2 uv1 = mul(rot2(vertex1), uv - vertexUv1) + vertexUv1;
                float2 uv2 = mul(rot2(vertex2), uv - vertexUv2) + vertexUv2;
                float2 uv3 = mul(rot2(vertex3), uv - vertexUv3) + vertexUv3;
                // 计算距离三角形三个顶点的距离
                float3 noise = tex2Dgrad(_NoiseTex, uv, dx, dy).rgb * 2 - 1;
                float d1 = length(uv - vertexUv1 - noise * _BlurEdge);
                float d2 = length(uv - vertexUv2 - noise * _BlurEdge);
                float d3 = length(uv - vertexUv3 - noise * _BlurEdge);
                // 计算权重
                float w1 = 1 / (pow(d1, _EdgePower) + 0.000001);
                float w2 = 1 / (pow(d2, _EdgePower) + 0.000001);
                float w3 = 1 / (pow(d3, _EdgePower) + 0.000001);
                float3 weights = float3(w1, w2, w3);
                weights /= dot(weights, float3(1, 1, 1));
                // 这里可视化遮罩
                float4 col = 1;
                col.rgb = (getcolorfromint(vertex1) * weights.x + getcolorfromint(vertex2) * weights.y + getcolorfromint(vertex3) * weights.z);
                // 采样
                float4 col0 = tex2Dgrad(_MainTex, uv1, dx, dy);
                float4 col1 = tex2Dgrad(_MainTex, uv2, dx, dy);
                float4 col2 = tex2Dgrad(_MainTex, uv3, dx, dy);
                col.rgb = col0.rgb * weights.x + col1.rgb * weights.y + col2.rgb * weights.z;                
                return col;
            }
            ENDCG
        }
    }
}
