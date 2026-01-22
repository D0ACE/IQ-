import '../constants/user_role.dart';
import '../../features/auth/model/customer_model.dart';

class CustomerAccessPolicy {
  static bool canViewCustomer({
    required UserRole role,
    required String currentUserId,
    required CustomerModel customer,
  }) {
    switch (role) {
      case UserRole.superAdmin:
      case UserRole.admin:
        return true; // 👑 ALL customers

      case UserRole.consultant:
        return customer.assignedConsultantId == currentUserId;

      case UserRole.customer:
        return customer.customerId == currentUserId;

      default:
        return false;
    }
  }
}
