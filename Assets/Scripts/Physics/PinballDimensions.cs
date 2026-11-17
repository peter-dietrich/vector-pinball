using UnityEngine;

namespace FunCity.Pinball
{
    /// <summary>
    /// Single source of physical dimensions for the pinball physics lab (meters).
    /// Ball and all playfield collision geometry are modeled in the XY plane.
    /// </summary>
    public static class PinballDimensions
    {
        public const float BallRadius = 0.12f;
        public const float BallMassKg = 0.08f;
        public const float FlipperLength = 0.85f;
        public const float FlipperWidth = 0.18f;
        public const float FlipperPivotAbsX = 0.915f;
        public const float FlipperPivotY = 0.85f;
        public const float FlipperRestAngleDeg = 24f;
        public const float FlipperActiveAngleDeg = 30f;
        public const float TableHalfWidth = 3.5f;
        public const float TableTopY = 10f;
        public const float DrainY = -0.25f;

        // The true tip-to-tip clearance at rest must exceed one ball diameter.
        public static float RestTipGap => 2f * (FlipperPivotAbsX - FlipperLength *
            Mathf.Cos(FlipperRestAngleDeg * Mathf.Deg2Rad));

        public static float GapInBallDiameters => RestTipGap / (2f * BallRadius);
    }
}
