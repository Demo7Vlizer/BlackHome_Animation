import 'dart:math';

import 'package:flutter/material.dart';

class CardHiddenAnimationPage extends StatefulWidget {
  const CardHiddenAnimationPage({Key? key}) : super(key: key);

  @override
  State<CardHiddenAnimationPage> createState() =>
      CardHiddenAnimationPageState();
}

class CardHiddenAnimationPageState extends State<CardHiddenAnimationPage>
    with TickerProviderStateMixin {
  final cardSize = 150.0;

  late final holeSizeTween = Tween<double>(
    begin: 0,
    end: 1.5 * cardSize,
  );
  late final holeAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  double get holeSize => holeSizeTween.evaluate(holeAnimationController);
  late final cardOffsetAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  late final cardOffsetTween = Tween<double>(
    begin: 0,
    end: 2 * cardSize,
  ).chain(CurveTween(curve: Curves.easeInBack));
  late final cardRotationTween = Tween<double>(
    begin: 0,
    end: 0.5,
  ).chain(CurveTween(curve: Curves.easeInBack));
  late final cardElevationTween = Tween<double>(
    begin: 2,
    end: 20,
  );

  double get cardOffset =>
      cardOffsetTween.evaluate(cardOffsetAnimationController);
  double get cardRotation =>
      cardRotationTween.evaluate(cardOffsetAnimationController);
  double get cardElevation =>
      cardElevationTween.evaluate(cardOffsetAnimationController);

  // Add new animation controller for sparkle effect
  late final sparkleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  // Add background color animation
  late final backgroundColorController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final backgroundColorAnimation = ColorTween(
    begin: Colors.grey[100],
    end: Colors.blue[50],
  ).animate(CurvedAnimation(
    parent: backgroundColorController,
    curve: Curves.easeInOut,
  ));

  @override
  void initState() {
    holeAnimationController.addListener(() => setState(() {}));
    cardOffsetAnimationController.addListener(() => setState(() {}));
    backgroundColorController.addListener(() => setState(() {}));
    cardOffsetAnimationController.value = 1.0;
    super.initState();
  }

  @override
  void dispose() {
    holeAnimationController.dispose();
    cardOffsetAnimationController.dispose();
    backgroundColorController.dispose();
    sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColorAnimation.value,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () async {
              backgroundColorController.reverse();
              holeAnimationController.forward();
              await cardOffsetAnimationController.forward();
              Future.delayed(const Duration(milliseconds: 200),
                  () => holeAnimationController.reverse());
            },
            child: const Icon(Icons.remove),
            backgroundColor: Colors.redAccent,
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            onPressed: () async {
              holeAnimationController.forward();
              await Future.delayed(const Duration(milliseconds: 200));
              cardOffsetAnimationController.reverse();
              backgroundColorController.forward();
              sparkleController.forward(from: 0);
              await Future.delayed(const Duration(milliseconds: 800));
              holeAnimationController.reverse();
            },
            child: const Icon(Icons.add),
            backgroundColor: Colors.green,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              height: cardSize * 1.25,
              width: double.infinity,
              child: ClipPath(
                clipper: BlackHoleClipper(),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: holeSize,
                      child: Image.asset(
                        'images/hole.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(0, cardOffset),
                          child: Transform.rotate(
                            angle: cardRotation,
                            child: Stack(
                              children: [
                                // Add sparkle effect around the card
                                SparkleEffect(
                                  controller: sparkleController,
                                  size: cardSize,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: HelloWorldCard(
                                    size: cardSize,
                                    elevation: cardElevation,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Add floating particles in the background
          Positioned.fill(
            child: CustomPaint(
              painter: ParticlePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class BlackHoleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height / 2);
    path.arcTo(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width,
        height: size.height,
      ),
      0,
      pi,
      true,
    );
    // Using -1000 guarantees the card won't be clipped at the top, regardless of its height
    path.lineTo(0, -1000);
    path.lineTo(size.width, -1000);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(BlackHoleClipper oldClipper) => false;
}

// Add new SparkleEffect widget
class SparkleEffect extends StatelessWidget {
  final AnimationController controller;
  final double size;

  const SparkleEffect({
    Key? key,
    required this.controller,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (0.2 * controller.value),
          child: Opacity(
            opacity: (1 - controller.value) * 0.5,
            child: Container(
              width: size + 40,
              height: size + 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.withOpacity(0.5),
                    Colors.blue.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Add ParticlePainter for background effect
class ParticlePainter extends CustomPainter {
  final List<Offset> particles = List.generate(
    50,
    (index) => Offset(
      Random().nextDouble() * 400,
      Random().nextDouble() * 800,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      canvas.drawCircle(particle, 2, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HelloWorldCard extends StatelessWidget {
  const HelloWorldCard({
    Key? key,
    required this.size,
    required this.elevation,
  }) : super(key: key);

  final double size;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue, Colors.lightBlueAccent],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                color: Colors.white,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                'Hello\nWorld',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
