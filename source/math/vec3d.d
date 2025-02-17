module math.vec3d;

import math.quat;
import raylib : Matrix;
import std.algorithm.comparison;
import std.math.algebraic;
import std.math.trigonometry;

struct Vec3d {
    double x = 0;
    double y = 0;
    double z = 0;
}

// Vector with components value 0.0f
Vec3d vec3dZero() {
    Vec3d result = {0.0f, 0.0f, 0.0f};

    return result;
}

// Vector with components value 1.0f
Vec3d vec3dOne() {
    Vec3d result = {1.0f, 1.0f, 1.0f};

    return result;
}

// Add two vectors
Vec3d vec3dAdd(Vec3d v1, Vec3d v2) {
    Vec3d result = {v1.x + v2.x, v1.y + v2.y, v1.z + v2.z};

    return result;
}

// Add vector and double value
Vec3d vec3dAddValue(Vec3d v, double add) {
    Vec3d result = {v.x + add, v.y + add, v.z + add};

    return result;
}

// Subtract two vectors
Vec3d vec3dSubtract(Vec3d v1, Vec3d v2) {
    Vec3d result = {v1.x - v2.x, v1.y - v2.y, v1.z - v2.z};

    return result;
}

// Subtract vector by double value
Vec3d vec3dSubtractValue(Vec3d v, double sub) {
    Vec3d result = {v.x - sub, v.y - sub, v.z - sub};

    return result;
}

// Multiply vector by scalar
Vec3d vec3dScale(Vec3d v, double scalar) {
    Vec3d result = {v.x * scalar, v.y * scalar, v.z * scalar};

    return result;
}

// Multiply vector by vector
Vec3d vec3dMultiply(Vec3d v1, Vec3d v2) {
    Vec3d result = {v1.x * v2.x, v1.y * v2.y, v1.z * v2.z};

    return result;
}

// Calculate two vectors cross product
Vec3d vec3dCrossProduct(Vec3d v1, Vec3d v2) {
    Vec3d result = {
        v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y * v2.x
    };

    return result;
}

// Calculate one vector perpendicular vector
Vec3d vec3dPerpendicular(Vec3d v) {
    Vec3d result;

    double min = abs(v.x);
    Vec3d cardinalAxis = {1.0f, 0.0f, 0.0f};

    if (abs(v.y) < min) {
        min = abs(v.y);
        Vec3d tmp = {0.0f, 1.0f, 0.0f};
        cardinalAxis = tmp;
    }

    if (abs(v.z) < min) {
        Vec3d tmp = {0.0f, 0.0f, 1.0f};
        cardinalAxis = tmp;
    }

    // Cross product between vectors
    result.x = v.y * cardinalAxis.z - v.z * cardinalAxis.y;
    result.y = v.z * cardinalAxis.x - v.x * cardinalAxis.z;
    result.z = v.x * cardinalAxis.y - v.y * cardinalAxis.x;

    return result;
}

// Calculate vector length
double vec3dLength(const Vec3d v) {
    double result = sqrt(v.x * v.x + v.y * v.y + v.z * v.z);

    return result;
}

// Calculate vector square length
double vec3dLengthSqr(const Vec3d v) {
    double result = v.x * v.x + v.y * v.y + v.z * v.z;

    return result;
}

// Calculate two vectors dot product
double vec3dDotProduct(Vec3d v1, Vec3d v2) {
    double result = (v1.x * v2.x + v1.y * v2.y + v1.z * v2.z);

    return result;
}

// Calculate distance between two vectors
double vec3dDistance(Vec3d v1, Vec3d v2) {
    double result = 0.0f;

    double dx = v2.x - v1.x;
    double dy = v2.y - v1.y;
    double dz = v2.z - v1.z;
    result = sqrt(dx * dx + dy * dy + dz * dz);

    return result;
}

// Calculate square distance between two vectors
double vec3dDistanceSqr(Vec3d v1, Vec3d v2) {
    double result = 0.0f;

    double dx = v2.x - v1.x;
    double dy = v2.y - v1.y;
    double dz = v2.z - v1.z;
    result = dx * dx + dy * dy + dz * dz;

    return result;
}

