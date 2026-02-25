import 'package:flutter/material.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';

class CustomerHierarchyCustom extends StatelessWidget {
  final CustomerModel customer;

  const CustomerHierarchyCustom({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _node(
            title: "Top Level Department",
            name: customer.topLevelName,
            email: customer.topLevelEmail,
            mobile: customer.topLevelMobile,
            color: Colors.redAccent,
          ),

          _verticalLine(),

          _node(
            title: "Medium Level Department",
            name: customer.mediumLevelName,
            email: customer.mediumLevelEmail,
            mobile: customer.mediumLevelMobile,
            color: Colors.orangeAccent,
          ),

          _verticalLine(),

          _node(
            title: "Low Level Department",
            name: customer.lowLevelName,
            email: customer.lowLevelEmail,
            mobile: customer.lowLevelMobile,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  /// ✅ Vertical connector ONLY between cards
  Widget _verticalLine() {
    return Container(
      width: 2,
      height: 40,
      color: Colors.grey.shade400,
    );
  }

  Widget _node({
    required String title,
    required String name,
    required String email,
    required String mobile,
    required Color color,
  }) {
    return Container(
      width: 260,
     // constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha:0.4)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          _row("Name", name),
          _row("Email", email),
          _row("Mobile", mobile),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            value.isEmpty ? "-" : value,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
