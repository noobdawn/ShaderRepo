Shader "Mobile-Game/PointCloud"
{
    Properties
    {
        _Color("Color", Color) = (0,1,1,1)
        [Toggle]_Divide("Divide", float) = 0
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom
            #pragma shader_feature _DIVIDE_ON

            #include "UnityCG.cginc"

            struct v2g
            {
                float4 pos    : POSITION;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
            };

            float4 _Color;

            v2g vert(appdata_base v)
            {
                v2g o = (v2g)0;
                o.pos = v.vertex;
                return o;
            }

#ifdef _DIVIDE_ON
            [maxvertexcount(6)]
#else 
            [maxvertexcount(3)]
#endif
            void geom(triangle v2g p[3], inout PointStream<g2f> pointStream)
            {
#ifdef _DIVIDE_ON
                g2f r[6];
#else
                g2f r[3];
#endif
                for (int i = 0; i < 3; i++) {
                    r[i] = (g2f)0;
                    r[i].pos = UnityObjectToClipPos(p[i].pos);
                }
                pointStream.Append(r[0]);
                pointStream.Append(r[1]);
                pointStream.Append(r[2]);
#ifdef _DIVIDE_ON
                r[3] = (g2f)0; r[3].pos = UnityObjectToClipPos((p[0].pos + p[1].pos) * 0.5);
                r[4] = (g2f)0; r[4].pos = UnityObjectToClipPos((p[1].pos + p[2].pos) * 0.5);
                r[5] = (g2f)0; r[5].pos = UnityObjectToClipPos((p[0].pos + p[2].pos) * 0.5);
                pointStream.Append(r[3]);
                pointStream.Append(r[4]);
                pointStream.Append(r[5]);
#endif
            }

            fixed4 frag(g2f i) : SV_Target
            {
                return _Color;
            }
            ENDCG
        }
    }
}