// Calculate angle between two vectors
double vec3dAngle(Vec3d v1, Vec3d v2) {
    double result = 0.0f;

    Vec3d cross = {
        v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y * v2.x
    };
    double len = sqrt(cross.x * cross.x + cross.y * cross.y + cross.z * cross.z);
    double dot = (v1.x * v2.x + v1.y * v2.y + v1.z * v2.z);
    result = atan2(len, dot);

    return result;
}

// Negate provided vector (invert direction)
Vec3d vec3dNegate(Vec3d v) {
    Vec3d result = {-v.x, -v.y, -v.z};

    return result;
}

// Divide vector by vector
Vec3d vec3dDivide(Vec3d v1, Vec3d v2) {
    Vec3d result = {v1.x / v2.x, v1.y / v2.y, v1.z / v2.z};

    return result;
}

// Normalize provided vector
Vec3d vec3dNormalize(Vec3d v) {
    Vec3d result = v;

    double length = sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
    if (length != 0.0f) {
        double ilength = 1.0f / length;

        result.x *= ilength;
        result.y *= ilength;
        result.z *= ilength;
    }

    return result;
}

//Calculate the projection of the vector v1 on to v2
Vec3d vec3dProject(Vec3d v1, Vec3d v2) {
    Vec3d result;

    double v1dv2 = (v1.x * v2.x + v1.y * v2.y + v1.z * v2.z);
    double v2dv2 = (v2.x * v2.x + v2.y * v2.y + v2.z * v2.z);

    double mag = v1dv2 / v2dv2;

    result.x = v2.x * mag;
    result.y = v2.y * mag;
    result.z = v2.z * mag;

    return result;
}

//Calculate the rejection of the vector v1 on to v2
Vec3d vec3dReject(Vec3d v1, Vec3d v2) {
    Vec3d result;

    double v1dv2 = (v1.x * v2.x + v1.y * v2.y + v1.z * v2.z);
    double v2dv2 = (v2.x * v2.x + v2.y * v2.y + v2.z * v2.z);

    double mag = v1dv2 / v2dv2;

    result.x = v1.x - (v2.x * mag);
    result.y = v1.y - (v2.y * mag);
    result.z = v1.z - (v2.z * mag);

    return result;
}

// Orthonormalize provided vectors
// Makes vectors normalized and orthogonal to each other
// Gram-Schmidt function implementation
void vec3dOrthoNormalize(Vec3d* v1, Vec3d* v2) {
    double length = 0.0f;
    double ilength = 0.0f;

    // Vec3dNormalize(*v1);
    Vec3d v = *v1;
    length = sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
    if (length == 0.0f)
        length = 1.0f;
    ilength = 1.0f / length;
    v1.x *= ilength;
    v1.y *= ilength;
    v1.z *= ilength;

    // Vec3dCrossProduct(*v1, *v2)
    Vec3d vn1 = {
        v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y * v2.x
    };

    // Vec3dNormalize(vn1);
    v = vn1;
    length = sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
    if (length == 0.0f)
        length = 1.0f;
    ilength = 1.0f / length;
    vn1.x *= ilength;
    vn1.y *= ilength;
    vn1.z *= ilength;

    // Vec3dCrossProduct(vn1, *v1)
    Vec3d vn2 = {
        vn1.y * v1.z - vn1.z * v1.y, vn1.z * v1.x - vn1.x * v1.z, vn1.x * v1.y - vn1.y * v1.x
    };

    *v2 = vn2;
}

// Transforms a Vec3d by a given Matrix
Vec3d vec3dTransform(Vec3d v, Matrix mat) {
    Vec3d result;

    double x = v.x;
    double y = v.y;
    double z = v.z;

    result.x = mat.m0 * x + mat.m4 * y + mat.m8 * z + mat.m12;
    result.y = mat.m1 * x + mat.m5 * y + mat.m9 * z + mat.m13;
    result.z = mat.m2 * x + mat.m6 * y + mat.m10 * z + mat.m14;

    return result;
}

