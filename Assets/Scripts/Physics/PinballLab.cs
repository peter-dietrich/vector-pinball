using UnityEngine;

namespace FunCity.Pinball
{
    /// <summary>
    /// Pinball laboratory. Actual Rigidbody/HingeJoint simulation, not a
    /// key-triggered ball impulse or manually teleported ball.
    /// </summary>
    public sealed class PinballLab : MonoBehaviour
    {
        [SerializeField] private Rigidbody ball;
        [SerializeField] private HingeJoint leftFlipper;
        [SerializeField] private HingeJoint rightFlipper;
        [SerializeField] private Transform ballServePoint;
        [SerializeField] private float plungerSpeed = 8.5f;
        private bool leftDown;
        private bool rightDown;
        private bool served;

        public void Configure(Rigidbody steelBall, HingeJoint left, HingeJoint right, Transform serve)
        {
            ball = steelBall;
            leftFlipper = left;
            rightFlipper = right;
            ballServePoint = serve;
            ResetBall();
        }

        private void Update()
        {
            leftDown = Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftShift);
            rightDown = Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightShift);
            if (Input.GetKeyDown(KeyCode.Return)) ResetBall();
            if (Input.GetKeyDown(KeyCode.Space) && !served) LaunchBall();
            if (Input.GetKeyDown(KeyCode.Escape))
            {
                leftDown = false;
                rightDown = false;
            }
        }

        private void FixedUpdate()
        {
            SetMotor(leftFlipper, leftDown, 900f, -320f);
            SetMotor(rightFlipper, rightDown, -900f, 320f);

            if (served && ball != null && ball.position.y < PinballDimensions.DrainY)
            {
                served = false;
                ResetBall();
            }
        }

        private static void SetMotor(HingeJoint hinge, bool pressed, float upSpeed, float returnSpeed)
        {
            if (hinge == null) return;
            var motor = hinge.motor;
            motor.force = 900f;
            motor.targetVelocity = pressed ? upSpeed : returnSpeed;
            motor.freeSpin = false;
            hinge.motor = motor;
            hinge.useMotor = true;
        }

        public void ResetBall()
        {
            if (ball == null || ballServePoint == null) return;
            served = false;
            ball.position = ballServePoint.position;
            ball.rotation = Quaternion.identity;
            ball.linearVelocity = Vector3.zero;
            ball.angularVelocity = Vector3.zero;
            ball.Sleep();
        }

        public void LaunchBall()
        {
            if (ball == null || served) return;
            served = true;
            ball.WakeUp();
            // A deterministic calibrated impulse for the physics laboratory.
            // No hidden collision assist or infinite ball-save behavior.
            ball.AddForce(Vector3.up * (plungerSpeed * ball.mass), ForceMode.Impulse);
        }

        private void OnGUI()
        {
            GUI.color = Color.white;
            GUI.Label(new Rect(18, 14, 750, 32), "VECTOR PINBALL • PHYSICS LAB v0.1.0");
            GUI.Label(new Rect(18, 42, 900, 25), "RETURN reset | SPACE launch | A / Left Shift left flipper | D / Right Shift right flipper");
            GUI.Label(new Rect(18, 68, 600, 22),
                "Resting flipper gap: " + PinballDimensions.GapInBallDiameters.ToString("F2") + " ball diameters");
        }

        private void OnApplicationFocus(bool focus)
        {
            if (!focus)
            {
                leftDown = false;
                rightDown = false;
            }
        }
    }
}
