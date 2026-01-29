import '../constants/user_role.dart';
import '../../features/auth/model/customer_model.dart';

class CustomerAccessPolicy {
  // View rules
  static bool canViewCustomer({
    required UserRole role,
    required String currentUserId,
    required CustomerModel customer,
  }) {
    switch (role) {
      case UserRole.superAdmin:
      case UserRole.admin:
        return true; // can view all
      case UserRole.consultant:
        return customer.assignedConsultantId == currentUserId;
      case UserRole.customer:
        return customer.customerId == currentUserId;
      default:
        return false;
    }
  }

  // Edit rules
  static bool canEditCustomer({
    required UserRole role,
    required String currentUserId,
    required CustomerModel customer,
  }) {
    switch (role) {
      case UserRole.superAdmin:
      case UserRole.admin:
        return true; // can edit all
      case UserRole.customer:
        return customer.customerId == currentUserId; // can edit own profile
      default:
        return false; // consultants cannot edit
    }
  }
}
