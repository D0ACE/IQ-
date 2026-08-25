import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/create_admin/create_admin_page.dart';
import 'package:iq_plus/features/admin/customers/pages/assign_customers_page.dart';
import 'package:iq_plus/features/admin/customers/pages/customer_detail_page.dart';
import 'package:iq_plus/features/admin/customers/pages/customer_list_page.dart';
import 'package:iq_plus/features/admin/customers/pages/customer_profile_edit_page.dart';
import 'package:iq_plus/features/admin/customers/pages/customer_profile_page.dart';
import 'package:iq_plus/features/admin/pages/admin_detail_page.dart';
import 'package:iq_plus/features/admin/pages/admin_list_page.dart';
import 'package:iq_plus/features/admin/pages/admin_profile_page.dart';
import 'package:iq_plus/features/auth/Login/login_page.dart';
import 'package:iq_plus/features/auth/cubit/customer/customer_cubit.dart';
import 'package:iq_plus/features/auth/customer_onboarding/onboarding_mode.dart';
import 'package:iq_plus/features/auth/customer_onboarding/onboarding_request_page.dart';
import 'package:iq_plus/features/auth/customer_onboarding/page/customer_onboarding_page.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_cubit.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';
import 'package:iq_plus/features/chatbot/chat_screen.dart';
import 'package:iq_plus/features/consultant/consultant_profile_page.dart';
import 'package:iq_plus/features/customer_mme/pages/customer_mme_form_page.dart';
import 'package:iq_plus/features/customer_mme/pages/customer_mme_list_page.dart';
import 'package:iq_plus/features/dashboard/page/admin_dashbaord_page.dart';
import 'package:iq_plus/features/dashboard/page/consultant_dashbaord_page.dart';
import 'package:iq_plus/features/dashboard/page/contact_us_page.dart';
import 'package:iq_plus/features/dashboard/page/customer_dashbaord_page.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/pages/visitor_summary_list_page.dart';
import 'package:iq_plus/features/superadmin/pages/super_admin_dashboard.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_cubit.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/visit_summary_page.dart';
import 'package:iq_plus/features/users/cubit/employee_user_cubit.dart';
import 'package:iq_plus/features/users/pages/employe_user_list_page.dart';
import 'package:iq_plus/ncr_form/ncr_form_page.dart';
import 'package:iq_plus/ncr_form/ncr_page.dart';
import 'package:iq_plus/features/superadmin/pages/document_editor_page.dart';
import 'package:iq_plus/features/superadmin/pages/document_list_page.dart';
import 'package:iq_plus/features/superadmin/pages/document_add_edit_page.dart';
import 'package:iq_plus/features/superadmin/pages/excel_editor_page.dart';
import 'package:iq_plus/features/customer_policies/pages/customer_policy_list_page.dart';
import 'package:iq_plus/features/customer_policies/pages/customer_policy_detail_page.dart';
import 'package:iq_plus/features/superadmin/models/document_model.dart';
import 'package:iq_plus/features/superadmin/pages/history/global_version_history_page.dart';
import 'package:iq_plus/features/consultant/pages/add_employee_page.dart';
import 'package:iq_plus/features/users/repository/user_repository.dart';
import 'package:iq_plus/features/dashboard/page/employee_dashbaord_page.dart';
import 'package:iq_plus/features/users/pages/employee_list_page.dart';
import 'package:iq_plus/features/videos/cubit/video_cubit.dart';
import 'package:iq_plus/features/videos/repository/video_repository.dart';
import 'package:iq_plus/features/videos/models/video_model.dart';
import 'package:iq_plus/features/videos/pages/video_list_page.dart';
import 'package:iq_plus/features/videos/pages/video_upload_page.dart';
import 'package:iq_plus/features/videos/pages/video_quiz_page.dart';
import 'package:iq_plus/features/videos/pages/video_player_page.dart';
import 'package:iq_plus/features/videos/pages/video_details_page.dart';
import 'package:iq_plus/features/videos/pages/employee_training_page.dart';
import 'package:iq_plus/features/videos/pages/training_results_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login, // ✅ REQUIRED

    routes: [
      /// 🔐 LOGIN
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),

      /// 👤 CUSTOMER DETAIL
      GoRoute(
        path: AppRoutes.customerDetail,
        builder: (context, state) {
          final customer = state.extra as CustomerModel?;

          if (customer == null) {
            return const Scaffold(
              body: Center(child: Text('Customer data missing')),
            );
          }

          return MultiBlocProvider(
            providers: [
              BlocProvider<CustomerListCubit>(
                create: (_) => CustomerListCubit(getIt<AuthRepository>()),
              ),
              BlocProvider<ConsultantCubit>(
                create: (_) => getIt<ConsultantCubit>()..fetchConsultants(),
              ),
            ],
            child: CustomerDetailPage(customer: customer),
          );
        },
      ),

      /// ✏️ CUSTOMER EDIT
      GoRoute(
        path: AppRoutes.customerEdit,
        builder: (context, state) {
          final customer = state.extra as CustomerModel?;

          if (customer == null) {
            return const Scaffold(
              body: Center(child: Text('Customer data missing')),
            );
          }

          return CustomerProfileEditPage(customer: customer);
        },
      ),

      GoRoute(
        path: '/customer-onboarding',
        name: 'customerOnboarding',
        builder: (context, state) {
          final customer = state.extra as CustomerModel?;

          if (customer == null) {
            return const Scaffold(
              body: Center(child: Text('Error: Customer data is missing.')),
            );
          }

          return CustomerOnboardingPage(
            mode: OnboardingMode.approve,
            customer: customer,
          );
        },
      ),

      /// CUSTOMER DASHBOARDGoRoute(
      GoRoute(
        path: AppRoutes.customerDashboard,
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => getIt<VisitorSummaryCubit>()),
            ],
            child: DashboardPage(),
          );
        },
      ),

      /// ADMIN DASHBOARD
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardPage(),
      ),

      /// CONSULTANT DASHBOARD
      GoRoute(
        path: AppRoutes.consultantDashboard,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => getIt<CustomerListCubit>()..fetchCustomers(),
            ),
          ],
          child: const ConsultantDashboardPage(),
        ),
      ),

      GoRoute(
        path: AppRoutes.customerOnboarding,
        builder: (context, state) {
          final mode = state.extra as OnboardingMode? ?? OnboardingMode.create;

          return CustomerOnboardingPage(mode: mode);
        },
      ),
      GoRoute(
        path: AppRoutes.adminProfile,
        builder: (context, state) => const AdminProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.onboardingRequest,
        builder: (context, state) => const OnboardingRequestPage(),
      ),
      GoRoute(
        path: AppRoutes.customerList,
        builder: (context, state) => const CustomerListPage(),
      ),
      GoRoute(
        path: AppRoutes.employeeList,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<UserCubit>()..loadUsers(),
          child: const UserListPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.contactUs,
        builder: (context, state) => const ContactUsPage(),
      ),
      GoRoute(
        path: AppRoutes.ncrPage,
        builder: (context, state) => const NcrPage(),
      ),
      // GoRoute(
      //   path: AppRoutes.consultantProfile,
      //   builder: (context, state) => const ConsultantProfilePage(),
      // ),
      GoRoute(
        path: AppRoutes.consultantProfile,
        builder: (context, state) {
          final consultantId = state.extra as String?;
          if (consultantId == null) {
             return const Scaffold(
               body: Center(child: Text('Error: Consultant ID is missing.')),
             );
          }
          return ConsultantProfilePage(consultantId: consultantId);
        },
      ),

      /// Visitor summary listing
      GoRoute(
        path: AppRoutes.visitorSummaryList,
        builder: (context, state) {
          return VisitorSummaryListPage();
        },
      ),
      GoRoute(
        path: AppRoutes.visitorSummary,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;

          return VisitorSummaryPage(
            visitorSummaryModel: args?['visitorSummaryModel'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.contactUs,
        builder: (context, state) => const ContactUsPage(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => const ChatScreen(), // your chat page
      ),
      GoRoute(
        path: AppRoutes.customerProfile,
        builder: (context, state) {
          final customer = state.extra as CustomerModel?;
          if (customer == null) {
            return const Scaffold(
              body: Center(child: Text('Error: Customer data is missing.')),
            );
          }
          return CustomerProfilePage(customer: customer);
        },
      ),

      GoRoute(
        path: AppRoutes.customerProfileEdit,
        builder: (context, state) {
          final customer = state.extra as CustomerModel?;
          if (customer == null) {
            return const Scaffold(
              body: Center(child: Text('Error: Customer data is missing.')),
            );
          }
          return CustomerProfileEditPage(customer: customer);
        },
      ),

      GoRoute(
        path: AppRoutes.nCRFormPage,
        builder: (context, state) => const NCRFormPage(),
      ),

      /// CUSTOMER MME
      GoRoute(
        path: AppRoutes.customerMMEList,
        builder: (context, state) {
          final customer = state.extra as String?;
          if (customer == null) {
            return const Scaffold(
              body: Center(child: Text('Error: Customer ID is missing.')),
            );
          }
          return CustomerMMEListPage(customerId: customer);
        },
      ),

      /// CustomerMMEFormPage
      GoRoute(
        path: AppRoutes.customerMMEForm,
        builder: (context, state) {
          final extra = state.extra as Map?;
          return CustomerMMEFormPage(
            customerId: extra?['customerId'],
            mme: extra?['mme'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.superAdminDashboard,
        builder: (context, state) => const SuperadminDashboardPage(),
      ),
      GoRoute(
        path: '/create-admin',
        builder: (context, state) => const CreateAdminPage(),
      ),

      /// 🔹 Admin list
      GoRoute(
        path: '/admins',
        builder: (context, state) => const AdminListPage(),
      ),

      /// 🔹 Admin detail (IMPORTANT)
      GoRoute(
        path: AppRoutes.adminDetail,
        builder: (context, state) {
          final adminId = state.pathParameters['adminId']!;
          return AdminDetailPage(adminId: adminId);
        },
      ),

      /// 🔹 Admin detail (IMPORTANT)
      GoRoute(
        path: AppRoutes.assignCustomers,
        builder: (context, state) {
          final consultantId = state.extra as String?;
          if (consultantId == null) {
            return const Scaffold(
              body: Center(child: Text('Error: Consultant ID is missing.')),
            );
          }
          return BlocProvider(
            create: (_) =>
                getIt<CustomerListCubit>()..fetchAssignCustomers(consultantId),
            child: AssignCustomersPage(consultantId: consultantId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.documentEditor,
        builder: (context, state) {
          final doc = state.extra as DocumentModel?;
          return DocumentEditorPage(
            document: doc,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.documentList,
        builder: (context, state) => const DocumentListPage(),
      ),
      GoRoute(
        path: AppRoutes.documentAddEdit,
        builder: (context, state) {
          final doc = state.extra as DocumentModel?;
          return DocumentAddEditPage(document: doc);
        },
      ),
      GoRoute(
        path: AppRoutes.excelEditor,
        builder: (context, state) {
          final doc = state.extra as DocumentModel?;
          return ExcelEditorPage(document: doc);
        },
      ),
      GoRoute(
        path: AppRoutes.customerPolicyList,
        builder: (context, state) => const CustomerPolicyListPage(),
      ),
      GoRoute(
        path: AppRoutes.customerPolicyDetail,
        builder: (context, state) {
          final doc = state.extra as DocumentModel;
          return CustomerPolicyDetailPage(document: doc);
        },
      ),
      GoRoute(
        path: AppRoutes.globalVersionHistory,
        builder: (context, state) => const GlobalVersionHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.addEmployee,
        builder: (context, state) => BlocProvider(
          create: (_) => UserCubit(getIt<UserRepository>()),
          child: const AddEmployeePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.employeeDashboard,
        builder: (context, state) => const EmployeeDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.employeeListing,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => UserCubit(getIt<UserRepository>())),
            BlocProvider(create: (_) => CustomerListCubit(getIt<AuthRepository>())),
          ],
          child: const EmployeeListPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.videoList,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => VideoCubit(getIt<VideoRepository>())),
            BlocProvider(create: (_) => CustomerListCubit(getIt<AuthRepository>())),
          ],
          child: const VideoListPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.videoUpload,
        builder: (context, state) => BlocProvider(
          create: (_) => VideoCubit(getIt<VideoRepository>()),
          child: const VideoUploadPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.videoQuiz,
        builder: (context, state) => BlocProvider(
          create: (_) => VideoCubit(getIt<VideoRepository>()),
          child: VideoQuizPage(video: state.extra as AwarenessVideoModel),
        ),
      ),
      GoRoute(
        path: AppRoutes.videoPlayer,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return VideoPlayerPage(
            videoUrl: extra['videoUrl'],
            title: extra['title'],
            onVideoEnd: extra['onVideoEnd'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.videoDetails,
        builder: (context, state) => VideoDetailsPage(video: state.extra as AwarenessVideoModel),
      ),
      GoRoute(
        path: AppRoutes.employeeTraining,
        builder: (context, state) => BlocProvider(
          create: (_) => VideoCubit(getIt<VideoRepository>()),
          child: const EmployeeTrainingPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.trainingResults,
        builder: (context, state) {
          final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
          return BlocProvider(
            create: (_) => VideoCubit(getIt<VideoRepository>()),
            child: TrainingResultsPage(
              userId: extra?['userId'],
              userName: extra?['userName'],
              customerId: extra?['customerId'], // 🚀 Pass customerId from extra
            ),
          );
        },
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.toString()}')),
    ),
  );
}
