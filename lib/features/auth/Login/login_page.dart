import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/responsive.dart';

import 'components/login_form.dart';
import 'components/login_screen_top_image.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  int selectedRole = 0;

  final List<String> roles = ['Super Admin', 'Admin', 'Consultant', 'Customer'];

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
      backgroundColor: AppColors.loginBackground,
      body: Stack(
        children: [
          // 🚀 Animated Vibrant Mesh Background
          _buildVibrantBackground(),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
        // 🎨 Brand-aligned wash that gently shifts between the IQ + tints.
        final double t = _floatController.value * 2 * pi;
        final Color color1 = Color.lerp(
          AppColors.loginBackground,
          AppColors.loginBackground,
          (sin(t) + 1) / 2,
        )!;
        final Color color2 = AppColors.loginBackground;
        final Color color3 = Color.lerp(
          AppColors.loginBackground,
          AppColors.loginBackground,
          (cos(t) + 1) / 2,
        )!;

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

            // Orb 1: Steel blue (Moving)
            Positioned(
              top: -100 + (120 * sin(_floatController.value * 2 * pi)),
              right: -50 + (80 * cos(_floatController.value * 2 * pi)),
              child: _buildBlurOrb(
                500,
                AppColors.loginPrimary.withValues(alpha: 0.16),
              ),
            ),

            // Orb 2: Teal accent (Moving)
            Positioned(
              bottom: -150 + (100 * cos(_floatController.value * 2 * pi)),
              left: -100 + (60 * sin(_floatController.value * 2 * pi)),
              child: _buildBlurOrb(
                450,
                AppColors.loginAccent.withValues(alpha: 0.14),
              ),
            ),

            // Orb 3: Navy (Moving)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: 50 + (180 * sin(_floatController.value * 3 * pi)),
              child: _buildBlurOrb(
                350,
                AppColors.loginPrimary.withValues(alpha: 0.10),
              ),
            ),

            // ❄️ Subtle Frost Overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: AppColors.loginBackground.withValues(alpha: 0.02)),
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
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 20)],
      ),
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
              color: AppColors.loginSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: AppColors.loginSurface.withValues(alpha: 0.2),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // 💧 Liquid Primary Glass Indicator
                AnimatedAlign(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutQuart,
                  alignment: Alignment(
                    -1.0 + (selectedRole * (2.0 / (roles.length - 1))),
                    0,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 1 / roles.length,
                    child: AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, child) {
                        // 🌊 Surface tension wobble for liquid feel
                        final double radiusWobble =
                            28 + (2 * cos(_floatController.value * 4 * pi));

                        return Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radiusWobble),
                            gradient: AppColors.primaryButtonGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.loginPrimary.withValues(
                                  alpha: 0.4,
                                ),
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
                                  left:
                                      -100 +
                                      (250 *
                                          (_floatController.value * 1.5 % 1.0)),
                                  child: Transform.rotate(
                                    angle: pi / 4,
                                    child: Container(
                                      width: 25,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.loginSurface.withValues(alpha: 0),
                                            AppColors.loginSurface.withValues(alpha: 0.3),
                                            AppColors.loginSurface.withValues(alpha: 0),
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
                                      color: AppColors.loginSurface.withValues(
                                        alpha: 0.1,
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
                              color: isSelected
                                  ? AppColors.loginAccent
                                  : AppColors.loginSurface.withValues(
                                      alpha: 0.55,
                                    ),
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
            color: AppColors.loginBackground.withValues(alpha: 0.35),
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
              color: AppColors.loginSurface.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(44),
              border: Border.all(
                color: AppColors.loginSurface.withValues(alpha: 0.9),
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
                            color: AppColors.loginBackground.withValues(alpha: 0.08),
                            border: Border(
                              right: BorderSide(
                                color: AppColors.loginBorder.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          child: Center(
                            child: LoginScreenTopImage(
                              selectedRole: selectedRole,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 60,
                            vertical: 60,
                          ),
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
        const Icon(
          Icons.lock_rounded,
          color: AppColors.loginTextMuted,
          size: 14,
        ),
        const SizedBox(width: 10),
        Text(
          "PORTAL IS ENCRYPTED AND SECURE",
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: AppColors.loginTextMuted.withValues(alpha: 0.9),
            letterSpacing: 2,
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
