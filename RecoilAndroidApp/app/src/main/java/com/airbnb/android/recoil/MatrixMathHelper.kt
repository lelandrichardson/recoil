package com.airbnb.android.recoil

typealias Matrix = DoubleArray

/**
 * Provides helper methods for converting transform operations into a matrix and then into a list
 * of translate, scale and rotate commands.
 */
object MatrixMathHelper {

  private val EPSILON = .00001

  class MatrixDecompositionContext {
    internal var perspective = DoubleArray(4)
    internal var quaternion = DoubleArray(4)
    internal var scale = DoubleArray(3)
    internal var skew = DoubleArray(3)
    internal var translation = DoubleArray(3)
    internal var rotationDegrees = DoubleArray(3)
  }

  private fun isZero(d: Double): Boolean {
    return if (java.lang.Double.isNaN(d)) {
      false
    } else Math.abs(d) < EPSILON
  }

  fun multiplyInto(out: Matrix, a: Matrix, b: Matrix) {
    val a00 = a[0]
    val a01 = a[1]
    val a02 = a[2]
    val a03 = a[3]
    val a10 = a[4]
    val a11 = a[5]
    val a12 = a[6]
    val a13 = a[7]
    val a20 = a[8]
    val a21 = a[9]
    val a22 = a[10]
    val a23 = a[11]
    val a30 = a[12]
    val a31 = a[13]
    val a32 = a[14]
    val a33 = a[15]

    var b0 = b[0]
    var b1 = b[1]
    var b2 = b[2]
    var b3 = b[3]
    out[0] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30
    out[1] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31
    out[2] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32
    out[3] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33

    b0 = b[4]
    b1 = b[5]
    b2 = b[6]
    b3 = b[7]
    out[4] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30
    out[5] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31
    out[6] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32
    out[7] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33

    b0 = b[8]
    b1 = b[9]
    b2 = b[10]
    b3 = b[11]
    out[8] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30
    out[9] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31
    out[10] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32
    out[11] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33

    b0 = b[12]
    b1 = b[13]
    b2 = b[14]
    b3 = b[15]
    out[12] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30
    out[13] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31
    out[14] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32
    out[15] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33
  }

