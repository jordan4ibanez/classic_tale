module math.quat;

import math.vec3d;

// The reason Matrix is not doubled, is because it's going to be glitchy either way on the gpu if the camera is far out.
// todo: make the world move around the camera.
import raylib : Matrix, Quaternion;
import std.algorithm.comparison;
import std.math.algebraic;
import std.math.trigonometry;

static immutable double EPSILON = 0.000001;

struct Quat {
    double x = 0;
    double y = 0;
    double z = 0;
    double w = 0;

    Quaternion toRaylib() {
        return Quaternion(x, y, z, w);
    }
}

// Add two Quats
Quat quatAdd(Quat q1, Quat q2) {
    return Quat(q1.x + q2.x, q1.y + q2.y, q1.z + q2.z, q1.w + q2.w);
}

// Add Quat and double value
Quat quatAddValue(Quat q, double add) {
    return Quat(q.x + add, q.y + add, q.z + add, q.w + add);
}

// Subtract two Quats
Quat quatSubtract(Quat q1, Quat q2) {
    return Quat(q1.x - q2.x, q1.y - q2.y, q1.z - q2.z, q1.w - q2.w);

}

// Subtract Quat and double value
Quat quatSubtractValue(Quat q, double sub) {
    return Quat(q.x - sub, q.y - sub, q.z - sub, q.w - sub);

}

// Get identity Quat
Quat quatIdentity() {
    return Quat(0.0, 0.0, 0.0, 1.0);
}

// Computes the length of a Quat
double quatLength(Quat q) {
    return sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
}

// Normalize provided Quat
Quat quatNormalize(Quat q) {
    Quat result;

    double length = sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
    if (length == 0.0)
        length = 1.0;
    double ilength = 1.0 / length;

    result.x = q.x * ilength;
    result.y = q.y * ilength;
    result.z = q.z * ilength;
    result.w = q.w * ilength;

    return result;
}

// Invert provided Quat
Quat quatInvert(Quat q) {
    Quat result = q;

    double lengthSq = q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w;

    if (lengthSq != 0.0) {
        double invLength = 1.0 / lengthSq;

        result.x *= -invLength;
        result.y *= -invLength;
        result.z *= -invLength;
        result.w *= invLength;
    }

    return result;
}

// Calculate two Quat multiplication
Quat quatMultiply(Quat q1, Quat q2) {
    Quat result;

    double qax = q1.x, qay = q1.y, qaz = q1.z, qaw = q1.w;
    double qbx = q2.x, qby = q2.y, qbz = q2.z, qbw = q2.w;

    result.x = qax * qbw + qaw * qbx + qay * qbz - qaz * qby;
    result.y = qay * qbw + qaw * qby + qaz * qbx - qax * qbz;
    result.z = qaz * qbw + qaw * qbz + qax * qby - qay * qbx;
    result.w = qaw * qbw - qax * qbx - qay * qby - qaz * qbz;

    return result;
}

// Scale Quat by double value
Quat quatScale(Quat q, double mul) {
    Quat result;

    result.x = q.x * mul;
    result.y = q.y * mul;
    result.z = q.z * mul;
    result.w = q.w * mul;

    return result;
}

// Divide two Quats
Quat quatDivide(Quat q1, Quat q2) {
    return Quat(q1.x / q2.x, q1.y / q2.y, q1.z / q2.z, q1.w / q2.w);
}

// Calculate linear interpolation between two Quats
Quat quatLerp(Quat q1, Quat q2, double amount) {
    Quat result;

    result.x = q1.x + amount * (q2.x - q1.x);
    result.y = q1.y + amount * (q2.y - q1.y);
    result.z = q1.z + amount * (q2.z - q1.z);
    result.w = q1.w + amount * (q2.w - q1.w);

    return result;
}

// Calculate slerp-optimized interpolation between two Quats
Quat quatNlerp(Quat q1, Quat q2, double amount) {
    Quat result;

    // QuatLerp(q1, q2, amount)
    result.x = q1.x + amount * (q2.x - q1.x);
    result.y = q1.y + amount * (q2.y - q1.y);
    result.z = q1.z + amount * (q2.z - q1.z);
    result.w = q1.w + amount * (q2.w - q1.w);

    // QuatNormalize(q);
    Quat q = result;
    double length = sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
    if (length == 0.0)
        length = 1.0;
    double ilength = 1.0 / length;

    result.x = q.x * ilength;
    result.y = q.y * ilength;
    result.z = q.z * ilength;
    result.w = q.w * ilength;

    return result;
}