// Transform a vector by Quat rotation
Vec3d vec3dRotateByQuat(Vec3d v, Quat q) {
    Vec3d result;

    result.x = v.x * (q.x * q.x + q.w * q.w - q.y * q.y - q.z * q.z) + v.y * (
        2 * q.x * q.y - 2 * q.w * q.z) + v.z * (2 * q.x * q.z + 2 * q.w * q.y);
    result.y = v.x * (2 * q.w * q.z + 2 * q.x * q.y) + v.y * (
        q.w * q.w - q.x * q.x + q.y * q.y - q.z * q.z) + v.z * (-2 * q.w * q.x + 2 * q.y * q.z);
    result.z = v.x * (-2 * q.w * q.y + 2 * q.x * q.z) + v.y * (
        2 * q.w * q.x + 2 * q.y * q.z) + v.z * (q.w * q.w - q.x * q.x - q.y * q.y + q.z * q.z);

    return result;
}

// Rotates a vector around an axis
Vec3d vec3dRotateByAxisAngle(Vec3d v, Vec3d axis, double angle) {
    // Using Euler-Rodrigues Formula
    // Ref.: https://en.wikipedia.org/w/index.php?title=Euler%E2%80%93Rodrigues_formula

    Vec3d result = v;

    // Vec3dNormalize(axis);
    double length = sqrt(axis.x * axis.x + axis.y * axis.y + axis.z * axis.z);
    if (length == 0.0f)
        length = 1.0f;
    double ilength = 1.0f / length;
    axis.x *= ilength;
    axis.y *= ilength;
    axis.z *= ilength;

    angle /= 2.0f;
    double a = sin(angle);
    double b = axis.x * a;
    double c = axis.y * a;
    double d = axis.z * a;
    a = cos(angle);
    Vec3d w = {b, c, d};

    // Vec3dCrossProduct(w, v)
    Vec3d wv = {w.y * v.z - w.z * v.y, w.z * v.x - w.x * v.z, w.x * v.y - w.y * v.x};

    // Vec3dCrossProduct(w, wv)
    Vec3d wwv = {
        w.y * wv.z - w.z * wv.y, w.z * wv.x - w.x * wv.z, w.x * wv.y - w.y * wv.x
    };

    // Vec3dScale(wv, 2*a)
    a *= 2;
    wv.x *= a;
    wv.y *= a;
    wv.z *= a;

    // Vec3dScale(wwv, 2)
    wwv.x *= 2;
    wwv.y *= 2;
    wwv.z *= 2;

    result.x += wv.x;
    result.y += wv.y;
    result.z += wv.z;

    result.x += wwv.x;
    result.y += wwv.y;
    result.z += wwv.z;

    return result;
}

// Move Vector towards target
Vec3d vec3dMoveTowards(Vec3d v, Vec3d target, double maxDistance) {
    Vec3d result;

    double dx = target.x - v.x;
    double dy = target.y - v.y;
    double dz = target.z - v.z;
    double value = (dx * dx) + (dy * dy) + (dz * dz);

    if ((value == 0) || ((maxDistance >= 0) && (value <= maxDistance * maxDistance)))
        return target;

    double dist = sqrt(value);

    result.x = v.x + dx / dist * maxDistance;
    result.y = v.y + dy / dist * maxDistance;
    result.z = v.z + dz / dist * maxDistance;

    return result;
}

// Calculate linear interpolation between two vectors
Vec3d vec3dLerp(Vec3d v1, Vec3d v2, double amount) {
    Vec3d result;

    result.x = v1.x + amount * (v2.x - v1.x);
    result.y = v1.y + amount * (v2.y - v1.y);
    result.z = v1.z + amount * (v2.z - v1.z);

    return result;
}

// Calculate cubic hermite interpolation between two vectors and their tangents
// as described in the GLTF 2.0 specification: https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#interpolation-cubic
Vec3d vec3dCubicHermite(Vec3d v1, Vec3d tangent1, Vec3d v2, Vec3d tangent2, double amount) {
    Vec3d result;

    double amountPow2 = amount * amount;
    double amountPow3 = amount * amount * amount;

    result.x = (2 * amountPow3 - 3 * amountPow2 + 1) * v1.x + (
        amountPow3 - 2 * amountPow2 + amount) * tangent1.x + (
        -2 * amountPow3 + 3 * amountPow2) * v2.x + (amountPow3 - amountPow2) * tangent2.x;
    result.y = (2 * amountPow3 - 3 * amountPow2 + 1) * v1.y + (
        amountPow3 - 2 * amountPow2 + amount) * tangent1.y + (
        -2 * amountPow3 + 3 * amountPow2) * v2.y + (amountPow3 - amountPow2) * tangent2.y;
    result.z = (2 * amountPow3 - 3 * amountPow2 + 1) * v1.z + (
        amountPow3 - 2 * amountPow2 + amount) * tangent1.z + (
        -2 * amountPow3 + 3 * amountPow2) * v2.z + (amountPow3 - amountPow2) * tangent2.z;

    return result;
}

