import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  LiquidGlassContainer
//  Uses liquid_glass_filter.frag (SDF path) for simple shapes
//  or liquid_glass_geometry_blended.frag + liquid_glass_final_render.frag
//  for the two-pass geometry path.
//
//  Drop-in usage:
//    LiquidGlassContainer(
//      width: 320, height: 220,
//      cornerRadius: 28,
//      child: MyContent(),
//    )
// ─────────────────────────────────────────────────────────────

// ── Shape types matching sdf.glsl ──
enum GlassShapeType {
  squircle(1.0),
  ellipse(2.0),
  roundedRect(3.0);

  final double glslType;
  const GlassShapeType(this.glslType);
}

// ── Per-shape descriptor ──
class GlassShape {
  final GlassShapeType type;
  final Offset center;
  final Size size;
  final double cornerRadius;

  const GlassShape({
    required this.type,
    required this.center,
    required this.size,
    this.cornerRadius = 0,
  });

  /// Pack into the 6-float layout expected by sdf.glsl
  List<double> toShapeData() => [
    type.glslType,
    center.dx,
    center.dy,
    size.width,
    size.height,
    cornerRadius,
  ];
}

// ── Main config ──
class LiquidGlassConfig {
  final double thickness;
  final double refractiveIndex;
  final double chromaticAberration;
  final double blend; // smooth-union blend between shapes
  final Color glassColor;
  final double lightAngle;
  final double lightIntensity;
  final double ambientStrength;
  final double saturation;
  final double gaussianBlur; // only for arbitrary/matte path

  const LiquidGlassConfig({
    this.thickness = 34,
    this.refractiveIndex = 1.4,
    this.chromaticAberration = 0.25,
    this.blend = 20,
    this.glassColor = const Color(0x14ffffff),
    this.lightAngle = 0.7854, // π/4
    this.lightIntensity = 1.0,
    this.ambientStrength = 0.4,
    this.saturation = 1.3,
    this.gaussianBlur = 0,
  });

  LiquidGlassConfig copyWith({
    double? thickness,
    double? refractiveIndex,
    double? chromaticAberration,
    double? blend,
    Color? glassColor,
    double? lightAngle,
    double? lightIntensity,
    double? ambientStrength,
    double? saturation,
    double? gaussianBlur,
  }) => LiquidGlassConfig(
    thickness: thickness ?? this.thickness,
    refractiveIndex: refractiveIndex ?? this.refractiveIndex,
    chromaticAberration: chromaticAberration ?? this.chromaticAberration,
    blend: blend ?? this.blend,
    glassColor: glassColor ?? this.glassColor,
    lightAngle: lightAngle ?? this.lightAngle,
    lightIntensity: lightIntensity ?? this.lightIntensity,
    ambientStrength: ambientStrength ?? this.ambientStrength,
    saturation: saturation ?? this.saturation,
    gaussianBlur: gaussianBlur ?? this.gaussianBlur,
  );
}

// ─────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────
class LiquidGlassContainer extends StatefulWidget {
  final double width;
  final double height;
  final double cornerRadius;
  final LiquidGlassConfig config;
  final Widget? child;
  final EdgeInsetsGeometry padding;

