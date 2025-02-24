module graphics.frustum_culling;

/*
Copyright (c) 2020 Jeffery Myers

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import math.vec3d;
import math.vec4d;
import raylib : Matrix, rlGetMatrixModelview, rlGetMatrixProjection;
import std.math.algebraic;

struct Frustum {
    Vec4d[6] planes;
}

private static const enum BACK = 0;
private static const enum FRONT = 1;
private static const enum BOTTOM = 2;
private static const enum TOP = 3;
private static const enum RIGHT = 4;
private static const enum LEFT = 5;
private static const enum MAX = 6;

void normalizePlane(ref Vec4d plane) {

    double magnitudeDivisor = 1.0 / sqrt(plane.x * plane.x + plane.y * plane.y + plane.z * plane.z);

    plane.x *= magnitudeDivisor;
    plane.y *= magnitudeDivisor;
    plane.z *= magnitudeDivisor;
    plane.w *= magnitudeDivisor;
}

void extractFrustum(ref Frustum frustum) {

    Matrix projection = rlGetMatrixProjection();
    Matrix modelview = rlGetMatrixModelview();

    Matrix planes = Matrix();

    planes.m0 = modelview.m0 * projection.m0 + modelview.m1 * projection.m4 + modelview.m2 * projection.m8 + modelview
        .m3 * projection.m12;
    planes.m1 = modelview.m0 * projection.m1 + modelview.m1 * projection.m5 + modelview.m2 * projection.m9 + modelview
        .m3 * projection.m13;
    planes.m2 = modelview.m0 * projection.m2 + modelview.m1 * projection.m6 + modelview.m2 * projection.m10 + modelview
        .m3 * projection.m14;
    planes.m3 = modelview.m0 * projection.m3 + modelview.m1 * projection.m7 + modelview.m2 * projection.m11 + modelview
        .m3 * projection.m15;
    planes.m4 = modelview.m4 * projection.m0 + modelview.m5 * projection.m4 + modelview.m6 * projection.m8 + modelview
        .m7 * projection.m12;
    planes.m5 = modelview.m4 * projection.m1 + modelview.m5 * projection.m5 + modelview.m6 * projection.m9 + modelview
        .m7 * projection.m13;
    planes.m6 = modelview.m4 * projection.m2 + modelview.m5 * projection.m6 + modelview.m6 * projection.m10 + modelview
        .m7 * projection.m14;
    planes.m7 = modelview.m4 * projection.m3 + modelview.m5 * projection.m7 + modelview.m6 * projection.m11 + modelview
        .m7 * projection.m15;
    planes.m8 = modelview.m8 * projection.m0 + modelview.m9 * projection.m4 + modelview.m10 * projection.m8 + modelview
        .m11 * projection.m12;
    planes.m9 = modelview.m8 * projection.m1 + modelview.m9 * projection.m5 + modelview.m10 * projection.m9 + modelview
        .m11 * projection.m13;
    planes.m10 = modelview.m8 * projection.m2 + modelview.m9 * projection.m6 + modelview.m10 * projection.m10 +
        modelview.m11 * projection.m14;
    planes.m11 = modelview.m8 * projection.m3 + modelview.m9 * projection.m7 + modelview.m10 * projection.m11 +
        modelview.m11 * projection.m15;
    planes.m12 = modelview.m12 * projection.m0 + modelview.m13 * projection.m4 + modelview.m14 * projection.m8 +
        modelview.m15 * projection.m12;
    planes.m13 = modelview.m12 * projection.m1 + modelview.m13 * projection.m5 + modelview.m14 * projection.m9 +
        modelview.m15 * projection.m13;
    planes.m14 = modelview.m12 * projection.m2 + modelview.m13 * projection.m6 + modelview.m14 * projection.m10 +
        modelview.m15 * projection.m14;
    planes.m15 = modelview.m12 * projection.m3 + modelview.m13 * projection.m7 + modelview.m14 * projection.m11 +
        modelview.m15 * projection.m15;

    frustum.planes[RIGHT] = Vec4d(planes.m3 - planes.m0, planes.m7 - planes.m4, planes.m11 - planes.m8, planes.m15 -
            planes.m12);
    normalizePlane(frustum.planes[RIGHT]);

    frustum.planes[LEFT] = Vec4d(planes.m3 + planes.m0, planes.m7 + planes.m4, planes.m11 + planes.m8, planes.m15 +
            planes.m12);
    normalizePlane(frustum.planes[LEFT]);

    frustum.planes[TOP] = Vec4d(planes.m3 - planes.m1, planes.m7 - planes.m5, planes.m11 - planes.m9, planes.m15 -
            planes.m13);
    normalizePlane(frustum.planes[TOP]);

    frustum.planes[BOTTOM] = Vec4d(planes.m3 + planes.m1, planes.m7 + planes.m5, planes.m11 + planes.m9, planes.m15 +
            planes.m13);
    normalizePlane(frustum.planes[BOTTOM]);

    frustum.planes[BACK] = Vec4d(planes.m3 - planes.m2, planes.m7 - planes.m6, planes.m11 - planes.m10, planes.m15 -
            planes.m14);
    normalizePlane(frustum.planes[BACK]);

    frustum.planes[FRONT] = Vec4d(planes.m3 + planes.m2, planes.m7 + planes.m6, planes.m11 + planes.m10, planes.m15 +
            planes.m14);
    normalizePlane(frustum.planes[FRONT]);
}

double distanceToPlaneV(const ref Vec4d plane, const ref Vec3d position) {
    return (plane.x * position.x + plane.y * position.y + plane.z * position.z + plane.w);
}

double distanceToPlane(const ref Vec4d plane, double x, double y, double z) {
    return (plane.x * x + plane.y * y + plane.z * z + plane.w);
}

bool pointInFrustumV(const ref Frustum frustum, Vec3d position) {
    foreach (const ref plane; frustum.planes) {
        // Point is behind plane.
        if (distanceToPlaneV(plane, position) <= 0) {
            return false;
        }
    }
    return true;
}

bool pointInFrustum(const ref Frustum frustum, double x, double y, double z) {
    foreach (const ref plane; frustum.planes) {
        // Point is behind plane.
        if (distanceToPlane(plane, x, y, z) <= 0) {
            return false;
        }
    }
    return true;
}

bool sphereInFrustumV(const ref Frustum frustum, Vec3d position, double radius) {
    foreach (const ref plane; frustum.planes) {
        // Center is behind plane by more than the radius.
        if (distanceToPlaneV(plane, position) < -radius) {
            return false;
        }
    }

    return true;
}

bool aabBoxInFrustum(const ref Frustum frustum, Vec3d min, Vec3d max) {
    // If any point is in and we are good.
    if (pointInFrustum(frustum, min.x, min.y, min.z))
        return true;

    if (pointInFrustum(frustum, min.x, max.y, min.z))
        return true;

    if (pointInFrustum(frustum, max.x, max.y, min.z))
        return true;

    if (pointInFrustum(frustum, max.x, min.y, min.z))
        return true;

    if (pointInFrustum(frustum, min.x, min.y, max.z))
        return true;

    if (pointInFrustum(frustum, min.x, max.y, max.z))
        return true;

    if (pointInFrustum(frustum, max.x, max.y, max.z))
        return true;

    if (pointInFrustum(frustum, max.x, min.y, max.z))
        return true;

    // Check to see if all points are outside of any one plane, if so the entire box is outside.
    foreach (const ref plane; frustum.planes) {
        bool oneInside = false;

        if (distanceToPlane(plane, min.x, min.y, min.z) >= 0) {
            oneInside = true;
        }

        if (distanceToPlane(plane, max.x, min.y, min.z) >= 0) {
            oneInside = true;
        }

        if (distanceToPlane(plane, max.x, max.y, min.z) >= 0) {
            oneInside = true;
        }

        if (distanceToPlane(plane, min.x, max.y, min.z) >= 0) {
            oneInside = true;
        }

        if (distanceToPlane(plane, min.x, min.y, max.z) >= 0) {
            oneInside = true;
        }

        if (distanceToPlane(plane, max.x, min.y, max.z) >= 0) {
            oneInside = true;
        }

        if (distanceToPlane(plane, max.x, max.y, max.z) >= 0) {
            oneInside = true;
        }

        if (distanceToPlane(plane, min.x, max.y, max.z) >= 0) {
            oneInside = true;
        }

        if (!oneInside) {
            return false;
        }
    }

    // The box extends outside the frustum but crosses it.
    return true;
}
