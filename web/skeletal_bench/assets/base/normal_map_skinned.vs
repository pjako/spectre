//---------------------------------------------------------------------
// Vertex attributes
//---------------------------------------------------------------------

/// The vertex position.
attribute vec3 vPosition;
/// The texture coordinate.
attribute vec2 vTexCoord0;
/// The vertex normal.
attribute vec3 vNormal;

attribute float4 vBoneIndices;
attribute float4 vBoneWeights;

//---------------------------------------------------------------------
// Uniform variables
//---------------------------------------------------------------------

/// The Model-View matrix.
uniform mat4 uModelViewMatrix;
/// The Model-View-Projection matrix.
uniform mat4 uModelViewProjectionMatrix;
/// The normal matrix
uniform mat4 uNormalMatrix;
uniform mat4 uModelMatrix;

uniform mat4 uBoneMatrices[64];

//---------------------------------------------------------------------
// Varying variables
//
// Allows communication between vertex and fragment stages
//---------------------------------------------------------------------

/// The postition of the vertex.
varying vec3 position;
/// The texture coordinate of the vertex.
varying vec2 texCoord;
/// The normal of the model.
varying vec3 normal;

void main()
{
  mat4 skinMat = accumulateSkinMatrix();
  vec4 vPosition4 = skinMat * vec4(vPosition, 1.0);
  
  position = vec3(uModelMatrix * vPosition4);
  texCoord = vTexCoord0;
  normal = normalize(mat3(uNormalMatrix) * vNormal);
  
  gl_Position = uModelViewProjectionMatrix * vPosition4;
}

mat4 accumulateSkinMatrix() {
   mat4 result = vBoneWeights.x * uBoneMatrices[int(vBoneIndices.x)];
   result = result + vBoneWeights.y * uBoneMatrices[int(vBoneIndices.y)];
   result = result + vBoneWeights.z * uBoneMatrices[int(vBoneIndices.z)];
   result = result + vBoneWeights.w * uBoneMatrices[int(vBoneIndices.w)];
   return result;
}
