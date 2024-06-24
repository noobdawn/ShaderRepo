using NUnit.Framework;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class SDFGenerator
{
    public RenderTexture GenerateFaceSDFBetweenTwo(ref RenderTexture shadow0, ref RenderTexture shadow1, int width, int height, int lower, int upper)
    {
        GenerateUDF(ref shadow0, width, height, 1);
        GenerateUDF(ref shadow1, width, height, 1);
        RenderTexture result = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGBFloat);
        result.enableRandomWrite = true;
        result.useMipMap = false;
        result.Create();
        uint groupX, groupY, groupZ;
        SDFUtils.SDFCompute.GetKernelThreadGroupSizes(2, out groupX, out groupY, out groupZ);
        SDFUtils.SDFCompute.SetTexture(2, "Shadow0", shadow0);
        SDFUtils.SDFCompute.SetTexture(2, "Shadow1", shadow1);
        SDFUtils.SDFCompute.SetTexture(2, "Result", result);
        SDFUtils.SDFCompute.SetInt("width", width);
        SDFUtils.SDFCompute.SetInt("height", height);
        SDFUtils.SDFCompute.SetInt("lower", lower);
        SDFUtils.SDFCompute.SetInt("upper", upper);
        SDFUtils.SDFCompute.Dispatch(2, width / (int)groupX, height / (int)groupY, 1);
        return result;
    }

    public RenderTexture SumFaceSDF(ref List<RenderTexture> sdfList)
    {
        RenderTexture result = RenderTexture.GetTemporary(sdfList[0].width, sdfList[0].height, 0, RenderTextureFormat.ARGBFloat);
        result.enableRandomWrite = true;
        result.useMipMap = false;
        result.Create();
        uint groupX, groupY, groupZ;
        SDFUtils.SDFCompute.GetKernelThreadGroupSizes(3, out groupX, out groupY, out groupZ);
        for (int i = 0; i < sdfList.Count; i++)
        {
            string path = "D:/" + i + ".exr";
            Texture2D tex = SDFUtils.GetTexture2DFromRenderTexture(sdfList[i]);
            byte[] bytes = tex.EncodeToEXR();
            System.IO.File.WriteAllBytes(path, bytes);

            SDFUtils.SDFCompute.SetTexture(3, "Source", sdfList[i]);
            SDFUtils.SDFCompute.SetTexture(3, "Result", result);
            SDFUtils.SDFCompute.SetInt("sumTime", sdfList.Count);
            SDFUtils.SDFCompute.Dispatch(3, sdfList[i].width / (int)groupX, sdfList[i].height / (int)groupY, 1);
        }
        return result;
    }


    public void GenerateUDF(ref RenderTexture sdf, int width, int height, int pixelCountToArriveOne)
    {
        RenderTexture result = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGBFloat);
        result.enableRandomWrite = true;
        result.useMipMap = false;
        result.Create();
        uint groupX, groupY, groupZ;
        SDFUtils.SDFCompute.GetKernelThreadGroupSizes(0, out groupX, out groupY, out groupZ);
        SDFUtils.SDFCompute.SetTexture(0, "Source", sdf);
        SDFUtils.SDFCompute.SetTexture(0, "Result", result);
        SDFUtils.SDFCompute.SetInt("width", width);
        SDFUtils.SDFCompute.SetInt("height", height);
        SDFUtils.SDFCompute.SetFloat("pixelSize", 1.0f / (float)pixelCountToArriveOne);
        SDFUtils.SDFCompute.Dispatch(0, width / (int)groupX, height / (int)groupY, 1);
        SDFUtils.SDFCompute.SetTexture(1, "Source", result);
        SDFUtils.SDFCompute.SetTexture(1, "Result", sdf);
        SDFUtils.SDFCompute.Dispatch(1, width / (int)groupX, height / (int)groupY, 1);
        RenderTexture.ReleaseTemporary(result);
    }

    public RenderTexture PreprocessImage(Texture2D image, SDFUtils.SDFChannel channel, float threshold, bool invert, int width, int height, RenderTextureFormat format = RenderTextureFormat.ARGB32)
    {
        // 创建两个RenderTexture，一个用于存储原始图像，一个用于存储预处理后的图像
        RenderTexture source = RenderTexture.GetTemporary(width, height, 0, format);
        source.enableRandomWrite = true;
        source.useMipMap = false;
        source.Create();
        Graphics.Blit(image, source);
        RenderTexture result = RenderTexture.GetTemporary(width, height, 0, format);
        result.enableRandomWrite = true;
        result.useMipMap = false;
        result.Create();
        // 设置ComputeShader的参数
        SDFUtils.PreprocessCompute.SetTexture(0, "Target", result);
        SDFUtils.PreprocessCompute.SetTexture(0, "Source", source);
        SDFUtils.PreprocessCompute.SetFloat("Threshold", threshold);
        SDFUtils.PreprocessCompute.SetInt("Invert", invert ? 1 : 0);
        SDFUtils.PreprocessCompute.SetInt("Channel", (int)channel);
        // 运行ComputeShader
        uint groupX, groupY, groupZ;
        SDFUtils.PreprocessCompute.GetKernelThreadGroupSizes(0, out groupX, out groupY, out groupZ);
        SDFUtils.PreprocessCompute.Dispatch(0, width / (int)groupX, height / (int)groupY, 1);
        RenderTexture.ReleaseTemporary(source);
        return result;

    }
}

