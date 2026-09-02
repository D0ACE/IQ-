import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/core/access/access_control.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_hierarchy_graph.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';

class CustomerProfilePage extends StatefulWidget {
  final CustomerModel customer;

  const CustomerProfilePage({super.key, required this.customer});

  @override
  State<CustomerProfilePage> createState() => _CustomerDetailViewState();
}

class _CustomerDetailViewState extends State<CustomerProfilePage>
    with TickerProviderStateMixin {
  late CustomerModel customer;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    customer = widget.customer;
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _openEditPage() async {
    final updatedCustomer = await GoRouter.of(context)
        .push<CustomerModel>(AppRoutes.customerEdit, extra: customer);

    if (updatedCustomer != null) {
      setState(() {
        customer = updatedCustomer;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black54),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: const Text(
          "PORTFOLIO",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          if (AccessControl.canEditCustomer(customer))
            IconButton(
              icon: const Icon(Icons.edit_road_rounded, color: AppColors.kPrimaryColor),
              onPressed: _openEditPage,
            ),
        ],
      ),
      body: Stack(
        children: [
          // 🛡️ Geometric Mosaic Background
          _buildGeometricBackground(),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderIdentity(),
                  const SizedBox(height: 32),
                  
                  _sectionLabel("OPERATIONAL METRICS"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMetricBlock(Icons.people_alt_outlined, "WORKFORCE", customer.numberOfEmployees)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricBlock(Icons.account_tree_outlined, "NODES", customer.numberOfLocations)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _sectionLabel("CORE CONFIGURATION"),
                  const SizedBox(height: 12),
                  _buildMosaicPanel(
                    child: Column(
                      children: [
                        _buildMosaicRow(Icons.verified_outlined, "Certification", customer.certificateStandard),
                        const Divider(color: Colors.black12),
                        _buildMosaicRow(Icons.alternate_email_rounded, "Secure Entry", customer.email),
                        const Divider(color: Colors.black12),
                        _buildMosaicRow(Icons.phone_in_talk_outlined, "Telephony", customer.phoneNumber),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionLabel("GEOGRAPHIC BASE"),
                  const SizedBox(height: 12),
                  _buildMosaicPanel(
                    child: _buildMosaicRow(Icons.location_on_outlined, "Headquarters", customer.address),
                  ),

                  if (customer.consultantId != null) ...[
                    const SizedBox(height: 24),
                    _sectionLabel("SYSTEM AUTHORIZATION"),
                    const SizedBox(height: 12),
                    _buildMosaicPanel(
                      child: _buildMosaicRow(Icons.admin_panel_settings_outlined, "Assigned Expert", customer.consultantId!),
                    ),
                  ],

                  const SizedBox(height: 32),
                  _sectionLabel("ORGANIZATIONAL ARCHITECTURE"),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white),
                    ),
                    child: CustomerHierarchyCustom(customer: customer),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeometricBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: GeometricPainter(progress: _bgController.value),
        );
      },
    );
  }

  Widget _buildHeaderIdentity() {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)],
          ),
          child: Center(
            child: Text(
              customer.companyName.isNotEmpty ? customer.companyName[0] : 'C',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w100, color: AppColors.kPrimaryColor),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.companyName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1.1),
              ),
              const SizedBox(height: 4),
              Text(
                "VERIFIED CORPORATE ACCOUNT",
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade300, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2),
    );
  }

  Widget _buildMetricBlock(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.kPrimaryColor, size: 20),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black38)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildMosaicPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMosaicRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey.shade200, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9, color: Colors.black38, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GeometricPainter extends CustomPainter {
  final double progress;
  GeometricPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = Random(42);

    for (int i = 0; i < 8; i++) {
      final hue = (progress * 360 + (i * 45)) % 360;
      paint.color = HSLColor.fromAHSL(0.03, hue, 0.5, 0.5).toColor();
      
      final path = Path();
      final p1 = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
      final p2 = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
      final p3 = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
      
      path.moveTo(p1.dx, p1.p1(p1, progress));
      path.lineTo(p2.dx, p2.p1(p2, progress));
      path.lineTo(p3.dx, p3.p1(p3, progress));
      path.close();
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension OffsetExt on Offset {
  double p1(Offset o, double t) => o.dy + (20 * sin(t * 2 * pi));
}
