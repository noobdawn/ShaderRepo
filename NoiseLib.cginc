float4 random4(float4 p) {
	return frac(sin(float4(
		dot(p, float4(114.5, 141.9, 198.10, 175.5)),
		dot(p, float4(364.3, 648.8, 946.4, 431.7)),
		dot(p, float4(190.3, 233.5, 716.9, 362.0)),
		dot(p, float4(273.1, 558.4, 113.05, 285.4))
		)) * 643.1);
}

float3 random3(float3 p) {
	return frac(sin(float3(
		dot(p, float3(114.5, 141.9, 198.10)),
		dot(p, float3(364.3, 648.8, 946.4)),
		dot(p, float3(190.3, 233.5, 716.9))
		)) * 643.1);
}

float2 random2(float2 p) {
	return frac(sin(float2(
		dot(p, float3(114.5, 141.9, 198.10)),
		dot(p, float3(364.3, 648.8, 946.4))
		)) * 643.1);
}

float random1(float p) {
	return frac(sin(p * 114.514 + 1919.810) * 643.1);
}


static int3 grads[16] = {
		int3(-1, -1, 0), int3(-1, 1, 0), int3(1, -1, 0), int3(1, 1, 0),
		int3(-1, 0, -1), int3(-1, 0, 1), int3(1, 0, -1), int3(1, 0, 1),
		int3(0, -1, -1), int3(0, -1, 1), int3(0, 1, -1), int3(0, 1, 1),
		int3(1, 1, 0), int3(-1, 1, 0), int3(0, -1, 1), int3(0, -1, -1)
};

float3 randomGrad(float3 p) {
	int idx = floor(random3(p) * 16);
	return grads[idx];
}

float plerp(float a, float b, float t) {
	float t3 = t * t * t;
	float finalT = 6 * t3 * t * t - 15 * t3 * t + 10 * t3;
	return a * (1 - finalT) + b * finalT;
}

float pnoise(float3 p, float3 rep)
{
	p *= rep;
	// 整理出晶胞位置
	float3 p_int0 = floor(p);
	float3 p_int1 = p_int0 + 1;
	// 整理出小数位
	float3 p_f0 = p - p_int0;
	float3 p_f1 = p - p_int1;
	// 整理距离矢量
	float3 v000 = p_f0;
	float3 v111 = p_f1;
	float3 v001 = float3(p_f0.x, p_f0.y, p_f1.z);
	float3 v010 = float3(p_f0.x, p_f1.y, p_f0.z);
	float3 v100 = float3(p_f1.x, p_f0.y, p_f0.z);
	float3 v011 = float3(p_f0.x, p_f1.y, p_f1.z);
	float3 v101 = float3(p_f1.x, p_f0.y, p_f1.z);
	float3 v110 = float3(p_f1.x, p_f1.y, p_f0.z);
	// 获得点积
	float _d000 = dot(v000, randomGrad(p_int0));
	float _d111 = dot(v111, randomGrad(p_int1));
	float _d001 = dot(v001, randomGrad(float3(p_int0.x, p_int0.y, p_int1.z)));
	float _d010 = dot(v010, randomGrad(float3(p_int0.x, p_int1.y, p_int0.z)));
	float _d100 = dot(v100, randomGrad(float3(p_int1.x, p_int0.y, p_int0.z)));
	float _d011 = dot(v011, randomGrad(float3(p_int0.x, p_int1.y, p_int1.z)));
	float _d101 = dot(v101, randomGrad(float3(p_int1.x, p_int0.y, p_int1.z)));
	float _d110 = dot(v110, randomGrad(float3(p_int1.x, p_int1.y, p_int0.z)));
	// 用样条函数捏合
	float _dx00 = plerp(_d000, _d100, p_f0.x);
	float _dx01 = plerp(_d001, _d101, p_f0.x);
	float _dx10 = plerp(_d010, _d110, p_f0.x);
	float _dx11 = plerp(_d011, _d111, p_f0.x);
	float _dxy0 = plerp(_dx00, _dx10, p_f0.y);
	float _dxy1 = plerp(_dx01, _dx11, p_f0.y);
	float _dxyz = plerp(_dxy0, _dxy1, p_f0.z);
	return _dxyz;
}

float pnoise_fbm(float3 p, float3 rep, int times, int freq, float proportion)
{
	float res = 0;
	if (times <= 0)
		times = 1;
	for (int i = 0; i < times; i++)
		res += pnoise(p, rep * pow(freq, i)) * pow(proportion, i);
	return res;
}



float wnoise(float3 p, float3 rep) {
	float3 sp = p * rep;
	float3 p_int0 = floor(sp);
	float minDist = length(rep) * 10;
	for (int m = -1; m < 3; m++) {
		for (int n = -1; n < 3; n++) {
			for (int q = -1; q < 3; q++) {
				float3 newP_int0 = p_int0 + int3(m, n, q);
				newP_int0 += (random3(newP_int0) * 2 - 1);
				float dist = distance(newP_int0, sp);
				if (dist < minDist)
					minDist = dist;
			}
		}
	}
	return 1 - (minDist);
}

float wnoise_fbm(float3 p, float3 rep, int times, int freq, float proportion)
{
	float res = 0;
	if (times <= 0)
		times = 1;
	for (int i = 0; i < times; i++)
		res += wnoise(p, rep * pow(freq, i)) * pow(proportion, i);
	return res;
}