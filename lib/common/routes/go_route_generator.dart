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
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_cubit.dart';
import 'package:iq_plus/features/customer_mme/pages/customer_mme_form_page.dart';
import 'package:iq_plus/features/customer_mme/pages/customer_mme_list_page.dart';
import 'package:iq_plus/features/dashboard/page/admin_dashbaord_page.dart';
import 'package:iq_plus/features/dashboard/page/consultant_dashbaord_page.dart';
import 'package:iq_plus/features/dashboard/page/contact_us_page.dart';
import 'package:iq_plus/features/dashboard/page/customer_dashbaord_page.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/pages/visitor_summary_list_page.dart';
import 'package:iq_plus/features/superadmin/pages/superAdmin_dashboard.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_cubit.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/visit_summary_page.dart';
import 'package:iq_plus/features/users/cubit/employee_user_cubit.dart';
import 'package:iq_plus/features/users/pages/employe_user_list_page.dart';
import 'package:iq_plus/ncr_form/ncr_form_page.dart';
import 'package:iq_plus/ncr_form/ncr_page.dart';

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
          final customer = state.extra as CustomerModel;

          return BlocProvider.value(
            value: context.read<CustomerCubit>(),
            child: CustomerOnboardingPage(
              mode: OnboardingMode.approve,
              customer: customer,
            ),
          );
        },
      ),

      /// CUSTOMER DASHBOARDGoRoute(
      GoRoute(
        path: AppRoutes.customerDashboard,
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => getIt<CustomerMMECubit>()),
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

          return BlocProvider(
            create: (_) => getIt<CustomerCubit>(),
            child: CustomerOnboardingPage(mode: mode),
          );
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
          final consultantId = state.extra as String;
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
          final customer = state.extra as CustomerModel;

          return CustomerProfilePage(customer: customer);
        },
      ),

      GoRoute(
        path: AppRoutes.customerProfileEdit,
        builder: (context, state) {
          final customer = state.extra as CustomerModel;
          return CustomerProfileEditPage(customer: customer);
        },
      ),

      GoRoute(
        path: AppRoutes.NCRFormPage,
        builder: (context, state) => const NCRFormPage(),
      ),

      /// CUSTOMER MME
      GoRoute(
        path: AppRoutes.customerMMEList,
        builder: (context, state) {
          final customer = state.extra as String;
          return BlocProvider(
            create: (_) => getIt<CustomerMMECubit>(),
            child: CustomerMMEListPage(customerId: customer),
          );
        },
      ),

      /// CustomerMMEFormPage
      GoRoute(
        path: AppRoutes.customerMMEForm,
        builder: (context, state) {
          final customer = state.extra as String;
          return BlocProvider(
            create: (_) => getIt<CustomerMMECubit>(),
            child: CustomerMMEFormPage(customerId: customer),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.superAdminDashboard,
        builder: (context, state) {
          return BlocProvider<CustomerListCubit>(
            create: (_) =>
                CustomerListCubit(getIt<AuthRepository>())..fetchCustomers(),
            child: SuperadminDashboardPage(),
          );
        },
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
          final consultantId = state.extra as String;
          return BlocProvider(
            create: (_) =>
                getIt<CustomerListCubit>()..fetchAssignCustomers(consultantId),
            child: AssignCustomersPage(consultantId: consultantId),
          );
        },
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.toString()}')),
    ),
  );
}
