/*
  Copyright (C) 2013 John McCutchan

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

library skeletal_bench;

//---------------------------------------------------------------------
// Imports
//---------------------------------------------------------------------

import 'dart:html';
import 'dart:math' as Math;
import 'dart:async';
import 'dart:typed_data';
import 'package:vector_math/vector_math.dart';
import 'package:game_loop/game_loop_html.dart';
import 'package:asset_pack/asset_pack.dart';
import 'package:spectre/spectre.dart';
import 'package:spectre/spectre_asset_pack.dart';

//---------------------------------------------------------------------
// Library sources
//---------------------------------------------------------------------

part 'ui.dart';
part 'easing.dart';

//---------------------------------------------------------------------
// Application
//---------------------------------------------------------------------

typedef AdjustInstances(int count, bool reset);

class InstanceCountController {
  final Stopwatch autoAdjustWatch = new Stopwatch()..start();
  final AdjustInstances setInstances;
  final List<int> history = new List<int>(4);
  final List<int> instanceHistory = new List<int>(4);
  int cursor = 0;
  int lastMs = 0;
  const int targetMicrosMin = 19000;
  const int targetMicrosMax = 23000;
  int instanceCount;
  double continuousInstanceCount;
  InstanceCountController(this.setInstances, this.instanceCount) {
    continuousInstanceCount = instanceCount.toDouble();
    for (int i = 0; i < history.length; i++) {
      history[i] = targetMicrosMin;
      instanceHistory[i] = instanceCount;
    }
  }

  int get previousCursor => (cursor-1) % history.length;
  int get nextCursor => (cursor+1) % history.length;

  int get minDelta => history.reduce(Math.min);
  int get maxDelta => history.reduce(Math.max);

  void reset(int count) {
    instanceCount = count;
    continuousInstanceCount = count.toDouble();
    for (int i = 0; i < history.length; i++) {
      history[i] = targetMicrosMin;
      instanceHistory[i] = instanceCount;
    }
    cursor = 0;
    lastMs = 0;
    setInstances(instanceCount, true);
  }

  void recordSample() {
    int ms = autoAdjustWatch.elapsedMicroseconds;
    if (lastMs == 0) {
      // First frame.
      lastMs = ms;
      return;
    }
    int delta = ms - lastMs;
    lastMs = ms;
    history[cursor] = delta;
    instanceHistory[cursor] = instanceCount;
    if (maxDelta < targetMicrosMin) {
      continuousInstanceCount++;
    } else if (minDelta > targetMicrosMax) {
      continuousInstanceCount--;
    }
    if (continuousInstanceCount < 1.0) {
      continuousInstanceCount = 1.0;
    }
    int nextInstanceCount = continuousInstanceCount.floor();
    instanceCount = nextInstanceCount;
    setInstances(nextInstanceCount, false);
    cursor = nextCursor;
  }
}

class SampleMeshInstance extends SkinnedMeshInstance {
  int id;
  double scale = 0.0;

  double startScale = 0.0;
  double targetScale = 1.0;

  double scaleDuration = 0.5;
  double scaleTime = 0.0;

  SampleMeshInstance(SkinnedMesh mesh, this.id) : super(mesh);

  bool _visibleFlagged = true;
  bool get visible => scale > 0.001;
  set visible(bool value) {
    if(_visibleFlagged == value)
      return;

    _visibleFlagged = value;
    startScale = scale;
    targetScale = value ? 1.0 : 0.0;
    scaleTime = 0.0;
  }

  bool update(double dt, bool useSimd) {
    if(scaleTime < scaleDuration) {
      scaleTime += dt;
      EasingFunction f = _visibleFlagged ? Ease.OutElastic : Ease.InQuad;
      scale = EaseTo(scaleTime, scaleDuration, startScale, targetScale, f);
    }

    if(_visibleFlagged)
      return super.update(dt, useSimd);

    return false;
  }

  const num TAU = Math.PI * 2;
  final num PHI = (Math.sqrt(5) + 1) / 2;
  const int SCALE_FACTOR = 25;

  void getMatrix(Float32List out) {
    final num theta = id * TAU / PHI;
    final num r = Math.sqrt(id) * SCALE_FACTOR;

    out[0] = 0.5 * scale;
    out[5] = 0.5 * scale;
    out[10] = 0.5 * scale;

    out[12] = r * Math.cos(theta);
    out[14] = -r * Math.sin(theta);
    out[13] = -10.0;
  }
}

/// The sample application.
class Application {

  //---------------------------------------------------------------------
  // Class variables
  //---------------------------------------------------------------------

  /// The red value to clear the color buffer to.
  static const double _redClearColor = 0.0;
  /// The green value to clear the color buffer to.
  static const double _greenClearColor = 0.0;
  /// The blue value to clear the color buffer to.
  static const double _blueClearColor = 0.0;
  /// The alpha value to clear the color buffer to.
  static const double _alphaClearColor = 1.0;

  //---------------------------------------------------------------------
  // Member variables
  //---------------------------------------------------------------------

  /// The [GraphicsDevice] used by the application.
  ///
  GraphicsDevice _graphicsDevice;
  /// The [GraphicsContext] used by the application.
  ///
  /// The [GraphicsContext] is used to render the scene. All the rendering
  /// commands pass through the context.
  GraphicsContext _graphicsContext;
  /// The [AssetManager] used by the application.
  ///
  /// The [AssetManager] is used to import resources into the
  /// the application. Typically assets are imported by loading in a .pack
  /// file which contains references to the locations of the assets. Once
  /// loaded they can be used by the application.
  AssetManager _assetManager;

  //---------------------------------------------------------------------
  // Debug drawing member variables
  //---------------------------------------------------------------------

  /// Retained mode debug draw manager.
  ///
  /// Used to draw debugging information to the screen. In this sample the
  /// skeleton of the mesh is drawn by the [DebugDrawManager].
  DebugDrawManager _debugDrawManager;
  /// Whether debugging information should be drawn.
  ///
  /// If the debugging information is turned on in this sample the
  /// mesh's skeleton will be displayed.
  bool _drawDebugInformation = true;

  //---------------------------------------------------------------------
  // Rendering state member variables
  //---------------------------------------------------------------------

  /// The [Viewport] to draw to.
  Viewport _viewport;
  /// The [BlendState] to use during rendering.
  ///
  /// Some of the meshes contained within the models have textures with
  /// alpha values. Alpha blending is disabled by default so a BlendState will
  /// need to be applied to the pipeline.
  BlendState _blendState;
  /// The [SamplerState] to use during rendering.
  ///
  /// All the texture coordinates on the models are in the range [0,1].
  /// Because of this a single SamplerState can be applied to all the
  /// Textures being used.
  SamplerState _samplerState;
  /// An array of [SamplerState]s to use during rendering.
  List<SamplerState> _samplers;

  //---------------------------------------------------------------------
  // Camera member variables
  //---------------------------------------------------------------------

  /// The [Camera] being used to view the scene.
  Camera _camera;
  /// The [FpsFlyCameraController] which allows the movement of the [Camera].
  ///
  /// A [FpsFlyCameraController] provides a way to move the camera in the
  /// same way that a free-look FPS operates.
  OrbitCameraController _cameraController;
  /// The Model-View-Projection matrix.
  Matrix4 _modelViewProjectionMatrix;
  /// [Float32List] storage for the Model-View matrix.
  Float32List _modelViewMatrixArray;
  /// [Float32List] stoarage for the Model-View-Projection matrix.
  Float32List _modelViewProjectionMatrixArray;

  //---------------------------------------------------------------------
  // Mesh drawing variables
  //---------------------------------------------------------------------

  /// The [ShaderProgram] to use to draw the mesh.
  ///
  /// The models all contain a normal and specular map. The [ShaderProgram] uses the
  /// normal map to add additional detail to the surface, and the specular map to
  /// provide a variable shininess, which is used in Phong lighting, across the mesh.
  ShaderProgram _simpleShaderProgram;
  ShaderProgram _skinnedShaderProgram;
  /// The [InputLayout] of the mesh.
  InputLayout _inputLayout;
  InputLayout _skinnedInputLayout;
  InputLayout _roomInputLayout;
  /// The [SkinnedMesh]es being used by the application.
  List<SkinnedMesh> _meshes;
  SingleArrayMesh _room;
  int _roomVertCount;
  List<Texture2D> _roomFloorTextures;
  List<Texture2D> _roomCeilingTextures;
  List<Texture2D> _roomWallTextures;
  /// The [SpectreTexture]s to use on the meshes.
  ///
  /// Each mesh and their respective submeshes have [SpectreTexture]s to be set within the
  /// pipeline. Each submesh has a diffuse map, a normal map, and a specular map.
  List<List<List<Texture2D>>> _textures;
  /// The index of the [SkinnedMesh] to draw.
  int _meshIndex = 0;
  CanvasElement canvas;

  //---------------------------------------------------------------------
  // Construction
  //---------------------------------------------------------------------

  final Float32List modelMatrix = new Float32List(16);
  InstanceCountController controller;
  /// Creates an instance of the [Application] class.
  ///
  /// The application is hosted within the [CanvasElement] specified in [canvas].
  Application(this.canvas) {
    // Resize the canvas using the offsetWidth/offsetHeight.
    //
    // The canvas width/height is not being explictly specified in the markup,
    // but the canvas needs to take up the entire contents of the window. The
    // stylesheet accomplishes this but the underlying canvas will default to
    // 300x150 which will produce a really low resolution image.
    int width = canvas.offset.width;
    int height = canvas.offset.height;

    canvas.width = width;
    canvas.height = height;

    // Create the GraphicsDevice and attaches the AssetManager
    _createGraphicsDevice(canvas);

    // Create the rendering state
    _createRendererState();

    // Create the Camera and the CameraController
    _createCamera();

    _debugDrawManager = new DebugDrawManager(_graphicsDevice);

    // Call the onResize method which will update the viewport and camera
    onResize(width, height);

    modelMatrix[0] = 1.0;
    modelMatrix[5] = 1.0;
    modelMatrix[10] = 1.0;
    modelMatrix[15] = 1.0;

    // Start loading the resources
    _loadResources();
  }

  /// Creates the [GraphicsDevice] and attaches the [AssetManager].
  void _createGraphicsDevice(CanvasElement canvas) {
    // Create the GraphicsDevice using the CanvasElement
    _graphicsDevice = new GraphicsDevice(canvas);

    // Get the GraphicsContext from the GraphicsDevice
    _graphicsContext = _graphicsDevice.context;

    // Create the AssetManager and register Spectre specific resource loading
    _assetManager = new AssetManager();
    registerSpectreWithAssetManager(_graphicsDevice, _assetManager);

    // Attach additional importer/loaders to the AssetManager
    //
    // The application uses config files to define behavior. These files
    // are just json data. So associate a TextLoader and a JsonImporter
    // to a 'config'
    _assetManager.loaders['config'] = new TextLoader();
    _assetManager.importers['config'] = new JsonImporter();
  }

  /// Creates the rendering state.
  void _createRendererState() {
    // Create the Viewport
    _viewport = new Viewport('Viewport', _graphicsDevice);

    // Create the BlendState
    //
    // Blending should be enabled since there are some meshes whose textures
    // have alpha values. If there is no alpha blending then it should be turned
    // off. Enabling blending when there is no alpha values to blend causes the
    // graphics hardware to do work that isn't required.
    _blendState = new BlendState.alphaBlend('BlendState', _graphicsDevice);

    // Create the SamplerState
    //
    // All the models have texture coordinates that are clamped to [0,1].
    // Because of this a single SamplerState can be applied to all the
    // Textures being used.
    //
    // The ShaderProgram being used takes three textures, so create a list
    // containing the same SamplerState at all three locations.
    _samplerState = new SamplerState.linearClamp('SamplerState', _graphicsDevice);
    _samplers = [_samplerState, _samplerState, _samplerState];

    // By default the rendering pipeline has the depth buffer enabled and
    // set to writeable. Because of this there is no reason to create and
    // explcitly apply a DepthState while rendering.

    // By default the rendering pipeline has back facing polygons being
    // culled. Because of this there is no reason to create and explicitly
    // apply a RasterizerState while rendering.
  }

  /// Create the [Camera] and the [CameraController] to position it.
  void _createCamera() {
    // Create the Camera
    _camera = new Camera();
    _camera.zFar = 2000.0;
    _camera.position = new Vector3(150.0, 60.0, 0.0);
    _camera.focusPosition = new Vector3(0.0, 40.0, 0.0);

    // Create the CameraController and set the velocity of the movement
    _cameraController = new OrbitCameraController();
    _cameraController.radius = 400.0;
    _cameraController.maxRadius = 1000.0;

    // Create the Matrix4 holding the Model-View-Projection matrix
    _modelViewProjectionMatrix = new Matrix4.zero();

    // Create the Float32Lists that store the constant values for the matrices
    _modelViewMatrixArray = new Float32List(16);
    _modelViewProjectionMatrixArray = new Float32List(16);
  }

  /// Load the resources held in the .pack files.
  void _loadResources() {
    // Load the base pack
    _assetManager.loadPack('base', 'assets/base/_.pack').then((assetPack) {
      // Get the ShaderProgram
      //
      // Any uniforms that are constant throughout running the program
      // should be set after the ShaderProgram is created. The ShaderProgram
      // retains the state so there isn't a need to set them each time the
      // program is run. In fact its a drain on performance if the constants
      // are set to the same value each run
      _simpleShaderProgram = assetPack['simpleShader'];
      _skinnedShaderProgram = assetPack['normalMapSkinnedShader'];

      _roomFloorTextures = [assetPack['floorDiffuse']];
      _roomCeilingTextures = [assetPack['ceilingDiffuse']];
      _roomWallTextures = [assetPack['wallDiffuse']];

      // Apply the shader program and set the locations of the textures
      _graphicsContext.setShaderProgram(_simpleShaderProgram);

      // Load the individual models
      //
      // The configuration specifies the models to load within the application.
      // Each model is contained within a pack file.
      List models = assetPack['config']['models'];
      int modelCount = models.length;

      List<Future> requests = new List<Future>(modelCount);

      for (int i = 0; i < modelCount; ++i) {
        Map modelRequest = models[i];

        // Load the individual pack files containing the models
        requests[i] = _assetManager.loadPack(modelRequest['name'], modelRequest['pack']);
      }

      // Wait on all requests to be loaded
      Future.wait(requests).then((_) {
        // Create the list that holds the SkinnedMeshes
        _meshes = new List<SkinnedMesh>(modelCount);
        // Create the list that holds the Textures
        _textures = new List<List<List<Texture2D>>>();

        // Get the indices of the samplers
        //
        // This specifies what unit to bind the textures to. This is decided during
        // compilation so just query the actual values.
        // TODO: This may not align properly for both shaders
        int diffuseIndex  = _simpleShaderProgram.samplers['uDiffuse'].textureUnit;
        //int specularIndex = _simpleShaderProgram.samplers['uSpecular'].textureUnit;

        for (int i = 0; i < modelCount; ++i) {
          // Get the matching AssetPack
          Map modelRequest = models[i];
          String modelName = modelRequest['name'];
          AssetPack modelPack = _assetManager.root[modelName];

          // Import the mesh
          _meshes[i] = importSkinnedMesh2('${modelName}_Mesh', _graphicsDevice, modelPack['mesh']);
          importAnimation(_meshes[i], modelPack['anim'][0]);

          // Get the textures to use on the mesh.
          //
          // The configuration file references the textures to use when drawing
          // each part of the mesh
          List<List<Texture2D>> modelTextures = new List<List<Texture2D>>();
          List modelTextureConfig = modelPack['config']['textures'];

          int meshCount = modelTextureConfig.length;

          for (int i = 0; i < meshCount; ++i) {
            Map meshConfig = modelTextureConfig[i];
            List<Texture2D> meshTextures = new List<Texture2D>(3);

            meshTextures[diffuseIndex]  = modelPack[meshConfig['diffuse']];
            //meshTextures[specularIndex] = modelPack[meshConfig['specular']];

            modelTextures.add(meshTextures);
          }

          _textures.add(modelTextures);
        }

        // Setup the vertex layout
        _inputLayout = new InputLayout('InputLayout', _graphicsDevice);
        _inputLayout.shaderProgram = _simpleShaderProgram;
        _inputLayout.mesh = _meshes[0];

        _skinnedInputLayout = new InputLayout('SkinnedInputLayout', _graphicsDevice);
        _skinnedInputLayout.shaderProgram = _skinnedShaderProgram;
        _skinnedInputLayout.mesh = _meshes[0];

        _createRoom();

        // This forces the instances list to initialize now that we have the mesh loaded.
        instanceCount = _instanceCount;

        // Start the loop and show the UI
        _gameLoop.start();
        controller = new InstanceCountController((count, reset) {
          instanceCount = count;
        }, instanceCount);
      });
    });
  }

  void _createRoom() {
    double size = 512.0;
    double height = 400.0;
    double uvScale = 1.0;
    Float32List verts = new Float32List.fromList([
      // Floor
      size, 0.0, size,    uvScale, uvScale,   0.0, 1.0, 0.0,
      size, 0.0, -size,   uvScale, 0.0,       0.0, 1.0, 0.0,
      -size, 0.0, size,   0.0, uvScale,       0.0, 1.0, 0.0,

      -size, 0.0, size,   0.0, uvScale,       0.0, 1.0, 0.0,
      size, 0.0, -size,   uvScale, 0.0,       0.0, 1.0, 0.0,
      -size, 0.0,-size,   0.0, 0.0,           0.0, 1.0, 0.0,

      // Ceiling
      size, height, size,    uvScale, uvScale,   0.0, 1.0, 0.0,
      -size, height, size,   0.0, uvScale,       0.0, 1.0, 0.0,
      size, height, -size,   uvScale, 0.0,       0.0, 1.0, 0.0,

      -size, height, size,   0.0, uvScale,       0.0, 1.0, 0.0,
      -size, height,-size,   0.0, 0.0,           0.0, 1.0, 0.0,
      size, height, -size,   uvScale, 0.0,       0.0, 1.0, 0.0,

      // Wall, Back
      -size, height, size,    uvScale, 0.0,   0.0, 1.0, 0.0,
      -size, 0.0, size,   uvScale, uvScale,        0.0, 1.0, 0.0,
      -size, height, -size,    0.0, 0.0,      0.0, 1.0, 0.0,

      -size, 0.0, size,   uvScale, uvScale,        0.0, 1.0, 0.0,
      -size, 0.0,-size,   0.0, uvScale,           0.0, 1.0, 0.0,
      -size, height, -size,    0.0, 0.0,      0.0, 1.0, 0.0,

      // Wall, Front
      size, height, size,    uvScale, 0.0,   0.0, 1.0, 0.0,
      size, height, -size,   0.0, 0.0,       0.0, 1.0, 0.0,
      size, 0.0, size,   uvScale, uvScale,        0.0, 1.0, 0.0,

      size, 0.0, size,   uvScale, uvScale,        0.0, 1.0, 0.0,
      size, height, -size,  0.0, 0.0,      0.0, 1.0, 0.0,
      size, 0.0,-size,   0.0, uvScale,           0.0, 1.0, 0.0,

      // Wall, Right
      size, height, -size,    uvScale, 0.0,   0.0, 1.0, 0.0,
      -size, height, -size,   0.0, 0.0,       0.0, 1.0, 0.0,
      size, 0.0, -size,   uvScale, uvScale,       0.0, 1.0, 0.0,

      -size, height, -size,   0.0, 0.0,       0.0, 1.0, 0.0,
      -size, 0.0,-size,   0.0, uvScale,           0.0, 1.0, 0.0,
      size, 0.0, -size,   uvScale, uvScale,       0.0, 1.0, 0.0,

      // Wall, Left
      size, height, size,    uvScale, 0.0,   0.0, 1.0, 0.0,
      size, 0.0, size,   uvScale, uvScale,       0.0, 1.0, 0.0,
      -size, height, size,   0.0, 0.0,       0.0, 1.0, 0.0,

      -size, height, size,   0.0, 0.0,       0.0, 1.0, 0.0,
      size, 0.0, size,   uvScale, uvScale,       0.0, 1.0, 0.0,
      -size, 0.0,size,   0.0, uvScale,           0.0, 1.0, 0.0,
    ]);

    _roomVertCount = (verts.length/8.0).toInt();
    _room = new SingleArrayMesh('FloorMesh', _graphicsDevice);
    _room.vertexArray.uploadData(verts, UsagePattern.StaticDraw);

    _room.attributes['vPosition'] = new SpectreMeshAttribute('vPosition',
        new VertexAttribute(0, 0, 0, 32, DataType.Float32, 3, false));
    _room.attributes['vTexCoord0'] = new SpectreMeshAttribute('vTexCoord0',
        new VertexAttribute(0, 0, 12, 32, DataType.Float32, 2, false));
    _room.attributes['vNormal'] = new SpectreMeshAttribute('vNormal',
        new VertexAttribute(0, 0, 20, 32, DataType.Float32, 3, false));

    _roomInputLayout = new InputLayout('FloorInputLayout', _graphicsDevice);
    _roomInputLayout.shaderProgram = _simpleShaderProgram;
    _roomInputLayout.mesh = _room;
  }

  //---------------------------------------------------------------------
  // Properties
  //---------------------------------------------------------------------

  int _instanceCount = 15;
  int get instanceCount => _instanceCount;
  set instanceCount(int value) {
    if(value > _instanceCount) {
      for(int i = _instanceCount; i < Math.min(instances.length, value); ++i) {
        instances[i].visible = true;
      }
    }

    _instanceCount = value;

    if(_applicationControls != null)
      _applicationControls.instanceCount = value;

    if(value < instances.length) {
      for(int i = value; i < instances.length; ++i) {
        instances[i].visible = false;
      }
      return;
    }

    if(_meshes == null)
      return;

    SkinnedMesh mesh = _meshes[meshIndex];

    while(instances.length < value) {
      SampleMeshInstance instance = new SampleMeshInstance(mesh, instances.length);
      instance.currentTime = instances.length * 1.8; // Force every mesh to animate at different offsets
      instances.add(instance);
    }
  }

  List<SampleMeshInstance> instances = new List<SampleMeshInstance>();
  bool autoAdjustInstanceCount = true;
  bool _useSimdPosing = false;
  set useSimdPosing(bool r) {
    _useSimdPosing = r;
    /*if(useSimdPosing)
      _instanceCount = instanceCount * 3;
    else
      _instanceCount = (instanceCount / 3).toInt();*/
  }
  bool get useSimdPosing => _useSimdPosing;

  bool useSimdSkinning = true;
  bool _useGpuSkinning = true;

  bool get useGpuSkinning => _useGpuSkinning;
  set useGpuSkinning(bool value) {
    if(_useGpuSkinning != value) {
      _useGpuSkinning = value;
      if(value)
        _meshes[_meshIndex].resetToBindPose();
    }
  }

  /// The index of the [SkinnedMesh] to draw.
  int get meshIndex => _meshIndex;
  set meshIndex(int value) {
    _meshIndex = value;
    if(_useGpuSkinning)
      _meshes[_meshIndex].resetToBindPose();
  }

  /// Whether debugging information should be drawn.
  ///
  /// If the debugging information is turned on in this sample the
  /// mesh's skeleton will be displayed.
  bool get drawDebugInformation => _drawDebugInformation;
  set drawDebugInformation(bool value) { _drawDebugInformation = value; }

  //---------------------------------------------------------------------
  // Public methods
  //---------------------------------------------------------------------

  final Stopwatch updateSw = new Stopwatch();
  /// Updates the application.
  ///
  /// Uses the current change in time, [dt].
  void onUpdate(double dt) {
    _debugDrawManager.update(dt);

    updateSw.reset();
    updateSw.start();

    // Update the mesh
    for(int i = 0; i < instances.length; ++i) {
      instances[i].update(dt, useSimdPosing); // Won't animate if the mesh has had visible set to false
    }

    updateSw.stop();

    Mouse mouse = _gameLoop.mouse;

    if (mouse.isDown(Mouse.LEFT) || _gameLoop.pointerLock.locked) {
      _cameraController.accumDX = mouse.dx;
      _cameraController.accumDY = mouse.dy;
    }

    _cameraController.accumDZ = mouse.wheelDy;

    _cameraController.updateCamera(dt, _camera);

    // Get the current model-view-projection matrix
    //
    // Start off by copying the projection matrix into the matrix.
    _camera.copyProjectionMatrix(_modelViewProjectionMatrix);

    // Multiply the projection matrix by the view matrix to combine them.
    //
    // The mathematical operators in Dart Vector Math will end up creating
    // a new object. Rather than using * a self multiply is used. This is to
    // avoid creating additional objects. As a general rule with a garbage
    // collected language objects should be reused whenever possible.
    _modelViewProjectionMatrix.multiply(_camera.viewMatrix);

    // At this point we actually have the Model-View-Projection matrix. This
    // is because the model matrix is currently the identity matrix. The model
    // has no rotation, no scaling, and is sitting at (0, 0, 0).

    // Copy the Model-View-Projection matrix into a Float32List so it can be
    // passed in as a constant to the ShaderProgram.
    _modelViewProjectionMatrix.copyIntoArray(_modelViewProjectionMatrixArray);

    // Copy the View matrix from the camera into the Float32List.
    _camera.copyViewMatrixIntoArray(_modelViewMatrixArray);
  }

  /// Renders the scene.
  void onRender() {
    controller.recordSample();
    // Clear the color and depth buffer
    _graphicsContext.clearColorBuffer(
      _redClearColor,
      _greenClearColor,
      _blueClearColor,
      _alphaClearColor
    );
    _graphicsContext.clearDepthBuffer(1.0);

    // Reset the graphics context
    _graphicsContext.reset();

    // Set the renderer state
    _graphicsContext.setViewport(_viewport);
    _graphicsContext.setBlendState(_blendState);
    _graphicsContext.setSamplers(0, _samplers);

    // Draw the floor
    _graphicsContext.setShaderProgram(_simpleShaderProgram);
    // The matrices are the same for the drawing of each part of the mesh so
    // they only need to be set once.
    _graphicsContext.setConstant('uModelViewMatrix', _modelViewMatrixArray);
    _graphicsContext.setConstant('uModelViewProjectionMatrix', _modelViewProjectionMatrixArray);

    _graphicsContext.setVertexBuffers(0, [_room.vertexArray]);
    _graphicsContext.setPrimitiveTopology(PrimitiveTopology.Triangles);
    _graphicsContext.setInputLayout(_roomInputLayout);

    modelMatrix[0] = 1.0;
    modelMatrix[5] = 1.0;
    modelMatrix[10] = 1.0;

    modelMatrix[12] = 0.0;
    modelMatrix[14] = 0.0;
    modelMatrix[13] = -10.0;

    _graphicsContext.setConstant('uModelMatrix', modelMatrix);

    _graphicsContext.setTextures(0, _roomFloorTextures);
    _graphicsContext.draw(6, 0);

    _graphicsContext.setTextures(0, _roomCeilingTextures);
    _graphicsContext.draw(6, 6);

    _graphicsContext.setTextures(0, _roomWallTextures);
    _graphicsContext.draw(24, 12);

    // Set the shader program
    if(useGpuSkinning) {
      _graphicsContext.setShaderProgram(_skinnedShaderProgram);
      _graphicsContext.setConstant('uModelViewMatrix', _modelViewMatrixArray);
      _graphicsContext.setConstant('uModelViewProjectionMatrix', _modelViewProjectionMatrixArray);
    }

    for (int instance = 0; instance < instances.length; instance++) {
      SampleMeshInstance meshInstance = instances[instance];
      if(!meshInstance.visible) { break; }
      SkinnedMesh mesh = meshInstance.mesh;
      _graphicsContext.setVertexBuffers(0, [mesh.vertexArray, mesh.skinningArray]);
      _graphicsContext.setIndexBuffer(mesh.indexArray);
      _graphicsContext.setPrimitiveTopology(PrimitiveTopology.Triangles);

      if(useGpuSkinning) {
        _graphicsContext.setInputLayout(_skinnedInputLayout);
        _graphicsContext.setConstant('uBoneMatrices[0]', meshInstance.posedSkeleton.skinningMatrices);
      } else {
        meshInstance.skin(useSimdSkinning);
        _graphicsContext.setInputLayout(_inputLayout);
      }

      meshInstance.getMatrix(modelMatrix);
      _graphicsContext.setConstant('uModelMatrix', modelMatrix);

      // Draw each part of the mesh
      int meshCount = mesh.meshes.length;
      List<List<Texture2D>> meshTextures = _textures[_meshIndex];

      for (int i = 0; i < meshCount; ++i) {
        Map meshData = mesh.meshes[i];
        _graphicsContext.setTextures(0, meshTextures[i]);
        _graphicsContext.drawIndexed(meshData['count'], meshData['offset']);
      }
    }

    // Render debugging information if requested
    if (_drawDebugInformation) {
      _debugDrawManager.prepareForRender();
      _debugDrawManager.render(_camera);
    }
  }

  /// Resizes the application viewport.
  ///
  /// Changes the [Viewport]'s dimensions to the values contained in [width]
  /// and [height]. Additionally the [Camera]'s aspect ratio needs to be adjusted
  /// accordingly.
  ///
  /// This needs to occur whenever the underlying [CanvasElement] is resized,
  /// otherwise the rendered scene will be incorrect.
  void onResize(int width, int height) {
    canvas.width = width;
    canvas.height = height;
    // Resize the viewport
    _viewport.width = width;
    _viewport.height = height;
    // Change the aspect ratio of the camera
    _camera.aspectRatio = _viewport.aspectRatio;
  }
}

