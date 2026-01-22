import 'package:flutter/material.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';

class CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // ✅ NAVIGATION (NOT DROPDOWN)
      child: Card(
        margin: const EdgeInsets.all(12),
        child: ListTile(
          leading: CircleAvatar(
            child: Text(customer.companyName[0].toUpperCase()),
          ),
          title: Text(customer.companyName),
          subtitle: Text(customer.email),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}
