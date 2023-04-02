Shader "Unlit/LatticeNoise4SampleTiling"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex("Noise", 2D) = "white" {}
        _DistortScale("Distort Scale", Range(0.0, 1.0)) = 0.5
        [Toggle]_Hash("Hash", Int) = 1
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
            #pragma shader_feature _HASH_ON

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
            sampler2D _NoiseTex;
            float _DistortScale;
            float4 _MainTex_ST;
            float4 _NoiseTex_TexelSize;

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
#if defined(_HASH_ON)
                // 着这种情况下就直接使用uv的四角作为随机数
                float4 ofa = hash4(iuv + float2(0.0, 0.0));
                float4 ofb = hash4(iuv + float2(1.0, 0.0));
                float4 ofc = hash4(iuv + float2(0.0, 1.0));
                float4 ofd = hash4(iuv + float2(1.0, 1.0));
#else
                // 将纹理内容认为是随机数，挑四个点的颜色值作为随机数
                float4 ofa = tex2D(_MainTex, (iuv + float2(0.5, 0.5) * _NoiseTex_TexelSize.xy));
                float4 ofb = tex2D(_MainTex, (iuv + float2(1.5, 0.5) * _NoiseTex_TexelSize.xy));
                float4 ofc = tex2D(_MainTex, (iuv + float2(0.5, 1.5) * _NoiseTex_TexelSize.xy));
                float4 ofd = tex2D(_MainTex, (iuv + float2(1.5, 1.5) * _NoiseTex_TexelSize.xy));
#endif
                ofa = lerp(ofa, float4(0,0,0,0), _DistortScale);
                ofb = lerp(ofb, float4(0,0,0,0), _DistortScale);
                ofc = lerp(ofc, float4(0,0,0,0), _DistortScale);
                ofd = lerp(ofd, float4(0,0,0,0), _DistortScale);

                // 得到uv的导数
                float2 dx = ddx(uv);
                float2 dy = ddy(uv);
                // 从随机数的后两位通道得到随机的符号取向
                ofa.zw = sign(ofa.zw - 0.5);
                ofb.zw = sign(ofb.zw - 0.5);
                ofc.zw = sign(ofc.zw - 0.5);
                ofd.zw = sign(ofd.zw - 0.5);
                // 把uv进行distort，因为乘上了随机的符号值，所以ddx和ddy也要跟着乘上，免得出现mipmapping问题
                float2 uva = uv * ofa.zw + ofa.xy; float2 dxa = dx * ofa.zw; float2 dya = dy * ofa.zw;
                float2 uvb = uv * ofb.zw + ofb.xy; float2 dxb = dx * ofb.zw; float2 dyb = dy * ofb.zw;
                float2 uvc = uv * ofc.zw + ofc.xy; float2 dxc = dx * ofc.zw; float2 dyc = dy * ofc.zw;
                float2 uvd = uv * ofd.zw + ofd.xy; float2 dxd = dx * ofd.zw; float2 dyd = dy * ofd.zw;
                // 用4个uv进行混合，混合比例自行把握
                float2 b = smoothstep(0.0, 1.0, fuv);
                float4 col = lerp(
                    lerp(tex2Dgrad(_MainTex, uva, dxa, dya), tex2Dgrad(_MainTex, uvb, dxb, dyb), b.x),
                    lerp(tex2Dgrad(_MainTex, uvc, dxc, dyc), tex2Dgrad(_MainTex, uvd, dxd, dyd), b.x),
                    b.y
                );
                return col;
            }
            ENDCG
        }
    }
}
