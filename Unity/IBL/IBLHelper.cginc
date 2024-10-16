#define PI 3.1415926535898

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

float3 uv2normal(float2 uv)
{
    float3 result;
    uv.x = uv.x * PI * 2 - PI;
    uv.y = (1 - uv.y) * PI;
    result.y = cos(uv.y);
    result.x = sin(uv.y) * cos(uv.x);
    result.z = sin(uv.y) * sin(uv.x);
    result = normalize(result);
    return result;
}

float2 normal2uv(float3 normal)
{
    float2 result;
    result.y = 1 - acos(normal.y) / PI;
    result.x = (atan2(normal.z , normal.x)) / PI * 0.5 + 0.5;
    result.x = result.x;
    return result;
}

