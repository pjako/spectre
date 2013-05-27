import 'dart:html';
import 'dart:math';
import 'dart:typed_data';
import 'package:vector_math/vector_math.dart';
import 'package:game_loop/game_loop_html.dart';
import 'package:asset_pack/asset_pack.dart';
import 'package:spectre/spectre.dart';
import 'package:spectre/spectre_asset_pack.dart';
import 'package:spectre/spectre_renderer.dart';

final String _canvasId = '#frontBuffer';

// TODO:
// Fix renderable interface.
//   Implement FullscreenRenderable
// Fix material texture handling
// Material is just set of constants and textures
// Shader consumes it:
//     Shader material
//     Layer material
//     Renderable material
// Add Material->apply(). Possible for a material to override it.
// Add layer list importer and material importer.
// Only update material camera transform, time uniforms once.

GraphicsDevice graphicsDevice;
GraphicsContext graphicsContext;
DebugDrawManager debugDrawManager;
GameLoopHtml gameLoop;
AssetManager assetManager;
Renderer renderer;
final List<Layer> layers = new List<Layer>();
final List<Renderable> renderables = new List<Renderable>();

final Camera camera = new Camera();
final cameraController = new FpsFlyCameraController();
double _lastTime;
bool _circleDrawn = false;

Map renderer_config = {
 'buffers': [
 {
 'name': 'depthBuffer',
 'type': 'depth',
 'width': 640,
 'height': 480
 },
 {
'name': 'colorBuffer',
 'type': 'color',
 'width': 640,
 'height': 480
 }
 ],
 'targets': [
 {
 'name': 'frontBuffer',
 'width': 640,
 'height': 480,
 },
 {
 'name': 'backBuffer',
 'depthBuffer': 'depthBuffer',
 'colorBuffer': 'colorBuffer',
 }
 ]
};

void gameFrame(GameLoopHtml gameLoop) {
  double dt = gameLoop.dt;
  cameraController.forwardVelocity = 25.0;
  cameraController.strafeVelocity = 25.0;
  cameraController.forward =
      gameLoop.keyboard.buttons[Keyboard.W].down;
  cameraController.backward =
      gameLoop.keyboard.buttons[Keyboard.S].down;
  cameraController.strafeLeft =
      gameLoop.keyboard.buttons[Keyboard.A].down;
  cameraController.strafeRight =
      gameLoop.keyboard.buttons[Keyboard.D].down;
  if (gameLoop.pointerLock.locked) {
    cameraController.accumDX = gameLoop.mouse.dx;
    cameraController.accumDY = gameLoop.mouse.dy;
  }
  cameraController.updateCamera(gameLoop.dt, camera);
  // Update the debug draw manager state
  debugDrawManager.update(dt);
}

void renderFrame(GameLoop gameLoop) {
  renderer.time = gameLoop.gameTime;
  renderer.render(layers, renderables, camera);

  // Add three lines, one for each axis.
  debugDrawManager.addLine(new Vector3(0.0, 0.0, 0.0),
                           new Vector3(10.0, 0.0, 0.0),
                           new Vector4(1.0, 0.0, 0.0, 1.0));
  debugDrawManager.addLine(new Vector3(0.0, 0.0, 0.0),
                           new Vector3(0.0, 10.0, 0.0),
                           new Vector4(0.0, 1.0, 0.0, 1.0));
  debugDrawManager.addLine(new Vector3(0.0, 0.0, 0.0),
                           new Vector3(0.0, 0.0, 10.0),
                           new Vector4(0.0, 0.0, 1.0, 1.0));
  debugDrawManager.addSphere(new Vector3(20.0, 20.0, 20.0), 20.0,
                             new Vector4(0.0, 1.0, 0.0, 1.0));
  if (_circleDrawn == false) {
    _circleDrawn = true;
    // Draw a circle that lasts for 5 seconds.
    debugDrawManager.addCircle(new Vector3(0.0, 0.0, 0.0),
                               new Vector3(0.0, 1.0, 0.0),
                               2.0,
                               new Vector4(1.0, 1.0, 1.0, 1.0),
                               duration:5.0);
  }
  // Prepare the debug draw manager for rendering
  debugDrawManager.prepareForRender();
}

// Handle resizes
void resizeFrame(GameLoopHtml gameLoop) {
  CanvasElement canvas = gameLoop.element;
  // Set the canvas width and height to match the dom elements
  canvas.width = canvas.client.width;
  canvas.height = canvas.client.height;
  // Fix the camera's aspect ratio
  camera.aspectRatio = canvas.width.toDouble()/canvas.height.toDouble();
}

SingleArrayIndexedMesh _skyboxMesh;
ShaderProgram _skyboxShaderProgram;
InputLayout _skyboxInputLayout;
SamplerState _skyboxSampler;
DepthState _skyboxDepthState;
BlendState _skyboxBlendState;
RasterizerState _skyboxRasterizerState;

void _setupSkybox() {
  MaterialShader materialShader = new MaterialShader('skyBox', renderer);
  materialShader.vertexShader = assetManager['demoAssets.skyBoxVertexShader'];
  materialShader.fragmentShader =
      assetManager['demoAssets.skyBoxFragmentShader'];
  materialShader.rasterizerState.cullMode = CullMode.None;
  materialShader.blendState.enabled = false;
  var asset = assetManager['demoAssets'].registerAsset('skyBoxShader',
                                                       'MaterialShader', '', {},
                                                       {});
  asset.imported = materialShader;
  Renderable renderable = new Renderable('Skybox', renderer,
                                         'demoAssets.skyBox');
  renderable.T.setIdentity();
  renderable.material = new Material('Skybox', materialShader, renderer);
  renderable.material.textures['skyMap'].texturePath = 'demoAssets.space';
  renderable.material.addConstant('cameraTransform', 'mat4');
  renderables.add(renderable);
}

