Shader "Mobile-Game/wireframe"
{
    Properties
    {
        _Color("Color", Color) = (0,1,1,1)
        [Toggle]_Divide("Divide", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

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

            v2g vert (appdata_base v)
            {
                v2g o = (v2g)0;
                o.pos = v.vertex;
                return o;
            }

#ifdef _DIVIDE_ON
            [maxvertexcount(10)]
#else 
            [maxvertexcount(4)]
#endif
            void geom(triangle v2g p[3], inout LineStream<g2f> lineStream)
            {
                g2f r[3];
                for (int i = 0; i < 3; i++) {
                    r[i] = (g2f)0;
                    r[i].pos = UnityObjectToClipPos(p[i].pos);
                }
#ifdef _DIVIDE_ON
                g2f r4 = (g2f)0;
                r4.pos = UnityObjectToClipPos((p[0].pos + p[1].pos + p[2].pos) * 0.3333);
                lineStream.Append(r[1]);
                lineStream.Append(r[2]);
                lineStream.Append(r4);
                lineStream.Append(r[1]);
                lineStream.Append(r[0]);
                lineStream.Append(r4);
#else
                lineStream.Append(r[0]);
                lineStream.Append(r[1]);
                lineStream.Append(r[2]);
                lineStream.Append(r[0]);
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