// Calculate reflected vector to normal
Vec3d vec3dReflect(Vec3d v, Vec3d normal) {
    Vec3d result;

    // I is the original vector
    // N is the normal of the incident plane
    // R = I - (2*N*(DotProduct[I, N]))

    double dotProduct = (v.x * normal.x + v.y * normal.y + v.z * normal.z);

    result.x = v.x - (2.0f * normal.x) * dotProduct;
    result.y = v.y - (2.0f * normal.y) * dotProduct;
    result.z = v.z - (2.0f * normal.z) * dotProduct;

    return result;
}

// Get min value for each pair of components
Vec3d vec3dMin(Vec3d v1, Vec3d v2) {
    Vec3d result;

    result.x = min(v1.x, v2.x);
    result.y = min(v1.y, v2.y);
    result.z = min(v1.z, v2.z);

    return result;
}

// Get max value for each pair of components
Vec3d vec3dMax(Vec3d v1, Vec3d v2) {
    Vec3d result;

    result.x = max(v1.x, v2.x);
    result.y = max(v1.y, v2.y);
    result.z = max(v1.z, v2.z);

    return result;
}

// Compute barycenter coordinates (u, v, w) for point p with respect to triangle (a, b, c)
// NOTE: Assumes P is on the plane of the triangle
Vec3d vec3dBarycenter(Vec3d p, Vec3d a, Vec3d b, Vec3d c) {
    Vec3d result;

    Vec3d v0 = {b.x - a.x, b.y - a.y, b.z - a.z}; // Vec3dSubtract(b, a)
    Vec3d v1 = {c.x - a.x, c.y - a.y, c.z - a.z}; // Vec3dSubtract(c, a)
    Vec3d v2 = {p.x - a.x, p.y - a.y, p.z - a.z}; // Vec3dSubtract(p, a)
    double d00 = (v0.x * v0.x + v0.y * v0.y + v0.z * v0.z); // Vec3dDotProduct(v0, v0)
    double d01 = (v0.x * v1.x + v0.y * v1.y + v0.z * v1.z); // Vec3dDotProduct(v0, v1)
    double d11 = (v1.x * v1.x + v1.y * v1.y + v1.z * v1.z); // Vec3dDotProduct(v1, v1)
    double d20 = (v2.x * v0.x + v2.y * v0.y + v2.z * v0.z); // Vec3dDotProduct(v2, v0)
    double d21 = (v2.x * v1.x + v2.y * v1.y + v2.z * v1.z); // Vec3dDotProduct(v2, v1)

    double denom = d00 * d11 - d01 * d01;

    result.y = (d11 * d20 - d01 * d21) / denom;
    result.z = (d00 * d21 - d01 * d20) / denom;
    result.x = 1.0f - (result.z + result.y);

    return result;
}

