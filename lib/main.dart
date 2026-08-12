import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iq_plus/common/routes/app.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_cubit.dart';
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_cubit.dart';
import 'package:provider/provider.dart';


import 'package:iq_plus/core/firebase/firebase_options.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/cubit/auth_cubit.dart';
import 'package:iq_plus/features/auth/cubit/customer/customer_cubit.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/ncr_form/ncr_provider.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/superadmin/cubit/document_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iq_plus/core/supabase/supabase_config.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: "sb_publishable_bqQEuQGJf3a4APmqdpsWbQ_9pJlOB2z",
    );

    // 3. Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(CustomerModelAdapter());

    // 4. Open Boxes
    await Hive.openBox<UserModel>('userBox');
    await Hive.openBox<CustomerModel>('customerBox');

    // 5. Setup Service Locator
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
            BlocProvider(create: (_) => getIt<CustomerListCubit>()..fetchCustomers()),
            BlocProvider(create: (_) => getIt<ConsultantCubit>()..fetchConsultants()),
            BlocProvider(create: (_) => getIt<DocumentCubit>()),
          ],
          child: const MyApp(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('❌ Initialization Error: $e');
    debugPrint('Stacktrace: $stackTrace');
  }
}