// Calculates spherical linear interpolation between two Quats
Quat quatSlerp(Quat q1, Quat q2, double amount) {
    Quat result;

    double cosHalfTheta = q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w;

    if (cosHalfTheta < 0) {
        q2.x = -q2.x;
        q2.y = -q2.y;
        q2.z = -q2.z;
        q2.w = -q2.w;
        cosHalfTheta = -cosHalfTheta;
    }

    if (fabs(cosHalfTheta) >= 1.0)
        result = q1;
    else if (cosHalfTheta > 0.95f)
        result = quatNlerp(q1, q2, amount);
    else {
        double halfTheta = acos(cosHalfTheta);
        double sinHalfTheta = sqrt(1.0 - cosHalfTheta * cosHalfTheta);

        if (fabs(sinHalfTheta) < EPSILON) {
            result.x = (q1.x * 0.5f + q2.x * 0.5f);
            result.y = (q1.y * 0.5f + q2.y * 0.5f);
            result.z = (q1.z * 0.5f + q2.z * 0.5f);
            result.w = (q1.w * 0.5f + q2.w * 0.5f);
        } else {
            double ratioA = sin((1 - amount) * halfTheta) / sinHalfTheta;
            double ratioB = sin(amount * halfTheta) / sinHalfTheta;

            result.x = (q1.x * ratioA + q2.x * ratioB);
            result.y = (q1.y * ratioA + q2.y * ratioB);
            result.z = (q1.z * ratioA + q2.z * ratioB);
            result.w = (q1.w * ratioA + q2.w * ratioB);
        }
    }

    return result;
}

// Calculate Quat cubic spline interpolation using Cubic Hermite Spline algorithm
// as described in the GLTF 2.0 specification: https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#interpolation-cubic
Quat quatCubicHermiteSpline(Quat q1, Quat outTangent1, Quat q2, Quat inTangent2, double t) {
    double t2 = t * t;
    double t3 = t2 * t;
    double h00 = 2 * t3 - 3 * t2 + 1;
    double h10 = t3 - 2 * t2 + t;
    double h01 = -2 * t3 + 3 * t2;
    double h11 = t3 - t2;

    Quat p0 = quatScale(q1, h00);
    Quat m0 = quatScale(outTangent1, h10);
    Quat p1 = quatScale(q2, h01);
    Quat m1 = quatScale(inTangent2, h11);

    Quat result;

    result = quatAdd(p0, m0);
    result = quatAdd(result, p1);
    result = quatAdd(result, m1);
    result = quatNormalize(result);

    return result;
}

// Calculate Quat based on the rotation from one vector to another
Quat quatFromVec3dToVec3d(Vec3d from, Vec3d to) {
    Quat result;

    double cos2Theta = (from.x * to.x + from.y * to.y + from.z * to.z); // Vec3dDotProduct(from, to)
    Vec3d cross = Vec3d(
        from.y * to.z - from.z * to.y, from.z * to.x - from.x * to.z, from.x * to.y - from.y * to.x
    ); // Vec3dCrossProduct(from, to)

    result.x = cross.x;
    result.y = cross.y;
    result.z = cross.z;
    result.w = 1.0 + cos2Theta;

    // QuatNormalize(q);
    // NOTE: Normalize to essentially nlerp the original and identity to 0.5
    Quat q = result;
    double length = sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
    if (length == 0.0)
        length = 1.0;
    double ilength = 1.0 / length;

    result.x = q.x * ilength;
    result.y = q.y * ilength;
    result.z = q.z * ilength;
    result.w = q.w * ilength;

    return result;
}

