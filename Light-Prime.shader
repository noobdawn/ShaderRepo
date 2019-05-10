Shader "Mobile-Game/CarLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_FlareSize("Flare Size(光斑大小)", Range(0, 10)) = 1
		_WidthScale("Width Scale(长宽比)", Range(0, 5)) = 2
    }
    SubShader
    {
		Tags { "RenderType" = "Transparent" "RenderQueue"= "Transparent+1000" }
        LOD 100

        Pass
        {
			Cull Off
			ZTest Always
			Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float3 pos: TEXCOORD1;
				float3 normal : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			half _FlareSize;
			half _WidthScale;

            v2f vert (appdata v)
            {
                v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				float4 originalPos = mul(UNITY_MATRIX_MV, float4(0, 0, 0, 1));
				originalPos.xy += _FlareSize * v.vertex.xy * half2(_WidthScale, 1);
				o.vertex = mul(UNITY_MATRIX_P, originalPos);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = mul(unity_ObjectToWorld, v.normal);
				o.pos = UnityObjectToClipPos(float4(0, 0, 0, 1));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 diff = tex2D(_MainTex, i.uv);
				float3 n = normalize(i.normal * int3(1, 0, 1));
				float3 v = normalize(UnityWorldSpaceViewDir(i.pos)* int3(1, 0, 1));
				half e = 1 - max(0, dot(n, v));
				diff.a *= smoothstep(1, 0.5, e);
				return diff;
            }
            ENDCG
        }
    }
}