// SDF生成过程中用到的方法
public static class SDFUtils
{
    private static ComputeShader preprocessCompute = null;
    public static ComputeShader PreprocessCompute
    {
        get
        {
            // if (preprocessCompute == null)
            {
                FindShaders();
            }
            return preprocessCompute;
        }
    }
    private static ComputeShader sdfCompute = null;
    public static ComputeShader SDFCompute
    {
        get
        {
            // if (sdfCompute == null)
            {
                FindShaders();
            }
            return sdfCompute;
        }
    }

    public enum SDFChannel
    {
        Red,
        Green,
        Blue,
        Alpha,
        GrayScale,
    }

    public static Texture2D GetTexture2DFromRenderTexture(RenderTexture rt)
    {
        Texture2D tex = new Texture2D(rt.width, rt.height, TextureFormat.RGBAFloat, false);
        var oldRT = RenderTexture.active;
        RenderTexture.active = rt;
        tex.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
        tex.Apply();
        RenderTexture.active = oldRT;
        return tex;
    }

    public static RenderTexture GetRenderTextureFromTexture2D(Texture2D tex)
    {
        RenderTexture rt = new RenderTexture(tex.width, tex.height, 0, RenderTextureFormat.ARGBFloat);
        rt.enableRandomWrite = true;
        rt.useMipMap = false;
        rt.Create();
        Graphics.Blit(tex, rt);
        return rt;
    }


    // 寻找所有的ComputeShader
    private static void FindShaders()
    {
        // 如果是编辑器模式下，就在Assets文件夹下寻找所有的ComputeShader
        if (Application.isEditor)
        {
            string[] guids = AssetDatabase.FindAssets("t:ComputeShader");
            foreach (string guid in guids)
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                ComputeShader shader = AssetDatabase.LoadAssetAtPath<ComputeShader>(path);
                if (shader.name == "PreprocessCompute")
                {
                    preprocessCompute = shader;
                }
                else if (shader.name == "SDFCompute")
                {
                    sdfCompute = shader;
                }
            }
        }
        // 如果是运行时模式下，就在Resources文件夹下寻找所有的ComputeShader
        else
        {
            ComputeShader[] shaders = Resources.LoadAll<ComputeShader>("");
            foreach (ComputeShader shader in shaders)
            {
                if (shader.name == "PreprocessCompute")
                {
                    preprocessCompute = shader;
                }
                else if (shader.name == "SDFCompute")
                {
                    sdfCompute = shader;
                }
            }
        }
    }

}