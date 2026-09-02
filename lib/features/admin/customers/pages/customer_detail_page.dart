import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_cubit.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_state.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_hierarchy_graph.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:go_router/go_router.dart';

class CustomerDetailPage extends StatefulWidget {
  final CustomerModel customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailViewState();
}

class _CustomerDetailViewState extends State<CustomerDetailPage> {
  String? selectedConsultantId;

  @override
  void initState() {
    super.initState();
    selectedConsultantId = widget.customer.consultantId;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerListCubit, CustomerListState>(
      listener: (context, state) {
        if (state is CustomerListOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          GoRouter.of(context).pop();
        }
        if (state is CustomerListError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.titleText,
          title: const Text(
            'Authorization Terminal',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
          ),
        ),
        body: Stack(
          children: [
            // 🎨 Background Pattern
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DotPatternPainter(
                    dotColor: AppColors.primary.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),

            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("ORGANIZATION IDENTITY"),
                        _buildDetailCard([
                          _buildDetailRow(Icons.business_rounded, "Company Name", widget.customer.companyName),
                          _buildDetailRow(Icons.alternate_email_rounded, "Corporate Email", widget.customer.email),
                          _buildDetailRow(Icons.phone_android_rounded, "Primary Contact", widget.customer.phoneNumber),
                          _buildDetailRow(Icons.location_on_rounded, "Headquarters", widget.customer.address),
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionHeader("COMPLIANCE METRICS"),
                        _buildDetailCard([
                          _buildDetailRow(Icons.verified_rounded, "Standard", widget.customer.certificateStandard),
                          _buildDetailRow(Icons.groups_rounded, "Workforce", widget.customer.numberOfEmployees),
                          _buildDetailRow(Icons.map_rounded, "Nodes", widget.customer.numberOfLocations),
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionHeader("SYSTEM AUTHORIZATION"),
                        _buildDetailCard([
                           BlocBuilder<ConsultantCubit, ConsultantState>(
                            builder: (context, state) {
                              if (state is ConsultantLoading) {
                                return const LinearProgressIndicator();
                              }

                              if (state is ConsultantLoaded) {
                                return DropdownButtonFormField<String>(
                                  initialValue: selectedConsultantId,
                                  decoration: InputDecoration(
                                    labelText: 'Designated Consultant',
                                    labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                    border: InputBorder.none,
                                    prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                                  ),
                                  items: state.consultants.map((consultant) {
                                    return DropdownMenuItem<String>(
                                      value: consultant.id,
                                      child: Text(consultant.userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                  onChanged: widget.customer.isProfileApproved 
                                      ? null 
                                      : (value) => setState(() => selectedConsultantId = value),
                                );
                              }
                              return const Text("Consultants unavailable");
                            },
                          ),
                        ]),

                        const SizedBox(height: 32),
                        _buildSectionHeader("STRUCTURAL ARCHITECTURE"),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))
                            ],
                          ),
                          child: CustomerHierarchyCustom(customer: widget.customer),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                /// APPROVE BUTTON
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -10))
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.customer.isProfileApproved ? Colors.green : AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: widget.customer.isProfileApproved
                          ? null
                          : () async {
                              if ((selectedConsultantId ?? "").isNotEmpty) {
                                await context.read<CustomerListCubit>().approveCustomer(
                                      customerId: widget.customer.customerId,
                                      companyName: widget.customer.companyName,
                                      customerEmail: widget.customer.email,
                                      consultantId: selectedConsultantId ?? '',
                                    );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please select consultant first.")),
                                );
                              }
                            },
                      child: Text(
                        widget.customer.isProfileApproved ? 'IDENTITY VERIFIED' : 'AUTHORIZE ENTERPRISE',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, color: AppColors.titleText, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color dotColor;
  _DotPatternPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 30.0;
    final paint = Paint()
      ..color = dotColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final List<Offset> points = [];
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        points.add(Offset(x, y));
      }
    }
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
