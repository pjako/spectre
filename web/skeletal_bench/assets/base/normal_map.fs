precision mediump float;

//---------------------------------------------------------------------
// Uniform variables
//---------------------------------------------------------------------

/// The diffuse sampler.
uniform sampler2D uDiffuse;
/// The normal sampler.
uniform sampler2D uNormal;
/// The specular sampler.
uniform sampler2D uSpecular;

//---------------------------------------------------------------------
// Varying variables
//
// Allows communication between vertex and fragment stages
//---------------------------------------------------------------------

/// The postition of the vertex.
varying vec3 position;
/// The texture coodinate of the vertex.
varying vec2 texCoord;
/// The normal of the model.
varying vec3 normal;

//---------------------------------------------------------------------
// Constants
//---------------------------------------------------------------------

/// The intensity of the light.
vec3 lightColor = vec3(0.7, 0.7, 0.7);
/// The intensity of the light.
vec3 bounceColor = vec3(0.4, 0.4, 0.4);

/// The ambient color.
vec3 ka = vec3(0.2, 0.2, 0.2);

float shininess = 16.0;

vec3 lightDirection = normalize(vec3(0.25, 1.0, 0.0));
vec3 floorDirection = normalize(vec3(0.25, -1.0, 0.0));

/// Computes the lighting.
vec4 ads()
{  
  vec3 n = normalize(normal);
  vec4 kd4 = texture2D(uDiffuse, texCoord);
  vec3 kd = kd4.rgb;
	
  vec3 result = lightColor * kd * max(dot(lightDirection, n), 0.0);

  // Fake a light bounce from the floor
  result += bounceColor * kd * max(dot(floorDirection, n), 0.0);

  return vec4(result, kd4.a);
}

void main()
{
  gl_FragColor = ads();
}
