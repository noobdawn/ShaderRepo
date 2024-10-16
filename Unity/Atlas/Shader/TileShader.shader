// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Tiles/Default"
{
    Properties
    {
         _MainTex ("Tile Texture", 2D) = "white" {}
         _RendererColor ("RendererColor", Color) = (1,1,1,1)
         _Flip ("Flip", Vector) = (1,1,1,1)
        _TileRect("Tile Rect", Vector) = (0,1,0,1)
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend One OneMinusSrcAlpha

        Pass
        {
        CGPROGRAM
            #pragma vertex TileVert
            #pragma fragment TileFrag
            #pragma target 2.0
            #pragma multi_compile_instancing
            #pragma multi_compile _ PIXELSNAP_ON
            #pragma multi_compile _ ETC1_EXTERNAL_ALPHA
            #include "TileSupport.cginc"
        ENDCG
        }
    }
}
