using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using System.IO;

[Serializable]
public class MapTileAtlasInfo
{
    public string atlasName;
    public int Count;
    public List<MapTilePicInfo> Pictures;

    public bool Contains(string picName)
    {
        if (Pictures != null)
            foreach (var pic in Pictures)
                if (picName == pic.name)
                    return true;
        return false;
    }

    public void AdjustChildrenAtlasName()
    {
        if (Pictures != null)
            foreach (var i in Pictures)
                i.atlasName = atlasName;
    }
}

[Serializable]
public class MapTilePicInfo
{
    public string atlasName;
    public string name;
    public Vector4 rect;
    public Vector2 size;
}

public class MapTileAtlas
{
    public MapTileAtlasInfo info;
    public Texture2D texture;
    public Material material;
}

public static class MapTileTheme
{
    #region 制作地图瓦片主题图集（仅在编辑器模式下生效）
#if UNITY_EDITOR
    // 调试模式，逐次输出source和target看问题出现在哪一步
    public static bool DebugMode = false;

    public enum DivideBehaviour
    {
        Width,
        Height,
        Area,
    }

    [MenuItem("地图编辑器/合并Tile图片到图集中")]
    private static void MakeAtlas()
    {
        string rootDir = "Map/AtlasSources";
        string rootPathInWin = Path.Combine(Application.dataPath, rootDir);
        string[] subDirs = Directory.GetDirectories(rootPathInWin, "*", SearchOption.TopDirectoryOnly);
        foreach (var dir in subDirs)
        {
            List<Texture2D> texs = new List<Texture2D>();
            //dir : D:/Test/QuadDemo/Assets\Map/AtlasSources\Test
            string d = dir.Replace("\\", "/");
            //d : D:/Test/QuadDemo/Assets/Map/AtlasSources/Test
            string[] files = Directory.GetFiles(d, "*.png", SearchOption.TopDirectoryOnly);
            foreach (var file in files)
            {
                string f = file.Replace("\\", "/").Substring(0, file.Length - 4);
                f = f.Replace(Application.dataPath, "Assets") + ".png";
                //f : Assets/Map/AtlasSources/Test/cswy_icon_rcq
                var t = AssetDatabase.LoadAssetAtPath<Texture2D>(f);
                texs.Add(t);
            }
            List<MapTilePicInfo> infos;
            RenderTexture rt;
            MapTileTheme.MakeAtlasWithPictures(texs.ToArray(), 1, out rt, out infos);
            MapTileAtlasInfo atlasInfo = new MapTileAtlasInfo()
            {
                atlasName = Path.GetFileNameWithoutExtension(dir),
                Count = infos.Count,
                Pictures = infos,
            };
            atlasInfo.AdjustChildrenAtlasName();
            MapTileTheme.SavePNG(rt, "Resources/Atlas/" + atlasInfo.atlasName);
            string json = JsonUtility.ToJson(atlasInfo);
            string path = Path.Combine(Application.dataPath, "Resources/Atlas/" + atlasInfo.atlasName + ".json");
            File.WriteAllText(path, json);
        }
        AssetDatabase.Refresh();
    }

    public static int Spacing = 0;

    struct Room
    {
        public int left, right, top, bottom;
        public int width { get { return right - left; } }
        public int height { get { return top - bottom; } }
        public bool IsAvailable(int spacing)
        {
            return width > spacing && height > spacing;
        }
        public int area { get { return width * height; } }
    }

    private static int To2Max(int t)
    {
        int times = 0;
        while (t > 1)
        {
            t = t >> 1;
            times++;
        }
        for (int i = 0; i < times; i++)
            t = t << 1;
        return t;
    }

