# 如何在UE4.26中新增自定义Pass





## Global Pass和Mesh Pass

简单地以这俩关键字搜了一下，好像没找到比较严格明确的说法。我个人的理解是：

* Depth Pre-Pass、Shadow Depth Pass、Base Pass、Custom Depth Pass、Translucency Pass等这些需要将模型从局部坐标空间变换到屏幕空间、模型本身承载的几何信息不可或缺的Pass就是Mesh Pass
* 像是Lighting Pass、SSR Pass、TAA之类的，从屏幕画幅出发、对模型本身几何信息不敏感的，就是Global Pass。

## 如何创建Shader

同样简单地划分下概念，新增Shader需要有：

* .usf：Unreal Shader源文件
* .ush：Shader头文件，如果需要的话
* 与Shader一一对应的C++类：用于注册Shader

