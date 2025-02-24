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

import raylib;
import std.math.algebraic;

struct Frustum {
    Vector4[6] planes;
}

const static enum BACK = 0;
const static enum FRONT = 1;
const static enum BOTTOM = 2;
const static enum TOP = 3;
const static enum RIGHT = 4;
const static enum LEFT = 5;
const static enum MAX = 6;

void normalizePlane(Vector4* plane) {
    if (plane is null)
        return;

    float magnitude = sqrt(plane.x * plane.x + plane.y * plane.y + plane.z * plane.z);

    plane.x /= magnitude;
    plane.y /= magnitude;
    plane.z /= magnitude;
    plane.w /= magnitude;
}

void extractFrustum(Frustum* frustum) {
    if (frustum is null)
        return;

    Matrix projection = rlGetMatrixProjection();
    Matrix modelview = rlGetMatrixModelview();

    Matrix planes = {0};

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

    frustum.planes[RIGHT] = Vector4(planes.m3 - planes.m0, planes.m7 - planes.m4, planes.m11 - planes.m8, planes.m15 -
            planes.m12);
    normalizePlane(&frustum.planes[RIGHT]);

    frustum.planes[LEFT] = Vector4(planes.m3 + planes.m0, planes.m7 + planes.m4, planes.m11 + planes.m8, planes.m15 +
            planes.m12);
    normalizePlane(&frustum.planes[LEFT]);

    frustum.planes[TOP] = Vector4(planes.m3 - planes.m1, planes.m7 - planes.m5, planes.m11 - planes.m9, planes.m15 -
            planes.m13);
    normalizePlane(&frustum.planes[TOP]);

    frustum.planes[BOTTOM] = Vector4(planes.m3 + planes.m1, planes.m7 + planes.m5, planes.m11 + planes.m9, planes.m15 +
            planes.m13);
    normalizePlane(&frustum.planes[BOTTOM]);

    frustum.planes[BACK] = Vector4(planes.m3 - planes.m2, planes.m7 - planes.m6, planes.m11 - planes.m10, planes.m15 -
            planes.m14);
    normalizePlane(&frustum.planes[BACK]);

    frustum.planes[FRONT] = Vector4(planes.m3 + planes.m2, planes.m7 + planes.m6, planes.m11 + planes.m10, planes.m15 +
            planes.m14);
    normalizePlane(&frustum.planes[FRONT]);
}

float distanceToPlaneV(const Vector4* plane, const Vector3* position) {
    return (plane.x * position.x + plane.y * position.y + plane.z * position.z + plane.w);
}

float distanceToPlane(const Vector4* plane, float x, float y, float z) {
    return (plane.x * x + plane.y * y + plane.z * z + plane.w);
}

bool pointInFrustumV(Frustum* frustum, Vector3 position) {
    if (frustum is null)
        return false;

    for (int i = 0; i < 6; i++) {
        // Point is behind plane.
        if (distanceToPlaneV(&frustum.planes[i], &position) <= 0)
            return false;
    }

    return true;
}

bool pointInFrustum(Frustum* frustum, float x, float y, float z) {
    if (frustum is null)
        return false;

    for (int i = 0; i < 6; i++) {
        // Point is behind plane.
        if (distanceToPlane(&frustum.planes[i], x, y, z) <= 0)
            return false;
    }

    return true;
}

bool sphereInFrustumV(Frustum* frustum, Vector3 position, float radius) {
    if (frustum is null)
        return false;

    for (int i = 0; i < 6; i++) {
        // Center is behind plane by more than the radius.
        if (distanceToPlaneV(&frustum.planes[i], &position) < -radius)
            return false;
    }

    return true;
}

bool aabBoxInFrustum(Frustum* frustum, Vector3 min, Vector3 max) {
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
    for (int i = 0; i < 6; i++) {
        bool oneInside = false;

        if (distanceToPlane(&frustum.planes[i], min.x, min.y, min.z) >= 0)
            oneInside = true;

        if (distanceToPlane(&frustum.planes[i], max.x, min.y, min.z) >= 0)
            oneInside = true;

        if (distanceToPlane(&frustum.planes[i], max.x, max.y, min.z) >= 0)
            oneInside = true;

        if (distanceToPlane(&frustum.planes[i], min.x, max.y, min.z) >= 0)
            oneInside = true;

        if (distanceToPlane(&frustum.planes[i], min.x, min.y, max.z) >= 0)
            oneInside = true;

        if (distanceToPlane(&frustum.planes[i], max.x, min.y, max.z) >= 0)
            oneInside = true;

        if (distanceToPlane(&frustum.planes[i], max.x, max.y, max.z) >= 0)
            oneInside = true;

        if (distanceToPlane(&frustum.planes[i], min.x, max.y, max.z) >= 0)
            oneInside = true;

        if (!oneInside)
            return false;
    }

    // The box extends outside the frustum but crosses it.
    return true;
}
