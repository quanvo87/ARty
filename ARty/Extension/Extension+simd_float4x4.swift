import SceneKit

extension simd_float4x4 {
    static func rotationAroundY(radians: Float) -> simd_float4x4 {
        var matrix = matrix_identity_float4x4

        matrix.columns.0.x = cos(radians)
        matrix.columns.0.z = -sin(radians)

        matrix.columns.2.x = sin(radians)
        matrix.columns.2.z = cos(radians)

        return matrix
    }

    static func translationMatrix(translation: simd_float4) -> simd_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix.columns.3 = translation
        return matrix
    }
}
