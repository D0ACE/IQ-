import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';

class AccessControl {
  static bool canViewCustomer(CustomerModel customer) {
    final UserModel? user = getIt<HiveService>().getUser();

    // ❌ Not logged in
    if (user == null) return false;

    // ✅ Super Admin (roleId = 0)
    if (user.roleId == '0') return true;

    // ✅ Customer viewing own profile
    if (user.roleId == '3' && user.userId == customer.customerId) {
      return true;
    }

    // ✅ Assigned Consultant
    if (user.roleId == '2' &&
        user.userId == customer.assignedConsultantId) {
      return true;
    }

    return false;
  }

  static bool canEditCustomer(CustomerModel customer) {
    final UserModel? user = getIt<HiveService>().getUser();

    // ❌ Not logged in
    if (user == null) return false;

    // ✏️ ONLY customer can edit own profile
    return user.roleId == '3' &&
        user.userId == customer.customerId;
  }
}