// Get a Quat for a given rotation matrix
Quat quatFromMatrix(Matrix mat) {
    Quat result;

    double fourWSquaredMinus1 = mat.m0 + mat.m5 + mat.m10;
    double fourXSquaredMinus1 = mat.m0 - mat.m5 - mat.m10;
    double fourYSquaredMinus1 = mat.m5 - mat.m0 - mat.m10;
    double fourZSquaredMinus1 = mat.m10 - mat.m0 - mat.m5;

    int biggestIndex = 0;
    double fourBiggestSquaredMinus1 = fourWSquaredMinus1;
    if (fourXSquaredMinus1 > fourBiggestSquaredMinus1) {
        fourBiggestSquaredMinus1 = fourXSquaredMinus1;
        biggestIndex = 1;
    }

    if (fourYSquaredMinus1 > fourBiggestSquaredMinus1) {
        fourBiggestSquaredMinus1 = fourYSquaredMinus1;
        biggestIndex = 2;
    }

    if (fourZSquaredMinus1 > fourBiggestSquaredMinus1) {
        fourBiggestSquaredMinus1 = fourZSquaredMinus1;
        biggestIndex = 3;
    }

    double biggestVal = sqrt(fourBiggestSquaredMinus1 + 1.0) * 0.5f;
    double mult = 0.25f / biggestVal;

    final switch (biggestIndex) {
    case 0:
        result.w = biggestVal;
        result.x = (mat.m6 - mat.m9) * mult;
        result.y = (mat.m8 - mat.m2) * mult;
        result.z = (mat.m1 - mat.m4) * mult;
        break;
    case 1:
        result.x = biggestVal;
        result.w = (mat.m6 - mat.m9) * mult;
        result.y = (mat.m1 + mat.m4) * mult;
        result.z = (mat.m8 + mat.m2) * mult;
        break;
    case 2:
        result.y = biggestVal;
        result.w = (mat.m8 - mat.m2) * mult;
        result.x = (mat.m1 + mat.m4) * mult;
        result.z = (mat.m6 + mat.m9) * mult;
        break;
    case 3:
        result.z = biggestVal;
        result.w = (mat.m1 - mat.m4) * mult;
        result.x = (mat.m8 + mat.m2) * mult;
        result.y = (mat.m6 + mat.m9) * mult;
        break;
    }

    return result;
}

// Get a matrix for a given Quat
Matrix quatToMatrix(Quat q) {
    Matrix result = Matrix(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    ); // MatrixIdentity()

    double a2 = q.x * q.x;
    double b2 = q.y * q.y;
    double c2 = q.z * q.z;
    double ac = q.x * q.z;
    double ab = q.x * q.y;
    double bc = q.y * q.z;
    double ad = q.w * q.x;
    double bd = q.w * q.y;
    double cd = q.w * q.z;

    result.m0 = 1 - 2 * (b2 + c2);
    result.m1 = 2 * (ab + cd);
    result.m2 = 2 * (ac - bd);

    result.m4 = 2 * (ab - cd);
    result.m5 = 1 - 2 * (a2 + c2);
    result.m6 = 2 * (bc + ad);

    result.m8 = 2 * (ac + bd);
    result.m9 = 2 * (bc - ad);
    result.m10 = 1 - 2 * (a2 + b2);

    return result;
}

// Get rotation Quat for an angle and axis
// NOTE: Angle must be provided in radians
Quat quatFromAxisAngle(Vec3d axis, double angle) {
    Quat result = Quat(0.0, 0.0, 0.0, 1.0);

    double axisLength = sqrt(axis.x * axis.x + axis.y * axis.y + axis.z * axis.z);

    if (axisLength != 0.0) {
        angle *= 0.5f;

        double length = 0.0;
        double ilength = 0.0;

        // Vec3dNormalize(axis)
        length = axisLength;
        if (length == 0.0)
            length = 1.0;
        ilength = 1.0 / length;
        axis.x *= ilength;
        axis.y *= ilength;
        axis.z *= ilength;

        double sinres = sin(angle);
        double cosres = cos(angle);

        result.x = axis.x * sinres;
        result.y = axis.y * sinres;
        result.z = axis.z * sinres;
        result.w = cosres;

        // QuatNormalize(q);
        Quat q = result;
        length = sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
        if (length == 0.0)
            length = 1.0;
        ilength = 1.0 / length;
        result.x = q.x * ilength;
        result.y = q.y * ilength;
        result.z = q.z * ilength;
        result.w = q.w * ilength;
    }

    return result;
}