void _buildCubes() {
  renderables.length = 100;
  for (int i = 0; i < 100; i++) {
    Renderable renderable = new Renderable('box $i', renderer,
                                           'demoAssets.unitCube');
    renderable.T.setIdentity();
    renderable.T.translate(i.toDouble() * 2.0, 0.0, 0.0);
    MaterialShader shader = assetManager['demoAssets.simpleTextureShader'];
    renderable.material = new Material('Cube $i', shader, renderer);
    renderables[i] = renderable;
  }
}

void _makeMaterial() {
  MaterialShader materialShader = new MaterialShader('simpleTexture', renderer);
  materialShader.vertexShader = '''
precision highp float;

attribute vec3 POSITION;
attribute vec3 NORMAL;
attribute vec2 TEXCOORD0;

uniform mat4 cameraProjectionView;
uniform mat4 normalTransform;
uniform mat4 objectTransform;

uniform vec3 lightDirection;

varying vec3 surfaceNormal;
varying vec2 samplePoint;
varying vec3 lightDir;

void main() {
    // TexCoord
    samplePoint = TEXCOORD0;
    // Normal
    //mat4 LM = normalTransform*objectTransform;
    vec3 N = (objectTransform*vec4(NORMAL, 0.0)).xyz;
    N = normalize(N);
    N = (normalTransform*vec4(N, 0.0)).xyz;
    surfaceNormal = normalize(N);
    lightDir = (normalTransform*vec4(lightDirection, 0.0)).xyz;
    mat4 M = cameraProjectionView*objectTransform;
    vec4 vPosition4 = vec4(POSITION.x, POSITION.y, POSITION.z, 1.0);
    gl_Position = M*vPosition4;
}
''';
  materialShader.fragmentShader = '''
precision mediump float;

varying vec3 surfaceNormal;
varying vec2 samplePoint;

varying vec3 lightDir;

uniform sampler2D diffuse;

void main() {
  vec3 normal = normalize(surfaceNormal);
  vec3 light = normalize(lightDir);
  float NdotL = max(dot(normal, -light), 0.3);
  vec3 ambientColor = vec3(0.1, 0.1, 0.1);
  //Vector3 diffuseColor = vec3(1.0, 0.0, 0.0) * NdotL;
  vec3 diffuseColor = vec3(texture2D(diffuse, samplePoint)) * NdotL;
  vec3 finalColor = diffuseColor + ambientColor;
    //gl_FragColor = vec4(NdotL, NdotL, 1.0, 1.0);
    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
''';
  materialShader.depthState.depthBufferWriteEnabled = true;
  var asset = assetManager['demoAssets'].registerAsset('simpleTextureShader',
                                                       'MaterialShader', '', {},
                                                       {});
  asset.imported = materialShader;
}

main() {
  CanvasElement canvas = query(_canvasId);
  assert(canvas != null);

  // Create a GraphicsDevice
  graphicsDevice = new GraphicsDevice(canvas);
  // Get a reference to the GraphicsContext
  graphicsContext = graphicsDevice.context;
  // Create a debug draw manager and initialize it
  debugDrawManager = new DebugDrawManager(graphicsDevice);

  // Set the canvas width and height to match the dom elements
  canvas.width = canvas.client.width;
  canvas.height = canvas.client.height;

  assetManager = new AssetManager();
  registerSpectreWithAssetManager(graphicsDevice, assetManager);
  renderer = new Renderer(canvas, graphicsDevice, assetManager);
  renderer.fromJson(renderer_config);
  gameLoop = new GameLoopHtml(canvas);
  gameLoop.onUpdate = gameFrame;
  gameLoop.onRender = renderFrame;
  gameLoop.onResize = resizeFrame;
  assetManager.loadPack('demoAssets', 'assets/_.pack').then((assetPack) {
    // Setup camera.
    camera.aspectRatio = canvas.width.toDouble()/canvas.height.toDouble();
    camera.position = new Vector3(2.0, 2.0, 2.0);
    camera.focusPosition = new Vector3(1.0, 1.0, 1.0);
    _makeMaterial();
    _buildCubes();
    _setupSkybox();
    // Setup layers.
    var clearBackBuffer = new FullscreenLayer('clear');
    clearBackBuffer.clearColorTarget = true;
    clearBackBuffer.clearDepthTarget = true;
    clearBackBuffer.renderTarget = 'backBuffer';
    layers.add(clearBackBuffer);
    var colorBackBuffer = new SceneLayer('color');
    colorBackBuffer.renderTarget = 'backBuffer';
    layers.add(colorBackBuffer);
    var debugLayer = new DebugDrawLayer('debug', debugDrawManager);
    debugLayer.renderTarget = 'backBuffer';
    layers.add(debugLayer);
    var blitBackBuffer = new FullscreenLayer('blit');
    blitBackBuffer.renderTarget = 'frontBuffer';
    blitBackBuffer.material = assetManager['fullscreenEffects.blit'];
    blitBackBuffer.material.textures['source'].texturePath =
        'renderer.colorBuffer';
    blitBackBuffer.material.textures['source'].sampler = renderer.NPOTSampler;
    layers.add(blitBackBuffer);
    gameLoop.start();
  });
}
