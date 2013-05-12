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

/// The position of the light.
vec3 lightPosition = vec3(-1.0, -1.0, -1.0);
/// The intensity of the light.
vec3 lightIntensity = vec3(0.7, 0.7, 0.7);
/// The intensity of the light.
vec3 bounceIntensity = vec3(0.4, 0.4, 0.4);

/// The ambient color.
vec3 ka = vec3(0.2, 0.2, 0.2);

float shininess = 16.0;

vec3 lightDirection = normalize(vec3(0.25, 1.0, 0.0));
vec3 floorDirection = normalize(vec3(0.25, -1.0, 0.0));
float lightRadius = 100.0;

/// Computes the lighting.
vec4 ads()
{
  // Get the 2D distance from the center
  float lightDist = distance(position.xz, vec2(0,0));
  
  // Light attenuation
  float d = max(lightDist - lightRadius, 0.0) / lightRadius + 1.0;
  float distAttn = 1.0 / (d * d);
  
  vec3 n = normalize(normal);
  vec3 s = normalize(lightDirection);
  vec3 v = normalize(-position);
  vec3 r = reflect(-s, n);

  vec4 kd4 = texture2D(uDiffuse, texCoord);
  vec3 kd = kd4.rgb;
  vec3 ks = texture2D(uSpecular, texCoord).rgb;
	
  vec3 result = distAttn * lightIntensity * kd * max(dot(lightDirection, n), 0.0);

  // Fake a light bounce from the floor
  result += distAttn * bounceIntensity * kd * max(dot(floorDirection, n), 0.0);
	
  /*vec3 result = distAttn * lightIntensity *
    (ka +
     kd * max(dot(s, n), 0.0) +
     ks * pow(max(dot(r, v), 0.0), shininess));*/

  return vec4(result, kd4.a);
}

void main()
{
  gl_FragColor = ads();
}