// Projects a Vec3d from screen space into object space
// NOTE: We are avoiding calling other raymath functions despite available
Vec3d vec3dUnproject(Vec3d source, Matrix projection, Matrix view) {
    Vec3d result;

    // Calculate unprojected matrix (multiply view matrix by projection matrix) and invert it
    Matrix matViewProj = { // MatrixMultiply(view, projection);
        view.m0 * projection.m0 + view.m1 * projection.m4 + view.m2 * projection.m8 + view.m3 * projection.m12,
        view.m0 * projection.m1 + view.m1 * projection.m5 + view.m2 * projection.m9 + view.m3 * projection.m13,
        view.m0 * projection.m2 + view.m1 * projection.m6 + view.m2 * projection.m10 + view.m3 * projection.m14,
        view.m0 * projection.m3 + view.m1 * projection.m7 + view.m2 * projection.m11 + view.m3 * projection.m15,
        view.m4 * projection.m0 + view.m5 * projection.m4 + view.m6 * projection.m8 + view.m7 * projection.m12,
        view.m4 * projection.m1 + view.m5 * projection.m5 + view.m6 * projection.m9 + view.m7 * projection.m13,
        view.m4 * projection.m2 + view.m5 * projection.m6 + view.m6 * projection.m10 + view.m7 * projection.m14,
        view.m4 * projection.m3 + view.m5 * projection.m7 + view.m6 * projection.m11 + view.m7 * projection.m15,
        view.m8 * projection.m0 + view.m9 * projection.m4 + view.m10 * projection.m8 + view.m11 * projection.m12,
        view.m8 * projection.m1 + view.m9 * projection.m5 + view.m10 * projection.m9 + view.m11 * projection.m13,
        view.m8 * projection.m2 + view.m9 * projection.m6 + view.m10 * projection.m10 + view.m11 * projection.m14,
        view.m8 * projection.m3 + view.m9 * projection.m7 + view.m10 * projection.m11 + view.m11 * projection.m15,
        view.m12 * projection.m0 + view.m13 * projection.m4 + view.m14 * projection.m8 + view.m15 * projection.m12,
        view.m12 * projection.m1 + view.m13 * projection.m5 + view.m14 * projection.m9 + view.m15 * projection.m13,
        view.m12 * projection.m2 + view.m13 * projection.m6 + view.m14 * projection.m10 + view.m15 * projection.m14,
        view.m12 * projection.m3 + view.m13 * projection.m7 + view.m14 * projection.m11 + view.m15 * projection
            .m15
    };

    // Calculate inverted matrix . MatrixInvert(matViewProj);
    // Cache the matrix values (speed optimization)
    double a00 = matViewProj.m0, a01 = matViewProj.m1, a02 = matViewProj.m2, a03 = matViewProj.m3;
    double a10 = matViewProj.m4, a11 = matViewProj.m5, a12 = matViewProj.m6, a13 = matViewProj.m7;
    double a20 = matViewProj.m8, a21 = matViewProj.m9, a22 = matViewProj.m10, a23 = matViewProj.m11;
    double a30 = matViewProj.m12, a31 = matViewProj.m13, a32 = matViewProj.m14, a33 = matViewProj
        .m15;

    double b00 = a00 * a11 - a01 * a10;
    double b01 = a00 * a12 - a02 * a10;
    double b02 = a00 * a13 - a03 * a10;
    double b03 = a01 * a12 - a02 * a11;
    double b04 = a01 * a13 - a03 * a11;
    double b05 = a02 * a13 - a03 * a12;
    double b06 = a20 * a31 - a21 * a30;
    double b07 = a20 * a32 - a22 * a30;
    double b08 = a20 * a33 - a23 * a30;
    double b09 = a21 * a32 - a22 * a31;
    double b10 = a21 * a33 - a23 * a31;
    double b11 = a22 * a33 - a23 * a32;

    // Calculate the invert determinant (inlined to avoid double-caching)
    double invDet = 1.0f / (b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06);

    Matrix matViewProjInv = {
        (a11 * b11 - a12 * b10 + a13 * b09) * invDet,
        (-a01 * b11 + a02 * b10 - a03 * b09) * invDet,
        (a31 * b05 - a32 * b04 + a33 * b03) * invDet,
        (-a21 * b05 + a22 * b04 - a23 * b03) * invDet,
        (-a10 * b11 + a12 * b08 - a13 * b07) * invDet,
        (a00 * b11 - a02 * b08 + a03 * b07) * invDet,
        (-a30 * b05 + a32 * b02 - a33 * b01) * invDet,
        (a20 * b05 - a22 * b02 + a23 * b01) * invDet,
        (a10 * b10 - a11 * b08 + a13 * b06) * invDet,
        (-a00 * b10 + a01 * b08 - a03 * b06) * invDet,
        (a30 * b04 - a31 * b02 + a33 * b00) * invDet,
        (-a20 * b04 + a21 * b02 - a23 * b00) * invDet,
        (-a10 * b09 + a11 * b07 - a12 * b06) * invDet,
        (a00 * b09 - a01 * b07 + a02 * b06) * invDet,
        (-a30 * b03 + a31 * b01 - a32 * b00) * invDet,
        (a20 * b03 - a21 * b01 + a22 * b00) * invDet
    };

    // Create Quat from source point
    Quat quat = {source.x, source.y, source.z, 1.0f};

    // Multiply quat point by unprojecte matrix
    Quat qtransformed = { // QuatTransform(quat, matViewProjInv)
        matViewProjInv.m0 * quat.x + matViewProjInv.m4 * quat.y + matViewProjInv.m8 * quat.z +
            matViewProjInv.m12 * quat.w,
        matViewProjInv.m1 * quat.x + matViewProjInv.m5 * quat.y + matViewProjInv.m9 * quat.z +
            matViewProjInv.m13 * quat.w,
        matViewProjInv.m2 * quat.x + matViewProjInv.m6 * quat.y + matViewProjInv.m10 * quat.z +
            matViewProjInv.m14 * quat.w,
        matViewProjInv.m3 * quat.x + matViewProjInv.m7 * quat.y + matViewProjInv.m11 * quat.z +
            matViewProjInv.m15 * quat.w
    };

    // Normalized world points in vectors
    result.x = qtransformed.x / qtransformed.w;
    result.y = qtransformed.y / qtransformed.w;
    result.z = qtransformed.z / qtransformed.w;

    return result;
}

