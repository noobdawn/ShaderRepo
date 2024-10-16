Shader "Hidden/IBLMaker_CubeMap"
{
    Properties
    {
        _MainTex ("Texture", CUBE) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_cube2tex

            #include "UnityCG.cginc"
            #include "IBLHelper.cginc" 

            samplerCUBE _MainTex;
            float4 frag_cube2tex(v2f i) : SV_Target
            {
                float3 normal = uv2normal(i.uv);
                float4 col = texCUBE(_MainTex, normal);
                return col;
            }

            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_tex2tex

            #include "UnityCG.cginc"
            #include "IBLHelper.cginc" 

            sampler2D _MainTex;
            samplerCUBE _CubeTex;
            float4 _RandomVector;
            float4 frag_tex2tex(v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);
                float3 n = uv2normal(i.uv);
                float3 t;
                if (n.y > 0.99)
                    t = float3(1, 0, 0);
                else
                    t = float3(0, 1, 0);
                float3 b = normalize(cross(t, n));
                t = normalize(cross(b, n));
                _RandomVector.xyz = normalize(_RandomVector.xyz);
                float3 offsetN = t * _RandomVector.x + b * _RandomVector.z + n * _RandomVector.y;
                offsetN = normalize(offsetN);
                float4 offsetCol = texCUBE(_CubeTex, offsetN);
                col.rgb = (1 - _RandomVector.w) * col.rgb + _RandomVector.w * offsetCol.rgb;
                return col;
            }

            ENDCG
        }
    }
}