  /**
   * @param transformMatrix 16-element array of numbers representing 4x4 transform matrix
   */
  fun decomposeMatrix(transformMatrix: Matrix, ctx: MatrixDecompositionContext) {
    // output values
    val perspective = ctx.perspective
    val quaternion = ctx.quaternion
    val scale = ctx.scale
    val skew = ctx.skew
    val translation = ctx.translation
    val rotationDegrees = ctx.rotationDegrees

    // create normalized, 2d array matrix
    // and normalized 1d array perspectiveMatrix with redefined 4th column
    if (isZero(transformMatrix[15])) {
      return
    }
    val matrix = Array(4) { DoubleArray(4) }
    val perspectiveMatrix = Matrix(16)
    for (i in 0..3) {
      for (j in 0..3) {
        val value = transformMatrix[i * 4 + j] / transformMatrix[15]
        matrix[i][j] = value
        perspectiveMatrix[i * 4 + j] = if (j == 3) 0.0 else value
      }
    }
    perspectiveMatrix[15] = 1.0

    // test for singularity of upper 3x3 part of the perspective matrix
    if (isZero(determinant(perspectiveMatrix))) {
      return
    }

    // isolate perspective
    if (!isZero(matrix[0][3]) || !isZero(matrix[1][3]) || !isZero(matrix[2][3])) {
      // rightHandSide is the right hand side of the equation.
      // rightHandSide is a vector, or point in 3d space relative to the origin.
      val rightHandSide = doubleArrayOf(matrix[0][3], matrix[1][3], matrix[2][3], matrix[3][3])

      // Solve the equation by inverting perspectiveMatrix and multiplying
      // rightHandSide by the inverse.
      val inversePerspectiveMatrix = inverse(
          perspectiveMatrix
      )
      val transposedInversePerspectiveMatrix = transpose(
          inversePerspectiveMatrix
      )
      multiplyVectorByMatrix(rightHandSide, transposedInversePerspectiveMatrix, perspective)
    } else {
      // no perspective
      perspective[2] = 0.0
      perspective[1] = perspective[2]
      perspective[0] = perspective[1]
      perspective[3] = 1.0
    }

    // translation is simple
    for (i in 0..2) {
      translation[i] = matrix[3][i]
    }

    // Now get scale and shear.
    // 'row' is a 3 element array of 3 component vectors
    val row = Array(3) { DoubleArray(3) }
    for (i in 0..2) {
      row[i][0] = matrix[i][0]
      row[i][1] = matrix[i][1]
      row[i][2] = matrix[i][2]
    }

    // Compute X scale factor and normalize first row.
    scale[0] = v3Length(row[0])
    row[0] = v3Normalize(row[0], scale[0])

    // Compute XY shear factor and make 2nd row orthogonal to 1st.
    skew[0] = v3Dot(row[0], row[1])
    row[1] = v3Combine(row[1], row[0], 1.0, -skew[0])

    // Compute XY shear factor and make 2nd row orthogonal to 1st.
    skew[0] = v3Dot(row[0], row[1])
    row[1] = v3Combine(row[1], row[0], 1.0, -skew[0])

    // Now, compute Y scale and normalize 2nd row.
    scale[1] = v3Length(row[1])
    row[1] = v3Normalize(row[1], scale[1])
    skew[0] /= scale[1]

    // Compute XZ and YZ shears, orthogonalize 3rd row
    skew[1] = v3Dot(row[0], row[2])
    row[2] = v3Combine(row[2], row[0], 1.0, -skew[1])
    skew[2] = v3Dot(row[1], row[2])
    row[2] = v3Combine(row[2], row[1], 1.0, -skew[2])

    // Next, get Z scale and normalize 3rd row.
    scale[2] = v3Length(row[2])
    row[2] = v3Normalize(row[2], scale[2])
    skew[1] /= scale[2]
    skew[2] /= scale[2]

    // At this point, the matrix (in rows) is orthonormal.
    // Check for a coordinate system flip.  If the determinant
    // is -1, then negate the matrix and the scaling factors.
    val pdum3 = v3Cross(row[1], row[2])
    if (v3Dot(row[0], pdum3) < 0) {
      for (i in 0..2) {
        scale[i] *= -1.0
        row[i][0] *= -1.0
        row[i][1] *= -1.0
        row[i][2] *= -1.0
      }
    }

    // Now, get the rotations out
    quaternion[0] = 0.5 * Math.sqrt(Math.max(1 + row[0][0] - row[1][1] - row[2][2], 0.0))
    quaternion[1] = 0.5 * Math.sqrt(Math.max(1 - row[0][0] + row[1][1] - row[2][2], 0.0))
    quaternion[2] = 0.5 * Math.sqrt(Math.max(1.0 - row[0][0] - row[1][1] + row[2][2], 0.0))
    quaternion[3] = 0.5 * Math.sqrt(Math.max(1.0 + row[0][0] + row[1][1] + row[2][2], 0.0))

    if (row[2][1] > row[1][2]) {
      quaternion[0] = -quaternion[0]
    }
    if (row[0][2] > row[2][0]) {
      quaternion[1] = -quaternion[1]
    }
    if (row[1][0] > row[0][1]) {
      quaternion[2] = -quaternion[2]
    }

    // correct for occasional, weird Euler synonyms for 2d rotation

    if (quaternion[0] < 0.001 && quaternion[0] >= 0 &&
        quaternion[1] < 0.001 && quaternion[1] >= 0) {
      // this is a 2d rotation on the z-axis
      rotationDegrees[1] = 0.0
      rotationDegrees[0] = rotationDegrees[1]
      rotationDegrees[2] = roundTo3Places(Math.atan2(row[0][1], row[0][0]) * 180 / Math.PI)
    } else {
      quaternionToDegreesXYZ(quaternion, rotationDegrees)
    }
  }

