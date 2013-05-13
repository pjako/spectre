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

part of skeletal_bench;

/// Controls for the [Application].
class ApplicationControls {
  //---------------------------------------------------------------------
  // Class variables
  //---------------------------------------------------------------------

  /// Identifier for the container holding the UI controls.
  static String _controlContainerId = '#ui_wrap';
  /// Identifier for the container holding the model selection.
  static String _modelSelectionId = '#model_selection';
  /// Identifier for the SIMD Posing checkbox.
  static String _poseSimdId = '#pose_simd';
  /// Identifier for the counter.
  static String _counterId = '#counter';
  /// Classname for an option
  static String _optionClassName = 'option';
  /// Classname for when the UI should be hidden.
  static String _hideClassName = 'hide';
  /// Classname for when the UI should be shown.
  static String _showClassName = 'show';
  /// Classname for when an option is selected.
  static String _selectedClassName = 'selected';
  /// Classname for when an option is disabled.
  ///
  /// Used to disable mouse events after the model is selected.
  static String _disabledClassName = 'disabled';

  //---------------------------------------------------------------------
  // Member variables
  //---------------------------------------------------------------------

  /// [DivElement] containing the UI controls.
  DivElement _controlContainer;
  /// [DivElement] containing the model selection.
  DivElement _modelSelection;
  DivElement _counter;

  /// Creates an instance of the [ApplicationControls] class.
  ApplicationControls() {
    _controlContainer = query(_controlContainerId);
    _modelSelection = query(_modelSelectionId);
    _counter = query(_counterId);
    
    _counter.onTransitionEnd.listen((_) {
      _counter.attributes['data-count'] = _displayedInstanceCount.toString();
      _counter.classes.remove("spin-down");
      
      new Future.delayed(const Duration(milliseconds: 100), () {
        _instancesTransitioning = false;
        _updateCounter();
      });
    });
    
    // Hook up the instances 
    InputElement poseSimd = query(_poseSimdId);
    poseSimd.onChange.listen((_) {
      _application.useSimdPosing = poseSimd.checked;
    });
  }

  //---------------------------------------------------------------------
  // Public methods
  //---------------------------------------------------------------------

  bool _pauseCounterUpdates = true;
  bool get pauseCounterUpdates => _pauseCounterUpdates;
  set pauseCounterUpdates(bool value) {
    if(_pauseCounterUpdates != value) {
      _pauseCounterUpdates = value;
      _updateCounter();
    }
  }
  
  bool _instancesTransitioning = false;
  int _instanceCount = 0;
  int _displayedInstanceCount = 0;
  int get instanceCount => _instanceCount;
  set instanceCount(int value) {
    if(_instanceCount != value) {
      _instanceCount = value;
      _updateCounter();
    }
  }

  //---------------------------------------------------------------------
  // Private methods
  //---------------------------------------------------------------------

  /// Selects the model at the given [index] and updates the UI.
  void _selectModel(int index) {
    int currentIndex = _application.meshIndex;

    if (currentIndex == index) {
      return;
    }

    // Remove selection classes from the old selection
    DivElement current = _modelSelection.children[currentIndex];
    current.classes.remove(_selectedClassName);
    current.classes.remove(_disabledClassName);

    // Add selection classes to the new selection
    DivElement selected = _modelSelection.children[index];
    selected.classes.add(_selectedClassName);
    selected.classes.add(_disabledClassName);

    // Change the model being displayed
    _application.meshIndex = index;
  }
  
  void _updateCounter() {
    if(!_pauseCounterUpdates && !_instancesTransitioning && _displayedInstanceCount != _instanceCount) {
      _displayedInstanceCount = _instanceCount;
      _counter.attributes['data-count-next'] = "${_displayedInstanceCount}";
      _counter.classes.add("spin-down");
      _instancesTransitioning = true;
    }
  }

  //---------------------------------------------------------------------
  // Class methods
  //---------------------------------------------------------------------

  /// Changes the visual appearance of the checkbox area.
  static void _toggleCheckboxArea(InputElement checkbox, DivElement parent) {
    bool enabled = !checkbox.checked;

    if (enabled) {
      parent.classes.add(_selectedClassName);
    } else {
      parent.classes.remove(_selectedClassName);
    }

    checkbox.checked = enabled;
  }
}
