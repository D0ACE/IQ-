import 'package:iq_plus/common/constants/user_role.dart';
import 'package:iq_plus/common/policy/customer_access_policy.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';

bool canNavigateToCustomerProfile({
  required UserRole role,
  required String currentUserId,
  required CustomerModel customer,
}) {
  return CustomerAccessPolicy.canViewCustomer(
    role: role,
    currentUserId: currentUserId,
    customer: customer,
  );
}