// Get Vec3d as double array
double[3] vec3dTodoubleV(Vec3d v) {
    double[3] buffer = 0;

    buffer[0] = v.x;
    buffer[1] = v.y;
    buffer[2] = v.z;

    return buffer;
}

// Invert the given vector
Vec3d vec3dInvert(Vec3d v) {
    Vec3d result = {1.0f / v.x, 1.0f / v.y, 1.0f / v.z};

    return result;
}

// Clamp the components of the vector between
// min and max values specified by the given vectors
Vec3d vec3dClamp(Vec3d v, Vec3d minIn, Vec3d maxIn) {
    Vec3d result;

    result.x = min(maxIn.x, max(minIn.x, v.x));
    result.y = min(maxIn.y, max(minIn.y, v.y));
    result.z = min(maxIn.z, max(minIn.z, v.z));

    return result;
}

// Clamp the magnitude of the vector between two values
Vec3d vec3dClampValue(Vec3d v, double min, double max) {
    Vec3d result = v;

    double length = (v.x * v.x) + (v.y * v.y) + (v.z * v.z);
    if (length > 0.0f) {
        length = sqrt(length);

        double scale = 1; // By default, 1 as the neutral element.
        if (length < min) {
            scale = min / length;
        } else if (length > max) {
            scale = max / length;
        }

        result.x = v.x * scale;
        result.y = v.y * scale;
        result.z = v.z * scale;
    }

    return result;
}

// Check whether two given vectors are almost equal
int vec3dEquals(Vec3d p, Vec3d q) {

    static immutable double EPSILON = 0.000001;

    int result = ((abs(p.x - q.x)) <= (EPSILON * max(1.0f, max(abs(p.x), abs(q.x))))) &&
        ((abs(p.y - q.y)) <= (EPSILON * max(1.0f, max(abs(p.y), abs(q.y))))) &&
        ((abs(p.z - q.z)) <= (EPSILON * max(1.0f, max(abs(p.z), abs(q.z)))));

    return result;
}

// Compute the direction of a refracted ray
// v: normalized direction of the incoming ray
// n: normalized normal vector of the interface of two optical media
// r: ratio of the refractive index of the medium from where the ray comes
//    to the refractive index of the medium on the other side of the surface
Vec3d vec3dRefract(Vec3d v, Vec3d n, double r) {
    Vec3d result;

    double dot = v.x * n.x + v.y * n.y + v.z * n.z;
    double d = 1.0f - r * r * (1.0f - dot * dot);

    if (d >= 0.0f) {
        d = sqrt(d);
        v.x = r * v.x - (r * dot + d) * n.x;
        v.y = r * v.y - (r * dot + d) * n.y;
        v.z = r * v.z - (r * dot + d) * n.z;

        result = v;
    }

    return result;
}
