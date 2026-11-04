import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iq_plus/common/themes/app_const.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'providers/rating_provider.dart';
import 'providers/supplier_provider.dart';
import 'repositories/firestore_rating_repository.dart';
import 'repositories/firestore_supplier_repository.dart';

class SupplyManagementShell extends StatelessWidget {
  const SupplyManagementShell({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final user = getIt<HiveService>().getUser();
    final customer = getIt<HiveService>().getCustomer();
    final registeredBy = user?.userId ?? customer?.customerId;
    final role = user?.roleId ?? customer?.roleId ?? AppConst.customerRole;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SupplierProvider(
            repository: FirestoreSupplierRepository(FirebaseFirestore.instance),
            registeredBy: registeredBy,
            registeredByRole: role,
          )..loadSuppliers(),
        ),
        ChangeNotifierProvider(
          create: (_) => RatingProvider(
            repository: FirestoreRatingRepository(FirebaseFirestore.instance),
          ),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: child,
      ),
    );
  }
}
