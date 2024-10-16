#include "UnityCG.cginc"

UNITY_INSTANCING_BUFFER_START(PerDrawTile)
    UNITY_DEFINE_INSTANCED_PROP(fixed4, _RendererColor)
    UNITY_DEFINE_INSTANCED_PROP(fixed2, _Flip)
    UNITY_DEFINE_INSTANCED_PROP(float4, _TileRect)
UNITY_INSTANCING_BUFFER_END(PerDrawTile)

struct appdata_t
{
    float4 vertex   : POSITION;
    float4 color    : COLOR;
    float2 texcoord : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 vertex   : SV_POSITION;
    fixed4 color    : COLOR;
    float2 texcoord : TEXCOORD0;
    UNITY_VERTEX_OUTPUT_STEREO
};

sampler2D _MainTex;

inline float4 UnityFlipTile(in float4 pos, in fixed2 flip)
{
    return float4(pos.xy * flip.xy, pos.zw);
}

v2f TileVert(appdata_t IN)
{
    v2f OUT;
    UNITY_SETUP_INSTANCE_ID (IN);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
    OUT.vertex = UnityFlipTile(IN.vertex, UNITY_ACCESS_INSTANCED_PROP(PerDrawTile, _Flip));
    OUT.vertex = UnityObjectToClipPos(OUT.vertex);
    OUT.color = IN.color * UNITY_ACCESS_INSTANCED_PROP(PerDrawTile, _RendererColor);
	float4 rect = UNITY_ACCESS_INSTANCED_PROP(PerDrawTile, _TileRect);
    OUT.texcoord = IN.texcoord * (rect.yw - rect.xz) + rect.xz;
    return OUT;
}

fixed4 TileFrag(v2f IN) : SV_Target
{
    fixed4 c = tex2D (_MainTex, IN.texcoord) * IN.color;
    c.rgb *= c.a;
    return c;
}