import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector;

class ParticleTextMorpher extends StatefulWidget {
  const ParticleTextMorpher({Key? key}) : super(key: key);

  @override
  State<ParticleTextMorpher> createState() => _ParticleTextMorpherState();
}

class _ParticleTextMorpherState extends State<ParticleTextMorpher>
    with TickerProviderStateMixin {
  late final AnimationController _particleController;
  late final AnimationController _colorController;
  final Random _random = Random();
  // Reduced particle count for better performance
  final int particleCount = 50;
  final List<ParticleModel> particles = [];
  final List<String> texts = [
    '✨ MAGIC',
    '🌟 DREAM',
    '🎨 CREATE',
    '💫 SHINE',
    '🚀 BEYOND',
  ];
  int currentTextIndex = 0;
  bool isAnimating = false;

  // Add gradient background animation
  late final AnimationController _backgroundController;
  
  // Add mouse position for particle interaction
  Offset? mousePosition;
  
  // Replace Vector2 with custom Point class
  final Point gravity = Point(0, 0.05);
  
  // Add particle shapes
  final List<ParticleShape> particleShapes = [
    ParticleShape.circle,
    ParticleShape.star,
    ParticleShape.heart,
    ParticleShape.diamond,
    ParticleShape.spark,
  ];

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _updateParticles();
          });
        }
      });

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _initializeParticles();
    _scheduleNextAnimation();
  }

  void _onAnimationUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _initializeParticles() {
    particles.clear();
    for (int i = 0; i < particleCount; i++) {
      particles.add(ParticleModel(
        position: _getRandomPosition(),
        velocity: _getRandomVelocity(),
        color: _getRandomColor(),
        size: _random.nextDouble() * 2 + 1,
        shape: particleShapes[_random.nextInt(particleShapes.length)],
        rotation: _random.nextDouble() * pi * 2,
        rotationSpeed: _random.nextDouble() * 0.01,
        opacity: _random.nextDouble() * 0.5 + 0.5,
        energy: _random.nextDouble() * 0.5 + 0.5,
      ));
    }
  }

  Offset _getRandomPosition() {
    return Offset(
      _random.nextDouble() * 300,
      _random.nextDouble() * 300,
    );
  }

  Offset _getRandomVelocity() {
    return Offset(
      _random.nextDouble() * 1.5 - 0.75, // Reduced velocity
      _random.nextDouble() * 1.5 - 0.75,
    );
  }

  Color _getRandomColor() {
    final colors = [
      Colors.blue.shade300,
      Colors.red.shade300,
      Colors.green.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _scheduleNextAnimation() async {
    if (!mounted) return;
    
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted || isAnimating) return;

    isAnimating = true;
    setState(() {
      currentTextIndex = (currentTextIndex + 1) % texts.length;
      _initializeParticles();
    });

    await _particleController.forward(from: 0);
    isAnimating = false;
    _scheduleNextAnimation();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _colorController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MouseRegion(
        onHover: (event) {
          setState(() {
            mousePosition = event.localPosition;
          });
        },
        onExit: (_) {
          setState(() {
            mousePosition = null;
          });
        },
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      Colors.black,
                      Colors.blue.withOpacity(0.3),
                      _backgroundController.value,
                    )!,
                    Color.lerp(
                      Colors.black,
                      Colors.purple.withOpacity(0.3),
                      _backgroundController.value,
                    )!,
                  ],
                ),
              ),
              child: RepaintBoundary(
                child: Stack(
                  children: [
                    // Add floating background particles
                    CustomPaint(
                      painter: BackgroundParticlePainter(
                        progress: _backgroundController.value,
                      ),
                      size: Size.infinite,
                    ),
                    Center(
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: CustomPaint(
                          painter: ParticlePainter(
                            particles: particles,
                            progress: _particleController.value,
                            text: texts[currentTextIndex],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Update _updateParticles method
  void _updateParticles() {
    for (var particle in particles) {
      // Simplified physics
      particle.velocity = Offset(
        particle.velocity.dx * 0.98,
        particle.velocity.dy + gravity.y * 0.5,
      );
      
      particle.position = Offset(
        particle.position.dx + particle.velocity.dx,
        particle.position.dy + particle.velocity.dy,
      );
      
      particle.rotation += particle.rotationSpeed * 0.5;
    }
  }
}

// Add enum for particle shapes
enum ParticleShape { circle, star, heart, diamond, spark }

class ParticleModel {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  ParticleShape shape;
  double rotation;
  double rotationSpeed;
  double opacity;
  double energy;

  ParticleModel({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.shape,
    required this.rotation,
    required this.rotationSpeed,
    this.opacity = 1.0,
    this.energy = 1.0,
  });
}

class BackgroundParticlePainter extends CustomPainter {
  final double progress;
  final List<Offset> stars = List.generate(
    50,
    (index) => Offset(
      Random().nextDouble() * 400,
      Random().nextDouble() * 800,
    ),
  );

  BackgroundParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (var star in stars) {
      final twinkle = (sin(progress * pi * 2 + star.dx) + 1) / 2;
      paint.color = Colors.white.withOpacity(0.1 + twinkle * 0.2);
      canvas.drawCircle(star, 1 + twinkle, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ParticlePainter extends CustomPainter {
  final List<ParticleModel> particles;
  final double progress;
  final String text;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.text,
  });

  void drawParticle(Canvas canvas, Offset position, double size, 
      ParticleShape shape, Paint paint, double rotation) {
    switch (shape) {
      case ParticleShape.circle:
        canvas.drawCircle(position, size, paint);
        break;
      case ParticleShape.star:
        drawStar(canvas, position, size * 2, paint, rotation);
        break;
      case ParticleShape.heart:
        drawHeart(canvas, position, size * 2, paint, rotation);
        break;
      case ParticleShape.diamond:
        drawDiamond(canvas, position, size, paint, rotation);
        break;
      case ParticleShape.spark:
        drawSpark(canvas, position, size, paint, rotation);
        break;
    }
  }

  void drawStar(Canvas canvas, Offset center, double size, 
      Paint paint, double rotation) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final angle = rotation + (i * 4 * pi / 5);
      final point = Offset(
        center.dx + size * cos(angle),
        center.dy + size * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void drawHeart(Canvas canvas, Offset center, double size, 
      Paint paint, double rotation) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx + size * 0.7, center.dy - size * 0.5,
      center.dx + size * 0.6, center.dy - size * 0.7,
      center.dx, center.dy - size * 0.2,
    );
    path.cubicTo(
      center.dx - size * 0.6, center.dy - size * 0.7,
      center.dx - size * 0.7, center.dy - size * 0.5,
      center.dx, center.dy + size * 0.3,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void drawDiamond(Canvas canvas, Offset center, double size, 
      Paint paint, double rotation) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final angle = rotation + (i * pi / 2);
      final point = Offset(
        center.dx + size * cos(angle),
        center.dy + size * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void drawSpark(Canvas canvas, Offset center, double size, 
      Paint paint, double rotation) {
    for (var i = 0; i < 4; i++) {
      final angle = rotation + (i * pi / 2);
      canvas.drawLine(
        center,
        Offset(
          center.dx + size * cos(angle),
          center.dy + size * sin(angle),
        ),
        paint..strokeWidth = 2,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw particles with improved effects
    for (var particle in particles) {
      final particlePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = particle.color.withOpacity(particle.opacity * (1 - progress))
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          particle.energy * 2,
        );

      // Draw particle trail
      final trail = Path();
      trail.moveTo(
        particle.position.dx - particle.velocity.dx * 3,
        particle.position.dy - particle.velocity.dy * 3,
      );
      trail.lineTo(particle.position.dx, particle.position.dy);
      canvas.drawPath(trail, particlePaint..style = PaintingStyle.stroke);

      // Draw particle with shape
      drawParticle(
        canvas,
        particle.position,
        particle.size * particle.energy,
        particle.shape,
        particlePaint,
        particle.rotation,
      );
    }

    // Draw text with enhanced effects (without background glow)
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          foreground: Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.blue.withOpacity(progress),
                Colors.purple.withOpacity(progress),
                Colors.pink.withOpacity(progress),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(
              Rect.fromLTWH(0, 0, size.width, size.height),
            ),
          shadows: [
            Shadow(
              color: Colors.blue.withOpacity(progress * 0.7),
              blurRadius: 15,
            ),
            Shadow(
              color: Colors.purple.withOpacity(progress * 0.5),
              blurRadius: 25,
            ),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    // Draw text
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) =>
      progress != oldDelegate.progress || text != oldDelegate.text;
}

// Add Point class for simpler vector operations
class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);
}