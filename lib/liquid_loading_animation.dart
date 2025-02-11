import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';

class LiquidLoadingAnimation extends StatefulWidget {
  const LiquidLoadingAnimation({Key? key}) : super(key: key);

  @override
  State<LiquidLoadingAnimation> createState() => _LiquidLoadingAnimationState();
}

class _LiquidLoadingAnimationState extends State<LiquidLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _waves = List.generate(6, (index) => Random().nextDouble() * 2 * pi);
  final _velocities = List.generate(6, (index) => Random().nextDouble() * 0.015 + 0.005);
  Color _currentColor = Colors.blue;
  Color _targetColor = Colors.blue;
  final _colors = [
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
  ];

  final List<Particle> _particles = List.generate(20, (index) {
    final random = Random();
    return Particle(
      position: Offset(random.nextDouble() * 200, random.nextDouble() * 200),
      velocity: Offset(random.nextDouble() * 2 - 1, random.nextDouble() * 2 - 1),
      size: random.nextDouble() * 3 + 1,
    );
  });

  Offset? _touchPosition;
  final List<Ripple> _ripples = [];

  // Modify loading progress for smoother filling
  double _progress = 0.0;
  bool _isLoading = true;
  double _fillLevel = 0.0;
  
  // Add text style animation
  final List<String> _loadingTexts = [
    'Loading...',
    'Almost there...',
    'Just a moment...',
    'Processing...',
  ];
  int _currentTextIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();

    // Periodically change color
    Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() {
        _currentColor = _targetColor;
        _targetColor = _colors[Random().nextInt(_colors.length)];
      });
    });

    // Smoother filling animation
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isLoading) {
        setState(() {
          _progress += 0.005; // Slower progress
          // Smooth water filling effect
          _fillLevel = Curves.easeInOut.transform(_progress);
          
          if (_progress >= 1.0) {
            _progress = 0.0;
            _currentTextIndex = (_currentTextIndex + 1) % _loadingTexts.length;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _touchPosition = details.localPosition;
      _ripples.add(Ripple(position: _touchPosition!, radius: 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTapDown: _handleTapDown,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _currentColor.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        // Update waves with varying velocities and damping
                        for (var i = 0; i < _waves.length; i++) {
                          _waves[i] += _velocities[i] * (1 - _controller.value * 0.2);
                        }
                        return TweenAnimationBuilder<Color?>(
                          tween: ColorTween(
                            begin: _currentColor,
                            end: _targetColor,
                          ),
                          duration: const Duration(seconds: 2),
                          builder: (context, color, child) {
                            return CustomPaint(
                              painter: LiquidPainter(
                                progress: _controller.value,
                                waves: _waves,
                                color: color ?? _currentColor,
                                particles: _particles,
                                ripples: _ripples,
                                touchPosition: _touchPosition,
                                loadingProgress: _progress,
                                fillLevel: _fillLevel,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Add percentage text
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      color: _currentColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: _currentColor.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Add animated loading text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _loadingTexts[_currentTextIndex],
                key: ValueKey(_currentTextIndex),
                style: TextStyle(
                  color: _currentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: _currentColor.withOpacity(0.5),
                      blurRadius: 5,
                    ),
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

class LiquidPainter extends CustomPainter {
  final double progress;
  final List<double> waves;
  final Color color;
  final List<Particle> particles;
  final List<Ripple> ripples;
  final Offset? touchPosition;
  final double loadingProgress;
  final double fillLevel;
  
  LiquidPainter({
    required this.progress,
    required this.waves,
    required this.color,
    required this.particles,
    required this.ripples,
    required this.fillLevel,
    this.touchPosition,
    required this.loadingProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Draw container shape
    final containerPath = Path()
      ..moveTo(20, 40) // Start from top with some padding
      ..lineTo(20, size.height - 40) // Left side
      ..quadraticBezierTo(20, size.height - 20, 40, size.height - 20) // Bottom left corner
      ..lineTo(size.width - 40, size.height - 20) // Bottom
      ..quadraticBezierTo(size.width - 20, size.height - 20, size.width - 20, size.height - 40) // Bottom right corner
      ..lineTo(size.width - 20, 40) // Right side
      ..quadraticBezierTo(size.width - 20, 20, size.width - 40, 20) // Top right corner
      ..lineTo(40, 20) // Top
      ..quadraticBezierTo(20, 20, 20, 40) // Top left corner
      ..close();

    // Clip to container shape
    canvas.clipPath(containerPath);

    // Draw glass effect
    canvas.drawPath(
      containerPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
    );

    // Draw liquid
    final liquidHeight = size.height * (1 - fillLevel);
    final wavePath = Path()
      ..moveTo(0, size.height);

    // Enhanced wave effect
    for (var x = 0.0; x <= size.width + 20; x += 0.5) {
      var y = liquidHeight;
      
      // Combine multiple waves
      for (var i = 0; i < waves.length; i++) {
        final frequency = 1 + i * 0.25;
        final amplitude = size.height * 0.015 * (waves.length - i) / waves.length;
        y += sin((x / size.width) * pi * frequency + waves[i]) * amplitude;
        
        // Add cross-wave interference
        if (i > 0) {
          y += cos((x / size.width) * pi * frequency * 1.5 + waves[i-1]) * amplitude * 0.5;
        }
      }
      
      // Add meniscus effect near walls
      final distanceFromWall = min(x, size.width - x);
      if (distanceFromWall < 20) {
        y += (20 - distanceFromWall) * 0.5;
      }
      
      wavePath.lineTo(x, y);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    // Draw liquid with gradient
    canvas.drawPath(
      wavePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.7),
            color.withOpacity(0.9),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Add surface tension highlights
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(wavePath, highlightPaint);

    // Draw container outline
    canvas.drawPath(
      containerPath,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
    );

    // Draw light rays
    _drawLightRays(canvas, size, centerX, centerY, size.width / 2);

    // Draw swirling particles
    _drawParticles(canvas, size);

    // Draw ripples
    _drawRipples(canvas, centerX, centerY);

    // Draw touch glow
    if (touchPosition != null) {
      canvas.drawCircle(
        touchPosition!,
        20,
        Paint()
          ..color = color.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Add progress ring
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.5),
        ],
        stops: [0.0, loadingProgress],
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
      ).createShader(Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: size.width / 2,
      ))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: size.width / 2 + 5,
      ),
      -pi / 2,
      2 * pi * loadingProgress,
      false,
      progressPaint,
    );

    // Add pulsing effect based on progress
    final pulseSize = (1.0 + sin(progress * pi * 4) * 0.05) * (size.width / 2);
    canvas.drawCircle(
      Offset(centerX, centerY),
      pulseSize,
      Paint()
        ..color = color.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Add splashing effect when nearly full
    if (fillLevel > 0.8) {
      final splashOpacity = (fillLevel - 0.8) * 5;
      final splashPaint = Paint()
        ..color = color.withOpacity(splashOpacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      for (var i = 0; i < 5; i++) {
        final splashHeight = sin(progress * pi * 2 + i) * 10;
        canvas.drawCircle(
          Offset(
            centerX + cos(i * pi / 2.5) * (size.width / 2) * 0.8,
            liquidHeight - splashHeight,
          ),
          3,
          splashPaint,
        );
      }
    }
  }

  void _drawLightRays(Canvas canvas, Size size, double centerX, double centerY, double radius) {
    final rayPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.2),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius,
      ));

    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4 + progress * pi;
      final path = Path()
        ..moveTo(centerX, centerY)
        ..lineTo(
          centerX + cos(angle) * radius * 1.5,
          centerY + sin(angle) * radius * 1.5,
        );

      canvas.drawPath(
        path,
        Paint()
          ..shader = rayPaint.shader
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (var particle in particles) {
      // Update particle position
      if (particle.position.dx < 0 || particle.position.dx > size.width) {
        particle.velocity = Offset(-particle.velocity.dx, particle.velocity.dy);
      }
      if (particle.position.dy < 0 || particle.position.dy > size.height) {
        particle.velocity = Offset(particle.velocity.dx, -particle.velocity.dy);
      }
      particle.update();

      canvas.drawCircle(
        particle.position,
        particle.size,
        particlePaint,
      );
    }
  }

  void _drawRipples(Canvas canvas, double centerX, double centerY) {
    for (var ripple in ripples) {
      ripple.update();
      canvas.drawCircle(
        ripple.position,
        ripple.radius,
        Paint()
          ..color = color.withOpacity(ripple.opacity * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    ripples.removeWhere((ripple) => ripple.opacity < 0.01);
  }

  @override
  bool shouldRepaint(LiquidPainter oldDelegate) => true;
}

class Particle {
  Offset position;
  Offset velocity;
  final double size;

  Particle({
    required this.position,
    required this.velocity,
    required this.size,
  });

  void update() {
    position += velocity;
  }
}

class Ripple {
  final Offset position;
  double radius;
  double opacity = 1.0;

  Ripple({
    required this.position,
    required this.radius,
  });

  void update() {
    radius += 2;
    opacity *= 0.95;
  }
} 