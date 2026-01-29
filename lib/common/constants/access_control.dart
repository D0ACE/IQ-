// lib/common/constants/access_control.dart
import 'package:iq_plus/common/constants/user_role.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/common/policy/customer_access_policy.dart';

class AccessControl {
  // ✅ Check if user can view customer profile
  static bool canViewCustomerProfile({
    required CustomerModel? customer,
    required UserRole role,
    required String userId,
  }) {
    if (customer == null) return false;
    return CustomerAccessPolicy.canViewCustomer(
      role: role,
      currentUserId: userId,
      customer: customer,
    );
  }

  // ✅ Check if user can edit customer profile
  static bool canEditCustomerProfile({
    required CustomerModel? customer,
    required UserRole role,
    required String userId,
  }) {
    if (customer == null) return false;
    return CustomerAccessPolicy.canEditCustomer(
      role: role,
      currentUserId: userId,
      customer: customer,
    );
  }
}
