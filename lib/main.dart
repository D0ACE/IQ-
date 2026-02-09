import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iq_plus/common/routes/app.dart';
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_cubit.dart';
import 'package:provider/provider.dart';


import 'package:iq_plus/core/firebase/firebase_options.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/cubit/auth_cubit.dart';
import 'package:iq_plus/features/auth/cubit/customer/customer_cubit.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/ncr_form/ncr_provider.dart';

import 'features/dashboard/page/visit_summary/cubit/visitor_summary_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🟢 Register Hive adapters
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(CustomerModelAdapter());

  // 🟢 Initialize Hive for Flutter
  await Hive.initFlutter();

  // 🟢 Open boxes before using them
  await Hive.openBox<UserModel>('userBox');          // for storing UserModel
  await Hive.openBox<CustomerModel>('customerBox');  // for storing CustomerModel

  await setupServiceLocator();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NcrProvider()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<AuthCubit>()),
          BlocProvider(create: (_) => getIt<CustomerCubit>()),
          BlocProvider(create: (_) => getIt<CustomerMMECubit>()),
          BlocProvider(create: (_) => getIt<VisitorSummaryCubit>()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}
