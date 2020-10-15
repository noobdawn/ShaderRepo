Shader "Hidden/CopyTextureToArea"
{
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex, _CopyTexture;
			float4 _AreaRect;

            float4 frag (v2f i) : SV_Target
            {
				float4 col = tex2D(_MainTex, i.uv);
				if (i.uv.x >= _AreaRect.x &&
					i.uv.x <= _AreaRect.y &&
					i.uv.y >= _AreaRect.z &&
					i.uv.y <= _AreaRect.w) {
					float2 uvInCopyTexture;
					uvInCopyTexture.x = (i.uv.x - _AreaRect.x) / (_AreaRect.y - _AreaRect.x);
					uvInCopyTexture.y = (i.uv.y - _AreaRect.z) / (_AreaRect.w - _AreaRect.z);
					float4 col2 = tex2D(_CopyTexture, uvInCopyTexture);
					return col2;
				}
				else
					return col;
            }
            ENDCG
        }
    }
}