  fun determinant(matrix: Matrix): Double {
    val m00 = matrix[0]
    val m01 = matrix[1]
    val m02 = matrix[2]
    val m03 = matrix[3]
    val m10 = matrix[4]
    val m11 = matrix[5]
    val m12 = matrix[6]
    val m13 = matrix[7]
    val m20 = matrix[8]
    val m21 = matrix[9]
    val m22 = matrix[10]
    val m23 = matrix[11]
    val m30 = matrix[12]
    val m31 = matrix[13]
    val m32 = matrix[14]
    val m33 = matrix[15]
    return m03 * m12 * m21 * m30 - m02 * m13 * m21 * m30 -
        m03 * m11 * m22 * m30 + m01 * m13 * m22 * m30 +
        m02 * m11 * m23 * m30 - m01 * m12 * m23 * m30 -
        m03 * m12 * m20 * m31 + m02 * m13 * m20 * m31 +
        m03 * m10 * m22 * m31 - m00 * m13 * m22 * m31 -
        m02 * m10 * m23 * m31 + m00 * m12 * m23 * m31 +
        m03 * m11 * m20 * m32 - m01 * m13 * m20 * m32 -
        m03 * m10 * m21 * m32 + m00 * m13 * m21 * m32 +
        m01 * m10 * m23 * m32 - m00 * m11 * m23 * m32 -
        m02 * m11 * m20 * m33 + m01 * m12 * m20 * m33 +
        m02 * m10 * m21 * m33 - m00 * m12 * m21 * m33 -
        m01 * m10 * m22 * m33 + m00 * m11 * m22 * m33
  }

  /**
   * Inverse of a matrix. Multiplying by the inverse is used in matrix math
   * instead of division.
   *
   * Formula from:
   * http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm
   */
  fun inverse(matrix: Matrix): Matrix {
    val det = determinant(matrix)
    if (isZero(det)) {
      return matrix
    }
    val m00 = matrix[0]
    val m01 = matrix[1]
    val m02 = matrix[2]
    val m03 = matrix[3]
    val m10 = matrix[4]
    val m11 = matrix[5]
    val m12 = matrix[6]
    val m13 = matrix[7]
    val m20 = matrix[8]
    val m21 = matrix[9]
    val m22 = matrix[10]
    val m23 = matrix[11]
    val m30 = matrix[12]
    val m31 = matrix[13]
    val m32 = matrix[14]
    val m33 = matrix[15]
    return doubleArrayOf((m12 * m23 * m31 - m13 * m22 * m31 + m13 * m21 * m32 - m11 * m23 * m32 - m12 * m21 * m33 + m11 * m22 * m33) / det, (m03 * m22 * m31 - m02 * m23 * m31 - m03 * m21 * m32 + m01 * m23 * m32 + m02 * m21 * m33 - m01 * m22 * m33) / det, (m02 * m13 * m31 - m03 * m12 * m31 + m03 * m11 * m32 - m01 * m13 * m32 - m02 * m11 * m33 + m01 * m12 * m33) / det, (m03 * m12 * m21 - m02 * m13 * m21 - m03 * m11 * m22 + m01 * m13 * m22 + m02 * m11 * m23 - m01 * m12 * m23) / det, (m13 * m22 * m30 - m12 * m23 * m30 - m13 * m20 * m32 + m10 * m23 * m32 + m12 * m20 * m33 - m10 * m22 * m33) / det, (m02 * m23 * m30 - m03 * m22 * m30 + m03 * m20 * m32 - m00 * m23 * m32 - m02 * m20 * m33 + m00 * m22 * m33) / det, (m03 * m12 * m30 - m02 * m13 * m30 - m03 * m10 * m32 + m00 * m13 * m32 + m02 * m10 * m33 - m00 * m12 * m33) / det, (m02 * m13 * m20 - m03 * m12 * m20 + m03 * m10 * m22 - m00 * m13 * m22 - m02 * m10 * m23 + m00 * m12 * m23) / det, (m11 * m23 * m30 - m13 * m21 * m30 + m13 * m20 * m31 - m10 * m23 * m31 - m11 * m20 * m33 + m10 * m21 * m33) / det, (m03 * m21 * m30 - m01 * m23 * m30 - m03 * m20 * m31 + m00 * m23 * m31 + m01 * m20 * m33 - m00 * m21 * m33) / det, (m01 * m13 * m30 - m03 * m11 * m30 + m03 * m10 * m31 - m00 * m13 * m31 - m01 * m10 * m33 + m00 * m11 * m33) / det, (m03 * m11 * m20 - m01 * m13 * m20 - m03 * m10 * m21 + m00 * m13 * m21 + m01 * m10 * m23 - m00 * m11 * m23) / det, (m12 * m21 * m30 - m11 * m22 * m30 - m12 * m20 * m31 + m10 * m22 * m31 + m11 * m20 * m32 - m10 * m21 * m32) / det, (m01 * m22 * m30 - m02 * m21 * m30 + m02 * m20 * m31 - m00 * m22 * m31 - m01 * m20 * m32 + m00 * m21 * m32) / det, (m02 * m11 * m30 - m01 * m12 * m30 - m02 * m10 * m31 + m00 * m12 * m31 + m01 * m10 * m32 - m00 * m11 * m32) / det, (m01 * m12 * m20 - m02 * m11 * m20 + m02 * m10 * m21 - m00 * m12 * m21 - m01 * m10 * m22 + m00 * m11 * m22) / det)
  }

