Shader "Unlit/LayerShader"
{
    SubShader
    {
		Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
        Cull Off
		ZWrite On
		Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing

            #include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 worldPos : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			fixed4 _Color;
			sampler2D _BackDepthTex, _FrontDepthTex;
			float4x4 _Overlook_Matrix_V, _Overlook_Matrix_P;
			float4 _OverlookProjectionParams;
			float _LayerWeight;

            v2f vert (appdata v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float4 viewPos = mul(_Overlook_Matrix_V, i.worldPos);
				float depth01 = -(viewPos.z * _OverlookProjectionParams.w);
				float4 clipPos = mul(_Overlook_Matrix_P, viewPos);
				float4 screenPos = ComputeScreenPos(clipPos);
				float dBack = tex2Dproj(_BackDepthTex, screenPos);
				float dFront = tex2Dproj(_FrontDepthTex, screenPos);
				clip(depth01 - dFront);
				clip(dBack - depth01);
				return float4(_Color.rgb, _LayerWeight);
            }
            ENDCG
        }
    }
}
