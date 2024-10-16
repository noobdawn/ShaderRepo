Shader "Unlit/NoiseIndexTiling"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex("Noise", 2D) = "white" {}
        _NoiseTiling("NoiseTiling", Range(0.001, 1)) = 1
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
            sampler2D _NoiseTex;
            float4 _MainTex_ST;
            float4 _NoiseTex_TexelSize;
            float _NoiseTiling, _DistortScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float sum(float3 v) {
                return v.x + v.y + v.z;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float index = tex2D(_NoiseTex, uv * _NoiseTiling).r;
                float2 dx = ddx(uv);
                float2 dy = ddy(uv);
                // 相当于把噪声图通道看作是一个0~8的index
                // 然后小数部分就是在这个index上的偏移
                float l = index * 8.0;
                float f = frac(l);
                float ia = floor(l);
                float ib = ceil(l);

                // 随便用个hash就可以填充，总之就是从index随机映射到原图上的一个位置
                float2 offa = sin(float2(3.0, 7.0) * ia);
                float2 offb  = sin(float2(3.0, 7.0) * ib);

                float3 cola = tex2Dgrad(_MainTex, uv + _DistortScale * offa, dx, dy).rgb;
                float3 colb = tex2Dgrad(_MainTex, uv + _DistortScale * offb, dx, dy).rgb;
                f = smoothstep(0.2, 0.8, f - 0.1 * sum(cola - colb));
                return float4(lerp(cola, colb, f), 1);
            }
            ENDCG
        }
    }
}