    public static bool MakeAtlasWithPictures(Texture2D[] toCombine, int spacing, out RenderTexture atlasTexture, out List<MapTilePicInfo> infos)
    {
        atlasTexture = null;
        infos = null;
        if (toCombine == null || toCombine.Length == 0)
            return false;
        // 先给图片排个序，以平均面积为标准
        List<Texture2D> textures = new List<Texture2D>(toCombine.Length);
        textures.AddRange(toCombine);
        textures.Sort((a, b) => (b.width * b.height).CompareTo(a.width * a.height));
        Vector3Int t = Vector3Int.zero;
        foreach (var texture in textures)
        {
            if (texture.width > t.x)
                t.x = texture.width;
            if (texture.height > t.y)
                t.y = texture.height;
            t.z += (texture.width * texture.height);
        }
        // 计算初始的长宽
        t.x = To2Max(t.x);
        t.y = To2Max(t.y);
        while (t.x * t.y < t.z)
        {
            if (t.x <= t.y)
                t.x = t.x << 1;
            else
                t.y = t.y << 1;
        }
        // 按三种分划方法进行合并图集
        Vector3Int rts = t;
        List<Room> rooms = new List<Room>();
        rooms.Add(new Room()
        {
            left = 0,
            bottom = 0,
            right = rts.x,
            top = rts.y,
        });
        List<MapTilePicInfo> infos1 = new List<MapTilePicInfo>();
        RenderTexture rt1 = new RenderTexture(rts.x, rts.y, 0, RenderTextureFormat.ARGB32);
        rt1.enableRandomWrite = true;
        rt1.Create();
        while (!MakingAtlas(rt1, null, 0, ref textures, ref rooms, ref infos1, DivideBehaviour.Height, spacing))
        {
            if (rts.x <= rts.y)
                rts.x = rts.x << 1;
            else
                rts.y = rts.y << 1;
            if (RenderTexture.active == rt1)
                RenderTexture.active = null;
            rt1.Release();
            rt1 = new RenderTexture(rts.x, rts.y, 0, RenderTextureFormat.ARGB32);
            rt1.enableRandomWrite = true;
            rt1.Create();
            rooms.Clear();
            rooms.Add(new Room()
            {
                left = 0,
                bottom = 0,
                right = rts.x,
                top = rts.y,
            });
        }

        rts = t;
        rooms.Clear();
        rooms.Add(new Room()
        {
            left = 0,
            bottom = 0,
            right = rts.x,
            top = rts.y,
        });
        List<MapTilePicInfo> infos2 = new List<MapTilePicInfo>();
        RenderTexture rt2 = new RenderTexture(rts.x, rts.y, 0, RenderTextureFormat.ARGB32);
        rt2.enableRandomWrite = true;
        rt2.Create();
        while (!MakingAtlas(rt2, null, 0, ref textures, ref rooms, ref infos2, DivideBehaviour.Width, spacing))
        {
            if (rts.x <= rts.y)
                rts.x = rts.x << 1;
            else
                rts.y = rts.y << 1;
            if (RenderTexture.active == rt2)
                RenderTexture.active = null;
            rt2.Release();
            rt2 = new RenderTexture(rts.x, rts.y, 0, RenderTextureFormat.ARGB32);
            rt2.enableRandomWrite = true;
            rt2.Create();
            rooms.Clear();
            rooms.Add(new Room()
            {
                left = 0,
                bottom = 0,
                right = rts.x,
                top = rts.y,
            });
        }

        rts = t;
        rooms.Clear();
        rooms.Add(new Room()
        {
            left = 0,
            bottom = 0,
            right = rts.x,
            top = rts.y,
        });
        List<MapTilePicInfo> infos3 = new List<MapTilePicInfo>();
        RenderTexture rt3 = new RenderTexture(rts.x, rts.y, 0, RenderTextureFormat.ARGB32);
        rt3.enableRandomWrite = true;
        rt3.Create();
        while (!MakingAtlas(rt3, null, 0, ref textures, ref rooms, ref infos3, DivideBehaviour.Area, spacing))
        {
            if (rts.x <= rts.y)
                rts.x = rts.x << 1;
            else
                rts.y = rts.y << 1;
            if (RenderTexture.active == rt3)
                RenderTexture.active = null;
            rt3.Release();
            rt3 = new RenderTexture(rts.x, rts.y, 0, RenderTextureFormat.ARGB32);
            rt3.enableRandomWrite = true;
            rt3.Create();
            rooms.Clear();
            rooms.Add(new Room()
            {
                left = 0,
                bottom = 0,
                right = rts.x,
                top = rts.y,
            });
        }
        // 筛选尺寸最小的那个
        if (rt1.width * rt1.height <= rt2.width * rt2.height && rt1.width * rt1.height <= rt3.width * rt3.height)
        {
            infos = infos1;
            atlasTexture = rt1;
        }
        else if (rt2.width * rt2.height <= rt1.width * rt1.height && rt2.width * rt2.height <= rt3.width * rt3.height)
        {
            infos = infos2;
            atlasTexture = rt2;
        }
        else
        {
            infos = infos3;
            atlasTexture = rt3;
        }
        return true;
    }

