import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/auth/cubit/auth_cubit.dart';
import 'package:iq_plus/features/auth/cubit/change_password_cubit.dart';
import 'package:iq_plus/features/auth/cubit/customer/customer_cubit.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_cubit.dart';
import 'package:iq_plus/features/customer_mme/repository/customer_mme_repository.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_cubit.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/repository/visitor_summary_repository.dart';
import 'package:iq_plus/features/users/cubit/employee_user_cubit.dart';
import 'package:iq_plus/features/users/repository/user_repository.dart';
import 'package:iq_plus/features/superadmin/repository/document_repository.dart';
import 'package:iq_plus/features/superadmin/cubit/document_cubit.dart';
import 'package:iq_plus/features/videos/repository/video_repository.dart';
import 'package:iq_plus/features/videos/cubit/video_cubit.dart';
import 'package:iq_plus/features/periodic_compliance/repository/periodic_compliance_repository.dart';
import 'package:iq_plus/features/periodic_compliance/cubit/periodic_compliance_cubit.dart';
import 'package:iq_plus/features/kpis/repository/kpi_repository.dart';
import 'package:iq_plus/features/kpis/cubit/kpi_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Firebase
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<UserRepository>(
        () => UserRepository(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<CustomerMMERepository>(
        () => CustomerMMERepository(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<VisitorSummaryRepository>(
        () => VisitorSummaryRepository(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<DocumentRepository>(
        () => DocumentRepository(),
  );
  getIt.registerLazySingleton<VideoRepository>(
        () => VideoRepository(),
  );
  getIt.registerLazySingleton<PeriodicComplianceRepository>(
        () => PeriodicComplianceRepository(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<KpiRepository>(
        () => KpiRepository(getIt<FirebaseFirestore>()),
  );

  // Cubit
  getIt.registerFactory<AuthCubit>(() => AuthCubit(getIt<AuthRepository>()));
  getIt.registerFactory<CustomerCubit>(
    () => CustomerCubit(getIt<AuthRepository>()),
  );
  getIt.registerFactory<CustomerListCubit>(() => CustomerListCubit(getIt()));
  getIt.registerFactory<ConsultantCubit>(() => ConsultantCubit());
  getIt.registerFactory<CustomerPasswordCubit>(
    () => CustomerPasswordCubit(getIt<AuthRepository>()),
  );
  getIt.registerFactory<UserCubit>(
        () => UserCubit(getIt()),
  );
  getIt.registerFactory<CustomerMMECubit >(
        () => CustomerMMECubit (getIt()),
  );

  getIt.registerFactory<VisitorSummaryCubit >(
        () => VisitorSummaryCubit (getIt()),
  );

  getIt.registerFactory<DocumentCubit>(
        () => DocumentCubit(getIt()),
  );

  getIt.registerFactory<VideoCubit>(
        () => VideoCubit(getIt()),
  );

  getIt.registerFactory<PeriodicComplianceCubit>(
        () => PeriodicComplianceCubit(getIt()),
  );

  getIt.registerFactory<KpiCubit>(
        () => KpiCubit(getIt()),
  );

  getIt.registerLazySingleton<HiveService>(() => HiveService());
}
