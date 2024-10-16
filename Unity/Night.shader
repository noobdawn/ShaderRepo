Shader "Custom/Night"
{
	Properties
	{
		[Header(Sky Setting)]
		_Color1("Top Color", Color) = (1, 1, 1, 1)
		_Color2("Horizon Color", Color) = (1, 1, 1, 1)
		_Color3("Bottom Color", Color) = (1, 1, 1, 1)
		_UpperHeight("Upper Height", float) = 1
		_LowerHeight("Lower Height", float) = 1
		_HorizonHeight("Horizon Height", float) = 0

		[Header(Star Setting)]
		_StarDensity("Star Density", Range(0, 1)) = 0.5
		_StarColor("Star Color", Color) = (1, 1, 1, 1)
		_StarRotateSpeed("Star Rotate TimeScale", Range(0, 20)) = 1
		_Latitude("Latitude", Range(0, 89.9)) = 30

		[Header(Aurora Setting)]
		_AuroraSpeed("Aurora TimeScale", Range(0, 1)) = 0.2
		_AuroraColorSeed("Aurora Color", Range(0, 3)) = 1

		[Header(Cloud Setting)]
		_CloudAmount("Cloud Amount", Range(0, 1)) = 0.2
		_CloudDensity("Cloud Density", Range(0, 1)) = 0.2
		_CloudSpeed("Cloud TimeScale", Range(0, 1)) = 0.5

		[Header(Moon Setting)]
		_MoonRad("Moon Radius", Range(0, 1)) = 0.3

		[Header(Mountain Setting)]
		_MountainColor("Mountain Color",Color) = (1,1,1,1)
	}

	CGINCLUDE
	#define _EPISON 0.001
	#define _DEG_2_RAD 0.01745
	#define _STEP_COUNT 10
	#define _MAX_STEP_LENGTH 0.5
	#define _CLOUD_HEIGHT 1
	#define _CLOUD_THICKNESS 2.5
	#define _G .6
	#define _G2 0.36
	#define _PHASE_1 0.8
	#define _LIGHT_STEP_COUNT 10

	#include "UnityCG.cginc"
	#include "NoiseLib.cginc"
	#include "Lighting.cginc"
	struct appdata
	{
		float4 position : POSITION;
		float3 texcoord : TEXCOORD0;
		float3 normal : NORMAL;
	};

	struct v2f
	{
		float4 position : SV_POSITION;
		float3 texcoord : TEXCOORD0;
		float3 normal : TEXCOORD1;
	};

	half4 _Color1, _Color2, _Color3;
	half _UpperHeight, _LowerHeight, _HorizonHeight;

	half _StarDensity, _Latitude, _StarRotateSpeed;
	half4 _StarColor;

	half _AuroraSpeed, _AuroraColorSeed;

	half _CloudAmount, _CloudDensity, _CloudSpeed;

	half _MoonRad;

	half4 _MountainColor;

	// 带状极光
	// From https://www.shadertoy.com/view/XtGGRt
	// Author: nimitz
	float2x2 mm2(in float a){float c = cos(a), s = sin(a);return float2x2(c,s,-s,c);}
	float tri(in float x){return clamp(abs(frac(x)-.5),0.01,0.49);}
	float2 tri2(in float2 p){return float2(tri(p.x)+tri(p.y),tri(p.y+tri(p.x)));}

	float triNoise2d(in float2 p, float spd)
	{
		float z=1.8;
		float z2=2.5;
		float rz = 0.;
		p = mul(p, mm2(p.x*0.06));
		float2 bp = p;
		for (float i=0.; i<5.; i++ )
		{
			float2 dg = tri2(bp*1.85)*.75;
			dg = mul(dg, mm2(_Time.y*spd));
			p -= dg/z2;

			bp *= 1.3;
			z2 *= .45;
			z *= .42;
			p *= 1.21 + (rz-1.0)*.02;
			
			rz += tri(p.x+tri(p.y))*z;
			p = mul(p, -float2x2(0.95534, 0.29552, -0.29552, 0.95534));
		}
		return clamp(1./pow(rz*29., 1.3),0.,.55);
	}

	float hash21(in float2 n){ return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453); }
	float4 aurora(float3 ro, float3 rd)
	{
		float4 col = 0;
		float4 avgCol = 0;
		
		for(float i=0.;i<50.;i++)
		{
			float of = 0.006*hash21(rd.xy)*smoothstep(0.,15., i);
			float pt = ((.8+pow(i,1.4)*.002)-ro.y)/(rd.y*2.+0.4);
			pt -= of;
			float3 bpos = ro + pt*rd;
			float2 p = bpos.zx;
			float rzt = triNoise2d(p, _AuroraSpeed);
			float4 col2 = float4(0,0,0, rzt);
			col2.rgb = (sin(1.-float3(2.15,-.5, 1.2)+i * 0.043 * _AuroraColorSeed)*0.5+0.5)*rzt;
			avgCol =  lerp(avgCol, col2, .5);
			col += avgCol*exp2(-i*0.065 - 2.5)*smoothstep(0.,5., i);			
		}		
		col *= (clamp(rd.y*15.+.4,0.,1.));
		return col*1.8;
	}

	/// 体积云
	float getCloudAtPoint(float3 p)
	{
		float3 seed = p + float3(0, -_CLOUD_HEIGHT, 0);
		seed += float3(
			_Time.y * 3 + _SinTime.y,
			0,
			0) * _CloudSpeed;
		float n0 = pnoise_fbm(seed, 1, 2, 2, 0.6) * 0.5 + 0.5;
		float n1 = wnoise(seed, 0.1) * 0.5 + 0.5;
		n1 = pow(n1, 2);
		float n = 3 * n1 * n0 * smoothstep(0,_CLOUD_THICKNESS * 0.1, abs(_CLOUD_THICKNESS * 0.5 - seed.y));
		n = saturate(n - 3 + 3 * _CloudAmount);
		return n;
	}
	float getCloudAtPoint_l(float3 p)
	{
		float3 seed = p + float3(0, -_CLOUD_HEIGHT, 0);
		seed += float3(
			_Time.y * 3 + _SinTime.y,
			0,
			0) * _CloudSpeed;
		float n0 = 0.75;// pnoise(seed, 1) * 0.5 + 0.5;
		float n1 = wnoise(seed, 0.3) * 0.5 + 0.5;
		n1 = pow(n1, 3);
		float n = 3 * n1 * n0 * smoothstep(0, 0.25, abs(_CLOUD_THICKNESS * 0.5 - seed.y));
		n = saturate(n - 3 + 3 * _CloudAmount);
		return n;
	}

	/// Henyey-Greeensten phase function
	float phase(float cosTheta)
	{
		return (0.0796 * (1 - _G2) / pow((1 + _G2 - 2 * _G * cosTheta), 1.5));
	}

	float3 getLight(float3 p, float3 vd)
	{
		float3 ld = _WorldSpaceLightPos0.xyz;
		ld.y = ld.y == 0 ? _EPISON : ld.y;
		ld = normalize(ld);
		float cosTheta = dot(ld, normalize(vd));
		float ph = phase(cosTheta);
		float dist = (_CLOUD_THICKNESS + _CLOUD_HEIGHT - p.y) / ld.y;
		float step = min(_MAX_STEP_LENGTH, dist / _LIGHT_STEP_COUNT);
		float3 rayInPoint = dist * -ld + p;
		float3 res = 0, pos;
		float l = 1;
		for (int i = 0; i < _LIGHT_STEP_COUNT; i++)
		{
			pos = rayInPoint + (i + 0.5) * step * ld;
			float c = getCloudAtPoint_l(pos);
			l *= exp(-c * _PHASE_1 * step * _CloudDensity * 5);
		}
		l *= ph;
		// 在最外围做一次蚀刻
		float3 seed = rayInPoint + float3(0, -_CLOUD_HEIGHT, 0);
		seed += float3(
			_Time.y * 3 + _SinTime.y,
			0,
			0) * _CloudSpeed;
		float n = pnoise_fbm(seed, 4, 2, 2, 0.5) * 0.5 + 0.5;
		return lerp(_Color1, _LightColor0.xyz, l * max(0.5, n));
	}

	float4 cloud(float3 n)
	{
		float3 ray = n;
		ray.y = ray.y < _EPISON ? _EPISON : ray.y;
		float3 nray = normalize(ray);
		float3 rayInPoint = _CLOUD_HEIGHT / nray.y * nray;
		float3 rgb = 0, p;
		float c = 0;
		float step = min(_MAX_STEP_LENGTH, _CLOUD_THICKNESS / _STEP_COUNT / nray.y);
		for(int i = 0; i < _STEP_COUNT; i++)
		{
			p = rayInPoint + (i + 0.5) * step * nray;
			c += getCloudAtPoint(p);
			rgb += getLight(p, nray);
		}
		c /= _STEP_COUNT * 0.5;
		rgb /= _STEP_COUNT;
		c = saturate(c);
		return float4(rgb, c);
	}	

	v2f vert(appdata v)
	{
		v2f o;
		o.position = UnityObjectToClipPos(v.position);
		o.texcoord = v.texcoord;
		o.normal = v.normal;
		return o;
	}

	half4 frag(v2f i) : Color
	{
		float3 ntexcoord = normalize(i.texcoord);
		// 碧空如洗
		float p = ntexcoord.y;
		float l = p >= 0 ? 
				smoothstep(_HorizonHeight, _UpperHeight + _HorizonHeight, p) : 
				smoothstep(-_HorizonHeight, -_LowerHeight - _HorizonHeight, p);
		half4 baseCol = lerp(_Color2, p >= 0 ? _Color1 : _Color3, l);

		// 斗转星移
		float3 r = ntexcoord * 50;
		r.y = abs(r.y);
		float3 rn = normalize(float3(1, tan(_Latitude * _DEG_2_RAD), 0));
		float c = cos(_Time.x * _StarRotateSpeed);
		float s = sin(_Time.x * _StarRotateSpeed);
		float u = 1 - c;
		float3x3 m = float3x3(
			rn.x * rn.x * u + c,
			rn.x * rn.y * u - rn.z * s,
			rn.x * rn.z * u + rn.y * s,
			rn.x * rn.y * u + rn.z * s,
			rn.y * rn.y * u + c,
			rn.y * rn.z * u - rn.x * s,
			rn.x * rn.z * u - rn.y * s,
			rn.y * rn.z * u + rn.x * s,
			rn.z * rn.z * u + c
		);
		r = mul(r, m);
		// 繁星若雨
		float3 grid = floor(r);
		float starNoise = pnoise(r * 4, 1) * 0.5 + 0.5;
		float detailedNoise = random3(r);
		starNoise = detailedNoise * smoothstep(0.9 - _StarDensity, 0.9, starNoise);
		half4 starCol = _StarColor * starNoise;

		// 王母垂带
		float3 n = ntexcoord;
		n.y = abs(n.y);
		half4 auroraCol = smoothstep(0, 1.5, aurora(float3(0, 0, -6.7), n));

		// 垂天之云
		half4 cloudCol = cloud(n);

		// 皓月烛幽
		half4 moonCol = half4(_LightColor0.xyz, 0);
		moonCol.a = smoothstep(1 - _MoonRad * 0.011, 1 - _MoonRad * 0.01 , saturate(dot(_WorldSpaceLightPos0.xyz, n)));
		
		// 远山如墨
		n.y = 0;
		n = normalize(n);
		float mountainHeight = pnoise_fbm(n, 4, 2, 1.5, 0.8) * 0.5 + 0.3;
		mountainHeight *= 0.2;
		mountainHeight *= (pnoise_fbm(n, 16, 4, 2, 0.6) * 0.5 + 0.5);
		half4 mountainCol = half4(_MountainColor.rgb, mountainHeight > abs(p) ? 1 : 0);

		// 组合
		half4 finalCol = baseCol + starCol;
		finalCol.rgb = lerp(finalCol.rgb, moonCol.rgb, moonCol.a);
		finalCol.rgb = lerp(finalCol.rgb, auroraCol.rgb, auroraCol.a);
		finalCol.rgb = lerp(finalCol.rgb, cloudCol.rgb, cloudCol.a);
		finalCol.rgb = lerp(finalCol.rgb, mountainCol.rgb, mountainCol.a);
		// 用幂函数模拟菲涅尔定律
		finalCol *= p >= 0 ? 1 : 1 - pow(abs(p), 0.4);
		return finalCol;
	}
	ENDCG

	SubShader
	{
		Tags { "RenderType" = "Background" "Queue" = "Background" "PreviewType"="Skybox"}
		ZWrite Off
		Cull Off
		Pass
		{
			CGPROGRAM
			// 设置低精度
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
	}
	Fallback Off
}
