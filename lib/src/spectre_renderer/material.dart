/*
  Copyright (C) 2013 John McCutchan <john@johnmccutchan.com>

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

part of spectre_renderer;

/** A material describes how a mesh is rendered. */
class Material {
  final String name;
  final Renderer renderer;
  final MaterialShader shader;
  /// Key shader constant variable.
  final Map<String, MaterialConstant> constants =
      new Map<String, MaterialConstant>();
  /// Key shader sampler variable.
  final Map<String, MaterialTexture> textures =
      new Map<String, MaterialTexture>();

  /// Add a new constant with [name] of [type].
  void addConstant(String name, String type) {
    MaterialConstant constant = constants[name];
    if (constant != null) {
      return;
    }
    constant = new MaterialConstant(name, type);
    constants[name] = constant;
  }

  // Set constant [name].
  void setConstant(String name, dynamic value) {
    MaterialConstant constant = constants[name];
    if (constant == null) {
      return;
    }
    constant.update(value);
  }

  Material(this.name, this.shader, this.renderer) {
    if (this.name == null) {
      throw new ArgumentError('name cannot be null.');
    }
    if (this.shader == null) {
      throw new ArgumentError('shader cannot be null.');
    }
    if (this.renderer == null) {
      throw new ArgumentError('renderer cannot be null.');
    }
    _link();
  }

  Material.clone(Material other)
    : renderer = other.renderer, name = other.name, shader = other.shader {
    _cloneLink(other);
  }

  /** Apply this material to be used for rendering */
  void apply(GraphicsDevice device) {
    shader.apply(device, this);
  }

  void _cloneLink(Material other) {
    constants.clear();
    other.constants.forEach((k, v) {
      constants[k] = new MaterialConstant.clone(v);
    });
    textures.clear();
    other.textures.forEach((k, v) {
      textures[k] = new MaterialTexture.clone(v);
    });
  }

  void _link() {
    textures.clear();
    shader.shader.samplers.forEach((k, v) {
      textures[k] = new MaterialTexture(renderer, k, '', v.textureUnit);
    });
  }

  void link() {
    _link();
  }

  dynamic toJson() {
    Map json = new Map();
    json['name'] = name;
    json['depthState'] = depthState.toJson();
    json['rasterizerState'] = rasterizerState.toJson();
    json['blendState'] = blendState.toJson();
    json['constants'] = {};
    constants.forEach((k, v) {
      json['constants'][k] = v.toJson();
    });
    json['textures'] = {};
    textures.forEach((k, v) {
      json['textures'][k] = v.toJson();
    });
    return json;
  }

  void fromJson(dynamic json) {
    depthState.fromJson(json['depthState']);
    rasterizerState.fromJson(json['rasterizerState']);
    blendState.fromJson(json['blendState']);
    constants.forEach((k, v) {
      v.fromJson(json['constants'][k]);
    });
    textures.forEach((k, v) {
      v.fromJson(json['textures'][k]);
    });
  }
}
