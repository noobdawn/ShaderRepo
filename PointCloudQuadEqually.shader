Shader "Mobile-Game/PointCloudQuadEqually"
{
    Properties
    {
        _Color("Color", Color) = (0,1,1,1)
        [Toggle]_Divide("Divide", float) = 0
        _Size("Size", float) = 1
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

            float4 _Color, _ScreenParam;
            float _Size;

            v2g vert(appdata_base v)
            {
                v2g o = (v2g)0;
                o.pos = v.vertex;
                return o;
            }

            float4 getSrcPos(float4 center, float4 offset, int multi)
            {
                float4 srcPos = ComputeScreenPos(center);
                float4 srcPosPlus = ComputeScreenPos(offset);
                float4 res = float4(srcPosPlus.xy / srcPosPlus.w - srcPos.xy / srcPos.w, 0, 0);
                res.x = 1 / res.x;
                res.y = 1 / res.y;
                /*res.x = res.x * _ScreenParams.x / multi;
                res.y = res.y * _ScreenParams.y / multi;*/
                return res;
            }

            void buildQuad(float4 pos, float size, inout TriangleStream<g2f> stream)
            {
                g2f vertex[4];
                float4 screenParam = float4(1, 1.0 * _ScreenParams.x * _ScreenParams.x / _ScreenParams.y / _ScreenParams.y, 0, 0) * size;
                float4 center = UnityObjectToClipPos(pos);
                float4 offset = mul(UNITY_MATRIX_MV, pos);
                offset.xy += 1;
                offset = mul(UNITY_MATRIX_P, offset);
                vertex[0] = (g2f)0; vertex[0].pos = center + float4(-0.5, -0.5, 0, 0) * screenParam * getSrcPos(center, offset, 100);
                vertex[1] = (g2f)0; vertex[1].pos = center + float4(-0.5, 0.5, 0, 0) * screenParam * getSrcPos(center, offset, 100);
                vertex[2] = (g2f)0; vertex[2].pos = center + float4(0.5, -0.5, 0, 0) * screenParam * getSrcPos(center, offset, 100);
                vertex[3] = (g2f)0; vertex[3].pos = center + float4(0.5, 0.5, 0, 0) * screenParam * getSrcPos(center, offset, 100);
                stream.Append(vertex[0]); stream.Append(vertex[2]); stream.Append(vertex[1]); stream.RestartStrip();
                stream.Append(vertex[1]); stream.Append(vertex[2]); stream.Append(vertex[3]); stream.RestartStrip();
            }

#ifdef _DIVIDE_ON
            [maxvertexcount(36)]
#else 
            [maxvertexcount(18)]
#endif
            void geom(triangle v2g p[3], inout TriangleStream<g2f> triangleStream)
            {
#ifdef _DIVIDE_ON
                float4 pos[6];
#else
                float4 pos[3];
#endif
                for (int i = 0; i < 3; i++) {
                    pos[i] = p[i].pos;
                }

                buildQuad(pos[0], _Size, triangleStream);
                buildQuad(pos[1], _Size, triangleStream);
                buildQuad(pos[2], _Size, triangleStream);
#ifdef _DIVIDE_ON
                pos[3] = (p[0].pos + p[1].pos) * 0.5;
                pos[4] = (p[1].pos + p[2].pos) * 0.5;
                pos[5] = (p[0].pos + p[2].pos) * 0.5;
                buildQuad(pos[3], _Size, triangleStream);
                buildQuad(pos[4], _Size, triangleStream);
                buildQuad(pos[5], _Size, triangleStream);
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