  /**
   * Turns columns into rows and rows into columns.
   */
  fun transpose(m: Matrix): Matrix {
    return doubleArrayOf(m[0], m[4], m[8], m[12], m[1], m[5], m[9], m[13], m[2], m[6], m[10], m[14], m[3], m[7], m[11], m[15])
  }

  /**
   * Based on: http://tog.acm.org/resources/GraphicsGems/gemsii/unmatrix.c
   */
  fun multiplyVectorByMatrix(v: DoubleArray, m: Matrix, result: DoubleArray) {
    val vx = v[0]
    val vy = v[1]
    val vz = v[2]
    val vw = v[3]
    result[0] = vx * m[0] + vy * m[4] + vz * m[8] + vw * m[12]
    result[1] = vx * m[1] + vy * m[5] + vz * m[9] + vw * m[13]
    result[2] = vx * m[2] + vy * m[6] + vz * m[10] + vw * m[14]
    result[3] = vx * m[3] + vy * m[7] + vz * m[11] + vw * m[15]
  }

  /**
   * From: https://code.google.com/p/webgl-mjs/source/browse/mjs.js
   */
  fun v3Length(a: DoubleArray): Double {
    return Math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])
  }

  /**
   * Based on: https://code.google.com/p/webgl-mjs/source/browse/mjs.js
   */
  fun v3Normalize(vector: DoubleArray, norm: Double): DoubleArray {
    val im = 1 / if (isZero(norm)) v3Length(vector) else norm
    return doubleArrayOf(vector[0] * im, vector[1] * im, vector[2] * im)
  }

  /**
   * The dot product of a and b, two 3-element vectors.
   * From: https://code.google.com/p/webgl-mjs/source/browse/mjs.js
   */
  fun v3Dot(a: DoubleArray, b: DoubleArray): Double {
    return a[0] * b[0] +
        a[1] * b[1] +
        a[2] * b[2]
  }

  /**
   * From:
   * http://www.opensource.apple.com/source/WebCore/WebCore-514/platform/graphics/transforms/TransformationMatrix.cpp
   */
  fun v3Combine(a: DoubleArray, b: DoubleArray, aScale: Double, bScale: Double): DoubleArray {
    return doubleArrayOf(aScale * a[0] + bScale * b[0], aScale * a[1] + bScale * b[1], aScale * a[2] + bScale * b[2])
  }

  /**
   * From:
   * http://www.opensource.apple.com/source/WebCore/WebCore-514/platform/graphics/transforms/TransformationMatrix.cpp
   */
  fun v3Cross(a: DoubleArray, b: DoubleArray): DoubleArray {
    return doubleArrayOf(a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
  }

  /**
   * Based on:
   * http://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToEuler/
   * and:
   * http://quat.zachbennett.com/
   *
   * Note that this rounds degrees to the thousandth of a degree, due to
   * floating point errors in the creation of the quaternion.
   *
   * Also note that this expects the qw value to be last, not first.
   *
   * Also, when researching this, remember that:
   * yaw   === heading            === z-axis
   * pitch === elevation/attitude === y-axis
   * roll  === bank               === x-axis
   */
  fun quaternionToDegreesXYZ(q: DoubleArray, result: DoubleArray) {
    val qx = q[0]
    val qy = q[1]
    val qz = q[2]
    val qw = q[3]
    val qw2 = qw * qw
    val qx2 = qx * qx
    val qy2 = qy * qy
    val qz2 = qz * qz
    val test = qx * qy + qz * qw
    val unit = qw2 + qx2 + qy2 + qz2
    val conv = 180 / Math.PI

    if (test > 0.49999 * unit) {
      result[0] = 0.0
      result[1] = 2.0 * Math.atan2(qx, qw) * conv
      result[2] = 90.0
      return
    }
    if (test < -0.49999 * unit) {
      result[0] = 0.0
      result[1] = -2.0 * Math.atan2(qx, qw) * conv
      result[2] = -90.0
      return
    }

    result[0] = roundTo3Places(Math.atan2(2.0 * qx * qw - 2.0 * qy * qz, 1.0 - 2 * qx2 - 2 * qz2) * conv)
    result[1] = roundTo3Places(Math.atan2(2.0 * qy * qw - 2.0 * qx * qz, 1.0 - 2 * qy2 - 2 * qz2) * conv)
    result[2] = roundTo3Places(Math.asin(2.0 * qx * qy + 2.0 * qz * qw) * conv)
  }

  fun roundTo3Places(n: Double): Double {
    return Math.round(n * 1000.0) * 0.001
  }

  fun createIdentityMatrix(): Matrix {
    val res = DoubleArray(16)
    resetIdentityMatrix(res)
    return res
  }

  fun degreesToRadians(degrees: Double): Double {
    return degrees * Math.PI / 180
  }

  fun resetIdentityMatrix(matrix: Matrix) {
    matrix[14] = 0.0
    matrix[13] = matrix[14]
    matrix[12] = matrix[13]
    matrix[11] = matrix[12]
    matrix[9] = matrix[11]
    matrix[8] = matrix[9]
    matrix[7] = matrix[8]
    matrix[6] = matrix[7]
    matrix[4] = matrix[6]
    matrix[3] = matrix[4]
    matrix[2] = matrix[3]
    matrix[1] = matrix[2]
    matrix[15] = 1.0
    matrix[10] = matrix[15]
    matrix[5] = matrix[10]
    matrix[0] = matrix[5]
  }

  fun applyPerspective(m: Matrix, perspective: Double): Matrix {
    m[11] = -1 / perspective
    return m
  }

  fun applyScaleX(m: Matrix, factor: Double) {
    m[0] = factor
  }

  fun applyScaleY(m: Matrix, factor: Double) {
    m[5] = factor
  }

  fun applyScaleZ(m: Matrix, factor: Double) {
    m[10] = factor
  }

  fun applyTranslate2D(m: Matrix, x: Double, y: Double) {
    m[12] = x
    m[13] = y
  }

  fun applyTranslate3D(m: Matrix, x: Double, y: Double, z: Double) {
    m[12] = x
    m[13] = y
    m[14] = z
  }

  fun applySkewX(m: Matrix, radians: Double) {
    m[4] = Math.tan(radians)
  }

  fun applySkewY(m: Matrix, radians: Double) {
    m[1] = Math.tan(radians)
  }

  fun applyRotateX(m: Matrix, radians: Double) {
    m[5] = Math.cos(radians)
    m[6] = Math.sin(radians)
    m[9] = -Math.sin(radians)
    m[10] = Math.cos(radians)
  }

  fun applyRotateY(m: Matrix, radians: Double) {
    m[0] = Math.cos(radians)
    m[2] = -Math.sin(radians)
    m[8] = Math.sin(radians)
    m[10] = Math.cos(radians)
  }

  // http://www.w3.org/TR/css3-transforms/#recomposing-to-a-2d-matrix
  fun applyRotateZ(m: Matrix, radians: Double) {
    m[0] = Math.cos(radians)
    m[1] = Math.sin(radians)
    m[4] = -Math.sin(radians)
    m[5] = Math.cos(radians)
  }
}