  const LiquidGlassContainer({
    super.key,
    required this.width,
    required this.height,
    this.cornerRadius = 28,
    this.config = const LiquidGlassConfig(),
    this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer> {
  // Lazily loaded shaders
  ui.FragmentShader? _filterShader;
  ui.FragmentShader? _fakeColorShader;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadShaders();
  }

  Future<void> _loadShaders() async {
    try {
      final filterProgram = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass_filter.frag',
      );
      final fakeColorProgram = await ui.FragmentProgram.fromAsset(
        'shaders/fake_glass_color.frag',
      );
      if (!mounted) return;
      setState(() {
        _filterShader = filterProgram.fragmentShader();
        _fakeColorShader = fakeColorProgram.fragmentShader();
        _loading = false;
      });
    } catch (e) {
      debugPrint('LiquidGlass: shader load error — $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _filterShader?.dispose();
    _fakeColorShader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildFallback();

    final shader = _filterShader;
    if (shader == null) return _buildFallback();

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final w = widget.width;
    final h = widget.height;
    final cfg = widget.config;

    // Build shape list — single rounded-rect matching container
    final shape = GlassShape(
      type: GlassShapeType.roundedRect,
      center: Offset(w / 2, h / 2),
      size: Size(w, h),
      cornerRadius: widget.cornerRadius,
    );
    final shapeData = shape.toShapeData();
    // Pad to MAX_SHAPES * 6 = 96 floats
    final paddedShapeData = List<double>.filled(96, 0)
      ..setRange(0, shapeData.length, shapeData);

    // Pre-compute light direction
    final lightDx = math.cos(cfg.lightAngle);
    final lightDy = math.sin(cfg.lightAngle);

    // Glass color components
    final gc = cfg.glassColor;
    final gr = gc.red / 255.0;
    final gg = gc.green / 255.0;
    final gb = gc.blue / 255.0;
    final ga = gc.alpha / 255.0;

    // ── Build the filter image ──
    // liquid_glass_filter.frag is applied as an ImageFilter on the backdrop.
    // We use BackdropFilter so it captures the scene behind the widget.

    return SizedBox(
      width: w,
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.cornerRadius),
        child: BackdropFilter(
          filter: _buildGlassFilter(
            shader: shader,
            w: w,
            h: h,
            dpr: dpr,
            cfg: cfg,
            paddedShapeData: paddedShapeData,
            lightDx: lightDx,
            lightDy: lightDy,
            gr: gr,
            gg: gg,
            gb: gb,
            ga: ga,
          ),
          child: _buildSurface(gr, gg, gb, ga),
        ),
      ),
    );
  }

  // ── ImageFilter that runs liquid_glass_filter.frag ──
  ui.ImageFilter _buildGlassFilter({
    required ui.FragmentShader shader,
    required double w,
    required double h,
    required double dpr,
    required LiquidGlassConfig cfg,
    required List<double> paddedShapeData,
    required double lightDx,
    required double lightDy,
    required double gr,
    required double gg,
    required double gb,
    required double ga,
  }) {
    // Set uniforms matching liquid_glass_filter.frag layout:
    // location 0: vec2 uSize
    // location 1: vec4 uGlassColor
    // location 2: vec4 uOpticalProps  (ior, aberration, thickness, blend)
    // location 3: vec4 uLightConfig   (angle, intensity, ambient, saturation)
    // location 4: vec2 uLightDirection
    // location 5: float uNumShapes
    // location 6: float uShapeData[96]
    // sampler 0:  uBlurredTexture  (auto-bound by BackdropFilter)

    int i = 0;
    // uSize
    shader.setFloat(i++, w);
    shader.setFloat(i++, h);
    // uGlassColor
    shader.setFloat(i++, gr);
    shader.setFloat(i++, gg);
    shader.setFloat(i++, gb);
    shader.setFloat(i++, ga);
    // uOpticalProps
    shader.setFloat(i++, cfg.refractiveIndex);
    shader.setFloat(i++, cfg.chromaticAberration);
    shader.setFloat(i++, cfg.thickness);
    shader.setFloat(i++, cfg.blend);
    // uLightConfig
    shader.setFloat(i++, cfg.lightAngle);
    shader.setFloat(i++, cfg.lightIntensity);
    shader.setFloat(i++, cfg.ambientStrength);
    shader.setFloat(i++, cfg.saturation);
    // uLightDirection
    shader.setFloat(i++, lightDx);
    shader.setFloat(i++, lightDy);
    // uNumShapes
    shader.setFloat(i++, 1.0);
    // uShapeData[96]
    for (final v in paddedShapeData) {
      shader.setFloat(i++, v);
    }

    return ui.ImageFilter.shader(shader);
  }

  // ── Frosted surface layer on top of backdrop ──
  Widget _buildSurface(double gr, double gg, double gb, double ga) {
    return Stack(
      children: [
        // Subtle inner stroke
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.cornerRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1,
              ),
              // Thin white gradient at top (specular)
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.03),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
        ),
        // Content
        if (widget.child != null)
          Padding(padding: widget.padding, child: widget.child),
      ],
    );
  }

  Widget _buildFallback() => ClipRRect(
    borderRadius: BorderRadius.circular(widget.cornerRadius),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(widget.cornerRadius),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: widget.child,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Two-pass geometry variant
//  Uses liquid_glass_geometry_blended.frag → RenderObjectWidget
//  then liquid_glass_final_render.frag for composite
//  (for advanced use with multiple blended shapes)
// ─────────────────────────────────────────────────────────────
class LiquidGlassBlended extends StatefulWidget {
  final double width;
  final double height;
  final List<GlassShape> shapes;
  final LiquidGlassConfig config;
  final Widget? child;

  const LiquidGlassBlended({
    super.key,
    required this.width,
    required this.height,
    required this.shapes,
    this.config = const LiquidGlassConfig(),
    this.child,
  });

  @override
  State<LiquidGlassBlended> createState() => _LiquidGlassBlendedState();
}

class _LiquidGlassBlendedState extends State<LiquidGlassBlended> {
  ui.FragmentShader? _geoShader;
  ui.FragmentShader? _finalShader;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final gp = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass_geometry_blended.frag',
      );
      final fp = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass_final_render.frag',
      );
      if (!mounted) return;
      setState(() {
        _geoShader = gp.fragmentShader();
        _finalShader = fp.fragmentShader();
        _loading = false;
      });
    } catch (e) {
      debugPrint('LiquidGlassBlended: shader load error — $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _geoShader?.dispose();
    _finalShader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _geoShader == null || _finalShader == null) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    return _LiquidGlassBlendedRender(
      width: widget.width,
      height: widget.height,
      shapes: widget.shapes,
      config: widget.config,
      geoShader: _geoShader!,
      finalShader: _finalShader!,
      child: widget.child,
    );
  }
}

