import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/features/admin/cubit/admin_cubit.dart';
import 'package:iq_plus/features/admin/repository/admin_repository.dart';

class AdminDetailPage extends StatelessWidget {
  final String adminId;

  const AdminDetailPage({super.key, required this.adminId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminCubit(AdminRepository())..fetchAdminById(adminId),
      child: const _AdminDetailView(),
    );
  }
}

class _AdminDetailView extends StatelessWidget {
  const _AdminDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Details')),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminDetailLoaded) {
            final admin = state.admin;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin.userName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(admin.email),
                  const SizedBox(height: 8),
                  Text(admin.phone),
                  const SizedBox(height: 8),
                  Text('Role: ${admin.role}'),
                ],
              ),
            );
          }

          if (state is AdminError) {
            return Center(child: Text(state.message));
          }

          return const Center(child: Text('No admin data found'));
        },
      ),
    );
  }
}
