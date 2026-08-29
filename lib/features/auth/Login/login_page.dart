import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/responsive.dart';
import 'package:iq_plus/common/utility/utility.dart';

import 'components/login_form.dart';
import 'components/login_screen_top_image.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  int selectedRole = 0;

  final List<String> roles = [
    'Super Admin',
    'Admin',
    'Consultant',
    'Customer',
  ];

  late AnimationController _floatController;
  
  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🚀 Animated Vibrant Mesh Background
          _buildVibrantBackground(),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔹 Minimalist Branding
                    _buildMinimalBrand(),
                    
                    const SizedBox(height: 30),
                    
                    // 🔹 The Switcher (Pill Design)
                    _buildModernSwitcher(),
                    
                    const SizedBox(height: 40),
                    
                    // 🔹 The Glass Command Center
                    _buildGlassCard(isDesktop),
                    
                    const SizedBox(height: 40),
                    
                    // 🔹 Secure Badge
                    _buildSecureLabel(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibrantBackground() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        // 🎨 Dynamically shifting hues for the background gradient
        final double hueBase = _floatController.value * 360;
        final Color color1 = HSLColor.fromAHSL(1.0, hueBase % 360, 0.65, 0.94).toColor();
        final Color color2 = HSLColor.fromAHSL(1.0, (hueBase + 60) % 360, 0.7, 0.97).toColor();
        final Color color3 = HSLColor.fromAHSL(1.0, (hueBase + 120) % 360, 0.65, 0.94).toColor();

        return Stack(
          children: [
            // 🌈 Animated Base Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color1, color2, color3],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            
            // Orb 1: Indigo (Moving)
            Positioned(
              top: -100 + (120 * sin(_floatController.value * 2 * pi)),
              right: -50 + (80 * cos(_floatController.value * 2 * pi)),
              child: _buildBlurOrb(500, const Color(0xFF6366F1).withValues(alpha: 0.12)),
            ),
            
            // Orb 2: Teal (Moving)
            Positioned(
              bottom: -150 + (100 * cos(_floatController.value * 2 * pi)),
              left: -100 + (60 * sin(_floatController.value * 2 * pi)),
              child: _buildBlurOrb(450, const Color(0xFF14B8A6).withValues(alpha: 0.12)),
            ),
            
            // Orb 3: Violet (Moving)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: 50 + (180 * sin(_floatController.value * 3 * pi)),
              child: _buildBlurOrb(350, const Color(0xFFA855F7).withValues(alpha: 0.08)),
            ),

            // ❄️ Subtle Frost Overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.white.withValues(alpha: 0.02)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlurOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalBrand() {
    return Column(
      children: [
        const Text(
          "I Q  P L U S",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 12,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Container(width: 30, height: 2, color: AppColors.kPrimaryColor),
      ],
    );
  }

  Widget _buildModernSwitcher() {
    return Container(
      height: 68,
      constraints: const BoxConstraints(maxWidth: 550),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // 💧 Liquid Primary Glass Indicator
                AnimatedAlign(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutQuart,
                  alignment: Alignment(-1.0 + (selectedRole * (2.0 / (roles.length - 1))), 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / roles.length,
                    child: AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, child) {
                        // 🌊 Surface tension wobble for liquid feel
                        final double radiusWobble = 28 + (2 * cos(_floatController.value * 4 * pi));

                        return Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radiusWobble),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.kPrimaryLightColor,
                                AppColors.kPrimaryColor,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.kPrimaryColor.withValues(alpha: 0.4),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(radiusWobble),
                            child: Stack(
                              children: [
                                // ⚡ Moving Internal Glass Sheen (Refraction)
                                Positioned(
                                  top: -50,
                                  left: -100 + (250 * (_floatController.value * 1.5 % 1.0)),
                                  child: Transform.rotate(
                                    angle: pi / 4,
                                    child: Container(
                                      width: 25,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0),
                                            Colors.white.withValues(alpha: 0.3),
                                            Colors.white.withValues(alpha: 0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // ✨ Subtle Bottom Glow (Liquid Depth)
                                Positioned(
                                  bottom: -10,
                                  right: -20,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.1),
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
                ),
                // Tab Labels
                Row(
                  children: List.generate(roles.length, (index) {
                    final isSelected = selectedRole == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedRole = index),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 400),
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF1E293B).withValues(alpha: 0.5),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                            child: Text(roles[index].toUpperCase()),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(bool isDesktop) {
    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 1050 : 480),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(44),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 60,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(44),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutQuart,
              child: Responsive(
                mobile: MobileLoginScreen(selectedRole: selectedRole),
                desktop: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                          ),
                          child: Center(child: LoginScreenTopImage(selectedRole: selectedRole)),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 60),
                          child: LoginForm(selectedRole: selectedRole),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecureLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 14),
        const SizedBox(width: 10),
        Text(
          "PORTAL IS ENCRYPTED AND SECURE",
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF94A3B8).withValues(alpha: 0.8),
            letterSpacing: 2
          ),
        ),
      ],
    );
  }
}

class MobileLoginScreen extends StatelessWidget {
  final int selectedRole;
  const MobileLoginScreen({super.key, required this.selectedRole});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          child: LoginScreenTopImage(selectedRole: selectedRole),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 60),
          child: LoginForm(selectedRole: selectedRole),
        ),
      ],
    );
  }
}