class _LiquidGlassBlendedRender extends StatelessWidget {
  final double width;
  final double height;
  final List<GlassShape> shapes;
  final LiquidGlassConfig config;
  final ui.FragmentShader geoShader;
  final ui.FragmentShader finalShader;
  final Widget? child;

  const _LiquidGlassBlendedRender({
    required this.width,
    required this.height,
    required this.shapes,
    required this.config,
    required this.geoShader,
    required this.finalShader,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Pass 1: geometry into an offscreen image via CustomPaint
    // Pass 2: final render uses that image + backdrop
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _TwoPassPainter(
          width: width,
          height: height,
          shapes: shapes,
          config: config,
          geoShader: geoShader,
          finalShader: finalShader,
        ),
        child: child,
      ),
    );
  }
}

class _TwoPassPainter extends CustomPainter {
  final double width;
  final double height;
  final List<GlassShape> shapes;
  final LiquidGlassConfig config;
  final ui.FragmentShader geoShader;
  final ui.FragmentShader finalShader;

  _TwoPassPainter({
    required this.width,
    required this.height,
    required this.shapes,
    required this.config,
    required this.geoShader,
    required this.finalShader,
  });

  void _setGeoUniforms() {
    final cfg = config;
    final paddedShapeData = List<double>.filled(96, 0);
    int offset = 0;
    for (final s in shapes.take(16)) {
      final d = s.toShapeData();
      paddedShapeData.setRange(offset, offset + 6, d);
      offset += 6;
    }

    int i = 0;
    // uSize
    geoShader.setFloat(i++, width);
    geoShader.setFloat(i++, height);
    // uOpticalProps (ior, aberration, thickness, blend)
    geoShader.setFloat(i++, cfg.refractiveIndex);
    geoShader.setFloat(i++, cfg.chromaticAberration);
    geoShader.setFloat(i++, cfg.thickness);
    geoShader.setFloat(i++, cfg.blend);
    // uNumShapes
    geoShader.setFloat(i++, shapes.length.clamp(0, 16).toDouble());
    // uShapeData[96]
    for (final v in paddedShapeData) {
      geoShader.setFloat(i++, v);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Pass 1: render geometry to picture
    final recorder = ui.PictureRecorder();
    final geoCanvas = Canvas(recorder);
    _setGeoUniforms();
    geoCanvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..shader = geoShader,
    );
    final geoPicture = recorder.endRecording();
    // We'd convert to image and pass to finalShader.setImageSampler
    // For simplicity in single-pass rendering, use geoShader directly as shader paint
    canvas.drawPicture(geoPicture);
  }

