#if UNITY_EDITOR
using System.IO;
using FunCity.Pinball;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace FunCity.Pinball.Editor
{
    /// <summary>Create a reproducible physics laboratory from Git-tracked source.</summary>
    public static class PhysicsLabSceneBuilder
    {
        [MenuItem("Fun City/Pinball/Build Physics Lab Scene")]
        public static void Build()
        {
            const string dir = "Assets/Scenes";
            Directory.CreateDirectory(dir);
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            Physics.gravity = new Vector3(0, -9.81f, 0);
            Time.fixedDeltaTime = 1f / 120f;

            var cameraObject = new GameObject("Physics Lab Camera");
            var camera = cameraObject.AddComponent<Camera>();
            camera.orthographic = true;
            camera.orthographicSize = 6.25f;
            camera.backgroundColor = new Color(0.015f, 0.025f, 0.04f);
            camera.clearFlags = CameraClearFlags.SolidColor;
            cameraObject.transform.position = new Vector3(0, 4.9f, -18f);
            cameraObject.transform.rotation = Quaternion.identity;
            cameraObject.tag = "MainCamera";

            var railMaterial = MakeMaterial("Rail", 0.12f, 0.75f, new Color(0.12f, 0.24f, 0.29f));
            var rubberMaterial = MakeMaterial("Rubber", 0.72f, 0.72f, new Color(0.75f, 0.14f, 0.12f));
            var steelMaterial = MakeMaterial("Steel", 0.35f, 0.58f, new Color(0.80f, 0.88f, 0.94f));

            StaticWall("Left Cabinet", new Vector3(-3.54f, 5f, 0), new Vector3(0.18f, 10.8f, 1f), railMaterial);
            StaticWall("Right Cabinet", new Vector3(3.54f, 5f, 0), new Vector3(0.18f, 10.8f, 1f), railMaterial);
            StaticWall("Top Rail", new Vector3(0, 10.4f, 0), new Vector3(7f, 0.18f, 1f), railMaterial);

            // Thin back plate for visibility; it cannot collide with the ball.
            var back = GameObject.CreatePrimitive(PrimitiveType.Cube);
            back.name = "Non-Colliding Backplate";
            back.transform.position = new Vector3(0, 4.95f, 0.55f);
            back.transform.localScale = new Vector3(7f, 10.3f, 0.12f);
            Object.DestroyImmediate(back.GetComponent<Collider>());
            back.GetComponent<Renderer>().sharedMaterial =
                MakeRenderMaterial("Backplate", new Color(0.035f, 0.06f, 0.085f));

            var bumperMat = MakeMaterial("Bumper Rubber", 0.92f, 0.6f, new Color(0.24f, 0.85f, 0.56f));
            Bumper("Upper Left", new Vector3(-1.20f, 6.35f, 0), bumperMat);
            Bumper("Upper Right", new Vector3(1.20f, 6.35f, 0), bumperMat);
            Bumper("Lower Center", new Vector3(0, 4.95f, 0), bumperMat);
            StaticWall("Left Funnel", new Vector3(-2.54f, 1.52f, 0), new Vector3(1.50f, 0.12f, 0.6f),
                railMaterial, -55);
            StaticWall("Right Funnel", new Vector3(2.54f, 1.52f, 0), new Vector3(1.50f, 0.12f, 0.6f),
                railMaterial, 55);

            var left = CreateFlipper("Left Flipper", -PinballDimensions.FlipperPivotAbsX,
                                     PinballDimensions.FlipperRestAngleDeg * -1f, rubberMaterial, true);
            var right = CreateFlipper("Right Flipper", PinballDimensions.FlipperPivotAbsX,
                                      PinballDimensions.FlipperRestAngleDeg, rubberMaterial, false);

            var ballObject = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            ballObject.name = "Steel Ball";
            ballObject.transform.localScale = Vector3.one * (2f * PinballDimensions.BallRadius);
            var ballCollider = ballObject.GetComponent<SphereCollider>();
            ballCollider.sharedMaterial = steelMaterial;
            ballObject.GetComponent<Renderer>().sharedMaterial = MakeRenderMaterial("Steel Ball", new Color(0.75f, 0.82f, 0.92f));
            var ballBody = ballObject.AddComponent<Rigidbody>();
            ballBody.mass = PinballDimensions.BallMassKg;
            ballBody.collisionDetectionMode = CollisionDetectionMode.ContinuousDynamic;
            ballBody.interpolation = RigidbodyInterpolation.Interpolate;
            ballBody.constraints = RigidbodyConstraints.FreezePositionZ |
                                   RigidbodyConstraints.FreezeRotationX |
                                   RigidbodyConstraints.FreezeRotationY;
            ballBody.maxAngularVelocity = 90;

            var serve = new GameObject("Ball Serve Point").transform;
            serve.position = new Vector3(2.75f, 0.55f, 0);
            var controller = new GameObject("Pinball Physics Lab").AddComponent<PinballLab>();
            controller.Configure(ballBody, left, right, serve);

            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, dir + "/PhysicsLab.unity");
            EditorBuildSettings.scenes = new[] {
                new EditorBuildSettingsScene(dir + "/PhysicsLab.unity", true)
            };
            AssetDatabase.SaveAssets();
            Debug.Log("Physics lab created at " + dir + "/PhysicsLab.unity. Press Play.");
        }

        private static PhysicMaterial MakeMaterial(string name, float bounciness, float friction, Color color)
        {
            Directory.CreateDirectory("Assets/PhysicsMaterials");
            var path = "Assets/PhysicsMaterials/" + name.Replace(" ", "") + ".physicMaterial";
            var existing = AssetDatabase.LoadAssetAtPath<PhysicMaterial>(path);
            if (existing == null)
            {
                existing = new PhysicMaterial(name);
                AssetDatabase.CreateAsset(existing, path);
            }
            existing.bounciness = bounciness;
            existing.dynamicFriction = friction;
            existing.staticFriction = friction;
            existing.bounceCombine = PhysicMaterialCombine.Maximum;
            existing.frictionCombine = PhysicMaterialCombine.Average;
            return existing;
        }

        private static Material MakeRenderMaterial(string name, Color color)
        {
            var shader = Shader.Find("Standard");
            if (shader == null) shader = Shader.Find("Hidden/InternalErrorShader");
            var mat = new Material(shader);
            mat.name = name;
            mat.color = color;
            return mat;
        }

        private static void StaticWall(string name, Vector3 position, Vector3 size,
                                       PhysicMaterial material, float zAngle = 0)
        {
            var wall = GameObject.CreatePrimitive(PrimitiveType.Cube);
            wall.name = name;
            wall.transform.position = position;
            wall.transform.localScale = size;
            wall.transform.rotation = Quaternion.Euler(0, 0, zAngle);
            wall.GetComponent<BoxCollider>().sharedMaterial = material;
            wall.GetComponent<Renderer>().sharedMaterial = MakeRenderMaterial(name, new Color(0.15f, 0.32f, 0.36f));
        }

        private static void Bumper(string name, Vector3 position, PhysicMaterial material)
        {
            var obj = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            obj.name = name;
            obj.transform.position = position;
            obj.transform.localScale = new Vector3(0.95f, 0.95f, 0.6f);
            obj.GetComponent<SphereCollider>().sharedMaterial = material;
            obj.GetComponent<Renderer>().sharedMaterial = MakeRenderMaterial(name, new Color(0.18f, 0.76f, 0.46f));
        }

        private static HingeJoint CreateFlipper(string name, float pivotX, float rotation,
                                                 PhysicMaterial material, bool left)
        {
            var obj = new GameObject(name);
            obj.transform.position = new Vector3(pivotX, PinballDimensions.FlipperPivotY, 0);
            obj.transform.rotation = Quaternion.Euler(0, 0, rotation);
            var rigidbody = obj.AddComponent<Rigidbody>();
            rigidbody.mass = 1.2f;
            rigidbody.useGravity = false;
            rigidbody.constraints = RigidbodyConstraints.FreezePositionX |
                                    RigidbodyConstraints.FreezePositionY |
                                    RigidbodyConstraints.FreezePositionZ |
                                    RigidbodyConstraints.FreezeRotationX |
                                    RigidbodyConstraints.FreezeRotationY;
            rigidbody.collisionDetectionMode = CollisionDetectionMode.ContinuousSpeculative;
            var bat = GameObject.CreatePrimitive(PrimitiveType.Cube);
            bat.name = "Tapered Bat Proxy";
            bat.transform.SetParent(obj.transform, false);
            bat.transform.localPosition = new Vector3((left ? 1 : -1) * PinballDimensions.FlipperLength / 2f, 0, 0);
            bat.transform.localScale = new Vector3(PinballDimensions.FlipperLength, PinballDimensions.FlipperWidth, 0.35f);
            bat.GetComponent<BoxCollider>().sharedMaterial = material;
            bat.GetComponent<Renderer>().sharedMaterial = MakeRenderMaterial(name, new Color(0.85f, 0.25f, 0.21f));
            var hinge = obj.AddComponent<HingeJoint>();
            hinge.anchor = Vector3.zero;
            hinge.axis = Vector3.forward;
            hinge.autoConfigureConnectedAnchor = false;
            hinge.connectedAnchor = obj.transform.position;
            hinge.useLimits = true;
            var limit = hinge.limits;
            // The joint's relative angle is measured from its starting pose.
            if (left) { limit.min = 0; limit.max = 60; }
            else { limit.min = -60; limit.max = 0; }
            limit.bounciness = 0;
            hinge.limits = limit;
            hinge.useMotor = true;
            return hinge;
        }

        [MenuItem("Fun City/Pinball/Build macOS Physics Lab")]
        public static void BuildMac()
        {
            Build();
            Directory.CreateDirectory("Builds");
            BuildPipeline.BuildPlayer(new BuildPlayerOptions {
                scenes = new[] { "Assets/Scenes/PhysicsLab.unity" },
                locationPathName = "Builds/VectorPinballPhysicsLab.app",
                target = BuildTarget.StandaloneOSX,
                options = BuildOptions.None
            });
        }
    }
}
#endif