//---------------------------------------------------------------------
// Global variables
//---------------------------------------------------------------------

/// Instance of the [Application].
Application _application;
/// Instance of the [ApplicationControls].
ApplicationControls _applicationControls;
/// Instance of the [GameLoopHtml] controlling the application flow.
GameLoopHtml _gameLoop;
/// Identifier of the [CanvasElement] the application is rendering to.
final String _canvasId = '#backBuffer';

//---------------------------------------------------------------------
// GameLoop hooks
//---------------------------------------------------------------------

/// Callback for when the application should be updated.
void onFrame(GameLoop gameLoop) {
  _application.onUpdate(gameLoop.dt);
}

/// Callback for when the application should render.
void onRender(GameLoop gameLoop) {
  _application.onRender();
}

/// Callback for when the canvas is resized.
void onResize(GameLoopHtml gameLoop) {
  _application.onResize(gameLoop.width, gameLoop.height);
}

/// Callback for when the pointer lock changes.
///
/// Used to show/hide the options UI.
void onPointerLockChange(GameLoopHtml gameLoop) {

}

/// Entrypoint for the application.
void main() {
  // Get the canvas
  CanvasElement canvas = query(_canvasId);

  // Create the application
  _application = new Application(canvas);

  // Create the application controls
  _applicationControls = new ApplicationControls();

  // Hook up the game loop
  // The loop isn't started until the start method is called.
  _gameLoop = new GameLoopHtml(canvas);

  _gameLoop.onResize = onResize;
  _gameLoop.onUpdate = onFrame;
  _gameLoop.onRender = onRender;
  _gameLoop.onPointerLockChange = onPointerLockChange;

  // This application doesn't need pointer lock, so disable it.
  // If you want to use pointer lock, however, comment this line
  _gameLoop.pointerLock.lockOnClick = false;

  //_gameLoop.start();
}
