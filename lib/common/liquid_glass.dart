import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A reusable widget that applies a real-time liquid glass effect
/// to its child (or acts as a glass container over the background).
class LiquidGlassContainer extends StatefulWidget {
  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.thickness = 30.0,
    this.refractiveIndex = 1.2,
    this.chromaticAberration = 0.05,
    this.glassColor = const Color(0xFFFFFFFF),
    this.glassColorIntensity = 0.0,
    this.lightAngle = 0.0,
    this.lightIntensity = 1.0,
    this.ambientStrength = 0.5,
    this.saturation = 1.5,
    this.borderRadius = 24.0,
    this.shapeType = LiquidGlassShapeType.roundedRect,
    this.interactiveLight = true,
  });

  /// The content behind the glass.
  final Widget child;

  /// Optical Properties
  final double thickness;
  final double refractiveIndex;
  final double chromaticAberration;

  /// Appearance
  final Color glassColor;
  final double glassColorIntensity;
  final double saturation;

  /// Lighting
  final double lightAngle;
  final double lightIntensity;
  final double ambientStrength;

  /// Shape
  final double borderRadius;
  final LiquidGlassShapeType shapeType;

  /// If true, the light follows the mouse/pointer position.
  final bool interactiveLight;

  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

enum LiquidGlassShapeType {
  roundedRect, // Type 3 in shader
  squircle, // Type 1 in shader
  ellipse, // Type 2 in shader
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer> {
  ui.FragmentShader? _shader;
  ui.FragmentProgram? _program;
  Offset _pointerPosition = Offset.zero;
  bool _isPointerDown = false;
  Size _widgetSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      _program = await ui.FragmentProgram.fromAsset(
        'assets/shaders/liquid_glass_interactive.frag',
      );
      _shader = _program?.fragmentShader();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading shader: $e');
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) {
      return widget.child;
    }

    // We use a Stack to layer the shader over the content.
    // The BackdropFilter captures the content behind it.
    return Stack(
      children: [
        // The background content
        widget.child,

        // The Glass Layer
        Positioned.fill(
          child: MouseRegion(
            onHover: (event) {
              if (widget.interactiveLight) {
                setState(() {
                  _pointerPosition = event.position;
                });
              }
            },
            onEnter: (event) {
              if (widget.interactiveLight) {
                setState(() {
                  _pointerPosition = event.position;
                  _isPointerDown = false;
                });
              }
            },
            child: GestureDetector(
              onPanStart: (details) {
                if (widget.interactiveLight) {
                  setState(() {
                    _pointerPosition = details.globalPosition;
                    _isPointerDown = true;
                  });
                }
              },
              onPanUpdate: (details) {
                if (widget.interactiveLight) {
                  setState(() {
                    _pointerPosition = details.globalPosition;
                  });
                }
              },
              onPanEnd: (details) {
                if (widget.interactiveLight) {
                  setState(() {
                    _isPointerDown = false;
                  });
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _widgetSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  return BackdropFilter(
                    filter: ui.ImageFilter.shader(
                      _shader!,
                      // samplerIndices: [0],
                    ),
                    child: Container(
                      color: Colors
                          .transparent, // Required for hit testing/gestures
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(LiquidGlassContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateShaderUniforms();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We need to update uniforms when dependencies change (like MediaQuery)
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateShaderUniforms();
    });
  }

  void _updateShaderUniforms() {
    if (_shader == null || _widgetSize == Size.zero) return;

    final shader = _shader!;

    // --- 1. Geometry & Shape Data ---
    // We define a single shape for this container.
    // The shader expects MAX_SHAPES * 6 floats.
    // We only populate the first shape.
    // Layout: [type, centerX, centerY, width, height, borderRadius]

    final shapeData = List<double>.filled(
      16 * 6,
      0.0,
    ); // 16 shapes max * 6 floats

    // Calculate center in global coordinates because fragCoord is global
    final renderBox = context.findRenderObject() as RenderBox?;
    final globalOffset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    // Center X/Y in global pixels
    final centerX = globalOffset.dx + _widgetSize.width / 2;
    final centerY = globalOffset.dy + _widgetSize.height / 2;

    // Shape Type Mapping
    int typeIndex = 3; // Rounded Rect
    if (widget.shapeType == LiquidGlassShapeType.squircle) {
      typeIndex = 1;
    } else if (widget.shapeType == LiquidGlassShapeType.ellipse) {
      typeIndex = 2;
    }

    shapeData[0] = typeIndex.toDouble();
    shapeData[1] = centerX;
    shapeData[2] = centerY;
    shapeData[3] = _widgetSize.width; // Width in pixels
    shapeData[4] = _widgetSize.height; // Height in pixels
    shapeData[5] = widget.borderRadius;

    // --- 2. Light Direction (Interactive vs Static) ---
    double angle = widget.lightAngle;
    if (widget.interactiveLight && renderBox != null) {
      // Convert global pointer to local coordinates
      final localPointer = renderBox.globalToLocal(_pointerPosition);
      // Calculate angle relative to center
      final dx = localPointer.dx - _widgetSize.width / 2;
      final dy = localPointer.dy - _widgetSize.height / 2;
      angle = math.atan2(dy, dx);
    }

    // --- 3. Set Uniforms ---
    // Indices must match the layout(location = X) in the .frag file

    // Location 0: uSize (Screen Size)
    shader.setFloat(0, MediaQuery.of(context).size.width);
    shader.setFloat(1, MediaQuery.of(context).size.height);

    // Location 1: uGlassColor (RGBA)
    shader.setFloat(2, widget.glassColor.red.toDouble());
    shader.setFloat(3, widget.glassColor.green.toDouble());
    shader.setFloat(4, widget.glassColor.blue.toDouble());
    shader.setFloat(5, widget.glassColorIntensity);

    // Location 2: uOpticalProps (refractiveIndex, chromaticAberration, thickness, blend)
    shader.setFloat(6, widget.refractiveIndex);
    shader.setFloat(7, widget.chromaticAberration);
    shader.setFloat(8, widget.thickness);
    shader.setFloat(9, 10.0); // Blend (hardcoded for smooth edges)

    // Location 3: uLightConfig (angle, intensity, ambient, saturation)
    shader.setFloat(10, angle);
    shader.setFloat(11, widget.lightIntensity);
    shader.setFloat(12, widget.ambientStrength);
    shader.setFloat(13, widget.saturation);

    // Location 4: uLightDirection (Pre-calculated cos/sin)
    shader.setFloat(14, math.cos(angle));
    shader.setFloat(15, math.sin(angle));

    // Location 5: uNumShapes
    shader.setFloat(16, 1.0); // We are only rendering 1 shape

    // Location 6: uShapeData Array
    // Arrays are set sequentially starting from the location index
    for (int i = 0; i < shapeData.length; i++) {
      shader.setFloat(17 + i, shapeData[i]);
    }
  }
}
