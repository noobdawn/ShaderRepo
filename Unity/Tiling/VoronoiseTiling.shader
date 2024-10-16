Shader "Unlit/VoronoiseTiling"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DistortScale("Distort Scale", Range(0.0, 1.0)) = 0.5
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _DistortScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            // 从UV中生成一个随机数
            // 基本都是这样的，逐分量点乘，最后过一个三角函数并提取小数部分，值域是0~1
            float4 hash4(float2 p)
            {
                return frac(sin(float4(1.0 + dot(p, float2(37.0, 17.0)),
                                       2.0 + dot(p, float2(11.0, 47.0)),
                                       3.0 + dot(p, float2(41.0, 29.0)),
                                       4.0 + dot(p, float2(23.0, 31.0)))) * 103.0);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float2 iuv = floor(uv);
                float2 fuv = frac(uv);

                float2 dx = ddx(uv);
                float2 dy = ddy(uv);

                // 跟Voronoi图思想一样，从周围9个晶格点随机得到9个uv值
                // 用这些uv值进行采样，得到9个颜色值
                // 把这些颜色值以距离为权重进行加权平均
                float3 va = 0.0;
                float w1 = 0.0;
                float w2 = 0.0;
                for (int j = -1; j <= 1; j++)
                for (int i = -1; i <= 1; i++)
                {
                    float2 g = float2(i, j);
                    float4 o = hash4(iuv + g);
                    float2 r = g - fuv + o.xy;
                    float d = dot(r, r);
                    // 因为是加权平均，并不能保证亮度一致，所以要调整此处以保证9个颜色混合后仍然接近原本的颜色
                    float w = exp(-d * 7.0);
                    float3 c = tex2Dgrad(_MainTex, uv + _DistortScale * o.zw, dx, dy).rgb;
                    va += c * w;
                    w1 += w;
                    w2 += w * w;
                }
                // 这里可以考虑用mipmaplevel很高的颜色平均一下，避免颜色过渡重叠，当然，需要一次额外的采样
                float mean = tex2Dgrad(_MainTex, uv, dx * 16, dy * 16).r;
                float3 res = mean + (va - w1 * mean) / sqrt(w2);
                return float4(lerp(va / w1, res, _DistortScale), 1);
            }
            ENDCG
        }
    }
}
