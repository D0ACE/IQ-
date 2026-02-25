import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/features/admin/model/admin_model.dart';

class AdminListPage extends StatelessWidget {
  const AdminListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admins")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('admins').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No admins found'));
          }

          final admins = snapshot.data!.docs
              .map(
                (doc) =>
                    AdminModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();

          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];

              return ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: Text(admin.userName),
                subtitle: Text(admin.email),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  GoRouter.of(context).push('/admins/${admin.adminId}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
