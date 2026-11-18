#if UNITY_EDITOR
using System;
using System.IO;
using UnityEditor;
using UnityEditor.Build;
using UnityEngine;

namespace FunCity.Pinball.Editor
{
    /// <summary>Original, generated Fun City app icon; no external image assets.</summary>
    public static class PinballIconSetup
    {
        [MenuItem("Fun City/Pinball/Configure macOS App Icon")]
        public static void Configure()
        {
            const int size = 1024;
            var texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colors = new Color32[size * size];
            var navy = new Color(0.024f, 0.039f, 0.091f);
            var cyan = new Color(0.15f, 0.92f, 1f);
            var pink = new Color(1f, 0.26f, 0.68f);
            var gold = new Color(1f, 0.74f, 0.24f);
            float Distance(float ax, float ay, float bx, float by) =>
                Mathf.Sqrt((ax - bx) * (ax - bx) + (ay - by) * (ay - by));
            float Segment(float x, float y, float ax, float ay, float bx, float by)
            {
                var vx = bx - ax; var vy = by - ay;
                var t = Mathf.Clamp01(((x - ax) * vx + (y - ay) * vy) / (vx * vx + vy * vy));
                return Distance(x, y, ax + t * vx, ay + t * vy);
            }

            for (var y = 0; y < size; y++)
            for (var x = 0; x < size; x++)
            {
                var u = (x + 0.5f) / size; var v = (y + 0.5f) / size;
                var corner = Mathf.Max(Mathf.Abs(u - 0.5f), Mathf.Abs(v - 0.5f));
                var alpha = Mathf.SmoothStep(1f, 0f, Mathf.InverseLerp(0.43f, 0.50f, corner));
                var color = Color.Lerp(navy, new Color(0.09f, 0.08f, 0.18f), v * 0.85f);
                var frame = Mathf.Min(Mathf.Abs(u - 0.055f), Mathf.Abs(u - 0.945f),
                                      Mathf.Abs(v - 0.055f), Mathf.Abs(v - 0.945f));
                if (frame < 0.012f && corner < 0.45f)
                    color = Color.Lerp(color, pink, Mathf.Clamp01((0.012f - frame) * 140f));
                // Distinctive pinball table: angled rails, opposing flippers and silver ball.
                float rail = Mathf.Min(Segment(u,v,.24f,.75f,.18f,.28f),
                                       Segment(u,v,.76f,.75f,.82f,.28f));
                float left = Segment(u,v,.26f,.25f,.49f,.37f);
                float right = Segment(u,v,.74f,.25f,.51f,.37f);
                float ball = Distance(u,v,.53f,.58f);
                if (rail < .009f) color = Color.Lerp(color, cyan, Mathf.Clamp01((.009f - rail)*125f));
                if (Mathf.Min(left,right) < .021f) color = Color.Lerp(color,pink,1f);
                if (ball < .067f) color = Color.Lerp(gold,Color.white,Mathf.Clamp01((u+v-1.1f)*4f+.40f));
                if (ball > .067f && ball < .078f) color = cyan;
                colors[y*size+x] = new Color(color.r,color.g,color.b,alpha);
            }

            texture.SetPixels32(colors); texture.Apply();
            const string folder = "Assets/Editor/Generated";
            Directory.CreateDirectory(folder);
            const string path = folder + "/VectorPinballIcon.png";
            File.WriteAllBytes(path, texture.EncodeToPNG());
            UnityEngine.Object.DestroyImmediate(texture);
            AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);
            var icon = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
            var target = NamedBuildTarget.Standalone;
            var dimensions = PlayerSettings.GetIconSizes(target, IconKind.Application);
            if (dimensions.Length == 0) throw new InvalidOperationException("No macOS icon slots available");
            var icons = new Texture2D[dimensions.Length];
            for (var i = 0; i < icons.Length; i++) icons[i] = icon;
            PlayerSettings.SetIcons(target, icons, IconKind.Application);
            AssetDatabase.SaveAssets();
            Debug.Log("Fun City Vector Pinball app icon configured for macOS.");
        }

        [MenuItem("Fun City/Pinball/Help / Controls")]
        public static void ShowHelp()
        {
            EditorUtility.DisplayDialog("Vector Pinball Help",
                "PHYSICS LAB (UNFINISHED)\n\nReturn — reset ball\nSpace — launch\nA or Left Shift — left flipper\nD or Right Shift — right flipper\nF1 — show or hide in-game help\n\nUse Fun City > Pinball > Build Physics Lab Scene to generate the test scene. Use Build macOS Physics Lab to package the standalone app. The physics laboratory is not a finished pinball game.",
                "Back to Unity");
        }
    }
}
#endif