    private static bool MakingAtlas(RenderTexture target, RenderTexture source, int idx, ref List<Texture2D> textures,
        ref List<Room> rooms, ref List<MapTilePicInfo> infos, DivideBehaviour divide, int spacing)
    {
        if (source == null)
            source = new RenderTexture(target);
        source.enableRandomWrite = true;
        source.Create();
        Graphics.CopyTexture(target, source);
        if (DebugMode)
            SavePNG(source, "Map/" + idx.ToString() + "-source");
        Material copyMat = new Material(Shader.Find("Hidden/CopyTextureToArea"));
        if (idx >= textures.Count)
            return true;
        Texture2D tex = textures[idx];
        //从小开始比
        rooms.Sort((a, b) => { return a.area.CompareTo(b.area); });
        for (int i = rooms.Count - 1; i >= 0; i--)
        {
            var room = rooms[i];
            // 如果算上间隔，可以放进去图片，就放
            if (tex.width + spacing <= room.width && tex.height + spacing <= room.height ||
                (tex.width <= room.width && room.right == target.width &&
                tex.height <= room.height && room.top == target.height))
            {
                rooms.RemoveAt(i);
                MapTilePicInfo info = new MapTilePicInfo()
                {
                    name = tex.name,
                    rect = new Vector4(
                        // left
                        room.left / (float)target.width,
                        // right
                        (room.left + tex.width) / (float)target.width,
                        // bottom
                        room.bottom / (float)target.height,
                        // top
                        (room.bottom + tex.height) / (float)target.height
                        ),
                    size = new Vector2(tex.width, tex.height),
                };
                infos.Add(info);
                // 
                copyMat.SetVector("_AreaRect", info.rect);
                copyMat.SetTexture("_CopyTexture", tex);
                copyMat.SetTexture("_MainTex", source);
                Graphics.Blit(null, target, copyMat, 0);
                Room r1 = new Room()
                {
                    left = room.left,
                    right = room.right,
                    bottom = room.bottom + tex.height + spacing,
                    top = room.top,
                };
                Room r2 = new Room()
                {
                    left = room.left + tex.width + spacing,
                    right = room.right,
                    bottom = room.bottom,
                    top = room.bottom + tex.height + spacing,
                };
                Room r3 = new Room()
                {
                    left = room.left,
                    right = room.left + tex.width + spacing,
                    bottom = room.bottom + tex.height + spacing,
                    top = room.top,
                };
                Room r4 = new Room()
                {
                    left = room.left + tex.width + spacing,
                    right = room.right,
                    bottom = room.bottom,
                    top = room.top,
                };
                // 切分剩下的空间
                // 注意先塞小的，再塞大的
                if (divide == DivideBehaviour.Height)
                {
                    if (r1.IsAvailable(spacing))
                        rooms.Add(r1);
                    if (r2.IsAvailable(spacing))
                        rooms.Add(r2);
                }
                else if (divide == DivideBehaviour.Width)
                {
                    if (r3.IsAvailable(spacing))
                        rooms.Add(r3);
                    if (r4.IsAvailable(spacing))
                        rooms.Add(r4);
                }
                else
                {
                    if (Mathf.Abs(r1.area - r2.area) >= Mathf.Abs(r3.area - r4.area))
                    {
                        if (r3.IsAvailable(spacing))
                            rooms.Add(r3);
                        if (r4.IsAvailable(spacing))
                            rooms.Add(r4);
                    }
                    else
                    {
                        if (r1.IsAvailable(spacing))
                            rooms.Add(r1);
                        if (r2.IsAvailable(spacing))
                            rooms.Add(r2);
                    }
                }
                if (DebugMode)
                    SavePNG(target, "Map/" + idx.ToString() + "-target");
                // 切分完成，递归下一个
                if (idx + 1 < textures.Count)
                    return MakingAtlas(target, source, idx + 1, ref textures, ref rooms, ref infos, divide, spacing);
                else
                    return true;
            }
        }
        return false;
    }

