using NUnit.Framework;
using FunCity.Pinball;

namespace FunCity.Pinball.Tests
{
    public sealed class PinballDimensionsTests
    {
        [Test]
        public void RestingFlipperGapIs115PercentOfBallDiameter()
        {
            Assert.That(PinballDimensions.GapInBallDiameters, Is.InRange(1.12f, 1.18f));
        }

        [Test]
        public void BallHasPositiveMassAndRadius()
        {
            Assert.That(PinballDimensions.BallMassKg, Is.GreaterThan(0));
            Assert.That(PinballDimensions.BallRadius, Is.GreaterThan(0));
        }

        [Test]
        public void ActiveAngleIsDifferentFromRestingAngle()
        {
            Assert.That(PinballDimensions.FlipperActiveAngleDeg,
                        Is.Not.EqualTo(PinballDimensions.FlipperRestAngleDeg));
        }
    }
}
