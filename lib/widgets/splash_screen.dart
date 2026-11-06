import 'package:flutter/material.dart';

import 'bank_mini_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.72, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.78, curve: Curves.easeOutCubic),
      ),
    );
    _textOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(_textOpacity);
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 64,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: reduceMotion
                          ? const AlwaysStoppedAnimation(1)
                          : _logoOpacity,
                      child: ScaleTransition(
                        scale: reduceMotion
                            ? const AlwaysStoppedAnimation(1)
                            : _logoScale,
                        child: const BankMiniLogo(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: reduceMotion
                          ? const AlwaysStoppedAnimation(1)
                          : _textOpacity,
                      child: SlideTransition(
                        position: reduceMotion
                            ? const AlwaysStoppedAnimation(Offset.zero)
                            : _textSlide,
                        child: const Column(
                          children: [
                            Text(
                              'E-Teller Bank Mini',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF172033),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Sistem Informasi Bank Mini Sekolah',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!reduceMotion) ...[
                      const SizedBox(height: 32),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF003FB3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