    public static void SavePNG(RenderTexture rt, string path)
    {
        Texture2D save = new Texture2D(rt.width, rt.height, TextureFormat.ARGB32, false, true);
        var prev = RenderTexture.active;
        RenderTexture.active = rt;
        save.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
        save.Apply();
        RenderTexture.active = prev;
        var texPath = Path.Combine(Application.dataPath, string.Format("{0}.png", path));
        File.WriteAllBytes(texPath, save.EncodeToPNG());
    }
#endif
    #endregion

    #region 瓦片池子
    private static Stack<MapTileRenderer> pool = new Stack<MapTileRenderer>(256);

    public static MapTileRenderer GetEmptyTile(bool enabled)
    {
        if (pool.Count > 1)
        {
            var t = pool.Pop();
            t.Enabled = enabled;
            return t;
        }
        else if (pool.Count == 1)
        {
            GameObject go = GameObject.Instantiate<GameObject>(pool.Peek().gameObject);
            var t = go.GetComponent<MapTileRenderer>();
            go.name = "Tile";
            t.Enabled = enabled;
            return t;
        }
        else
        {
            GameObject go = Resources.Load<GameObject>("Tile");
            GameObject goInScene = GameObject.Instantiate<GameObject>(go);
            goInScene.name = "Tile";
            var t = goInScene.GetComponent<MapTileRenderer>();
            Push(t);
            return GetEmptyTile(enabled);
        }
    }

    public static void Push(MapTileRenderer r)
    {
        if (r.gameObject.transform.parent != null)
            r.gameObject.transform.parent = null;
        r.Enabled = false;
        r.ResetToEmpty();
        pool.Push(r);
    }
    #endregion

    #region Runtime时提供瓦片支持
    public static readonly int CID = Shader.PropertyToID("_RendererColor");
    public static readonly int RID = Shader.PropertyToID("_TileRect");
    public static readonly int FID = Shader.PropertyToID("_Flip");
    private static Shader _tileShader;
    private static Material _defaultMaterial;
    public static Material defaultMaterial
    {
        get
        {
            if (_defaultMaterial == null)
            {
                if (_tileShader == null)
                    _tileShader = Shader.Find("Tiles/Default");
                _defaultMaterial = new Material(_tileShader);
                // 进行最基本的配置
                _defaultMaterial.SetColor(CID, Color.white);
                _defaultMaterial.SetVector(FID, Vector4.one);
                _defaultMaterial.SetVector(RID, new Vector4(0, 1, 0, 1));
                _defaultMaterial.enableInstancing = true;
            }
            return _defaultMaterial;
        }
    }

    public static Dictionary<string, MapTileAtlas> atlasDic = new Dictionary<string, MapTileAtlas>();

    internal static bool SetTile(MapTileRenderer renderer, string atlasName, string picName)
    {
        if (atlasDic.ContainsKey(atlasName))
        {
            MapTileAtlas atlas = atlasDic[atlasName];
            foreach (var pi in atlas.info.Pictures)
            {
                if (pi.name == picName)
                {
                    // 找到了，开始整理renderer
                    renderer.mr.material = atlas.material;
                    renderer.SetRect(pi.rect);
                    return true;
                }
            }
            return false;
        }
        else
        {
            Texture2D tex = Resources.Load<Texture2D>("Atlas/" + atlasName);
            string json = Resources.Load<TextAsset>("Atlas/" + atlasName + "_config").text;
            MapTileAtlasInfo info = JsonUtility.FromJson<MapTileAtlasInfo>(json);
            MapTileAtlas atlas = new MapTileAtlas()
            {
                texture = tex,
                info = info,
                material = new Material(defaultMaterial)
            };
            atlas.material.SetTexture("_MainTex", tex);
            atlasDic.Add(atlasName, atlas);
            foreach (var pi in atlas.info.Pictures)
            {
                if (pi.name == picName)
                {
                    // 找到了，开始整理renderer
                    renderer.mr.material = atlas.material;
                    renderer.SetRect(pi.rect);
                    return true;
                }
            }
            return false;
        }
    }
    #endregion


}