// Get the rotation angle and axis for a given Quat
void quatToAxisAngle(Quat q, Vec3d* outAxis, double* outAngle) {
    if (fabs(q.w) > 1.0) {
        // QuatNormalize(q);
        double length = sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
        if (length == 0.0)
            length = 1.0;
        double ilength = 1.0 / length;

        q.x = q.x * ilength;
        q.y = q.y * ilength;
        q.z = q.z * ilength;
        q.w = q.w * ilength;
    }

    Vec3d resAxis = Vec3d(0.0, 0.0, 0.0);
    double resAngle = 2.0 * acos(q.w);
    double den = sqrt(1.0 - q.w * q.w);

    if (den > EPSILON) {
        resAxis.x = q.x / den;
        resAxis.y = q.y / den;
        resAxis.z = q.z / den;
    } else {
        // This occurs when the angle is zero.
        // Not a problem: just set an arbitrary normalized axis.
        resAxis.x = 1.0;
    }

    *outAxis = resAxis;
    *outAngle = resAngle;
}

// Get the Quat equivalent to Euler angles
// NOTE: Rotation order is ZYX
Quat quatFromEuler(double pitch, double yaw, double roll) {
    Quat result;

    double x0 = cos(pitch * 0.5f);
    double x1 = sin(pitch * 0.5f);
    double y0 = cos(yaw * 0.5f);
    double y1 = sin(yaw * 0.5f);
    double z0 = cos(roll * 0.5f);
    double z1 = sin(roll * 0.5f);

    result.x = x1 * y0 * z0 - x0 * y1 * z1;
    result.y = x0 * y1 * z0 + x1 * y0 * z1;
    result.z = x0 * y0 * z1 - x1 * y1 * z0;
    result.w = x0 * y0 * z0 + x1 * y1 * z1;

    return result;
}

// Get the Euler angles equivalent to Quat (roll, pitch, yaw)
// NOTE: Angles are returned in a Vec3d struct in radians
Vec3d quatToEuler(Quat q) {
    Vec3d result;

    // Roll (x-axis rotation)
    double x0 = 2.0 * (q.w * q.x + q.y * q.z);
    double x1 = 1.0 - 2.0 * (q.x * q.x + q.y * q.y);
    result.x = atan2(x0, x1);

    // Pitch (y-axis rotation)
    double y0 = 2.0 * (q.w * q.y - q.z * q.x);
    y0 = y0 > 1.0 ? 1.0 : y0;
    y0 = y0 < -1.0 ? -1.0 : y0;
    result.y = asin(y0);

    // Yaw (z-axis rotation)
    double z0 = 2.0 * (q.w * q.z + q.x * q.y);
    double z1 = 1.0 - 2.0 * (q.y * q.y + q.z * q.z);
    result.z = atan2(z0, z1);

    return result;
}

// Transform a Quat given a transformation matrix
Quat quatTransform(Quat q, Matrix mat) {
    Quat result;

    result.x = mat.m0 * q.x + mat.m4 * q.y + mat.m8 * q.z + mat.m12 * q.w;
    result.y = mat.m1 * q.x + mat.m5 * q.y + mat.m9 * q.z + mat.m13 * q.w;
    result.z = mat.m2 * q.x + mat.m6 * q.y + mat.m10 * q.z + mat.m14 * q.w;
    result.w = mat.m3 * q.x + mat.m7 * q.y + mat.m11 * q.z + mat.m15 * q.w;

    return result;
}

// Check whether two given Quats are almost equal
int quatEquals(Quat p, Quat q) {

    int result = (((fabs(p.x - q.x)) <= (EPSILON * max(1.0, max(fabs(p.x), fabs(q.x))))) &&
            ((fabs(p.y - q.y)) <= (EPSILON * max(1.0, max(fabs(p.y), fabs(q.y))))) &&
            ((fabs(p.z - q.z)) <= (EPSILON * max(1.0, max(fabs(p.z), fabs(q.z))))) &&
            ((fabs(p.w - q.w)) <= (EPSILON * max(1.0, max(fabs(p.w), fabs(q.w)))))) ||
        (((fabs(p.x + q.x)) <= (EPSILON * max(1.0, max(fabs(p.x), fabs(q.x))))) &&
                ((fabs(p.y + q.y)) <= (EPSILON * max(1.0, max(fabs(p.y), fabs(q.y))))) &&
                ((fabs(p.z + q.z)) <= (EPSILON * max(1.0, max(fabs(p.z), fabs(q.z))))) &&
                ((fabs(p.w + q.w)) <= (EPSILON * max(1.0, max(fabs(p.w), fabs(q.w))))));

    return result;
}