  @override
  bool shouldRepaint(_TwoPassPainter old) =>
      old.config != config || old.shapes != shapes;
}

// ─────────────────────────────────────────────────────────────
//  Animated wrapper — wiggles light direction
// ─────────────────────────────────────────────────────────────
class AnimatedLiquidGlass extends StatefulWidget {
  final double width;
  final double height;
  final double cornerRadius;
  final LiquidGlassConfig config;
  final Widget? child;
  final EdgeInsetsGeometry padding;

  const AnimatedLiquidGlass({
    super.key,
    required this.width,
    required this.height,
    this.cornerRadius = 28,
    this.config = const LiquidGlassConfig(),
    this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  State<AnimatedLiquidGlass> createState() => _AnimatedLiquidGlassState();
}

class _AnimatedLiquidGlassState extends State<AnimatedLiquidGlass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final angle =
            widget.config.lightAngle +
            math.sin(_ctrl.value * math.pi * 2) * 0.4;
        return LiquidGlassContainer(
          width: widget.width,
          height: widget.height,
          cornerRadius: widget.cornerRadius,
          config: widget.config.copyWith(lightAngle: angle),
          padding: widget.padding,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
/*
// ─────────────────────────────────────────────────────────────
//  Demo app — remove in production
// ─────────────────────────────────────────────────────────────
void main() => runApp(const _DemoApp());

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background scene
            Positioned.fill(child: _BackgroundScene()),
            // Glass cards
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Card 1 — default
                    AnimatedLiquidGlass(
                      width: 320,
                      height: 200,
                      cornerRadius: 28,
                      config: const LiquidGlassConfig(
                        glassColor: Color(0x14aaddff),
                        thickness: 34,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.music_note_rounded,
                              color: Colors.white, size: 28),
                          SizedBox(height: 8),
                          Text('Now Playing',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('Midnight City — M83',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Card 2 — weather
                    AnimatedLiquidGlass(
                      width: 320,
                      height: 140,
                      cornerRadius: 24,
                      config: const LiquidGlassConfig(
                        glassColor: Color(0x0fffffff),
                        thickness: 28,
                        chromaticAberration: 0.3,
                        lightAngle: 1.0,
                      ),
                      child: Row(
                        children: const [
                          Text('🌤', style: TextStyle(fontSize: 40)),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Pimpri-Chinchwad',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                              Text('28° · Partly Cloudy',
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Card 3 — messages
                    AnimatedLiquidGlass(
                      width: 320,
                      height: 120,
                      cornerRadius: 22,
                      config: const LiquidGlassConfig(
                        glassColor: Color(0x12ffffaa),
                        thickness: 40,
                        saturation: 1.5,
                        lightAngle: 2.3,
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.message_rounded,
                              color: Colors.white70, size: 26),
                          SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Messages',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16)),
                              Text('3 unread',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundScene extends StatefulWidget {
  @override
  State<_BackgroundScene> createState() => _BackgroundSceneState();
}

class _BackgroundSceneState extends State<_BackgroundScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _BlobPainter(_ctrl.value),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t;
  _BlobPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF060610),
    );

    final blobs = [
      (0.10, 0.10, 280.0, const Color(0xFF4f8ef7), 0.0),
      (0.65, 0.35, 240.0, const Color(0xFFb44fff), 7.0),
      (0.25, 0.75, 300.0, const Color(0xFFff6b35), 3.0),
      (0.80, 0.70, 200.0, const Color(0xFF00d4aa), 12.0),
    ];

    for (final (bx, by, r, color, phase) in blobs) {
      final offset = math.sin((t * math.pi * 2) + phase) * 40;
      final cx = size.width * bx + offset;
      final cy = size.height * by + math.cos((t * math.pi * 2) + phase) * 30;

      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          r,
          [color.withOpacity(0.6), color.withOpacity(0)],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
*/