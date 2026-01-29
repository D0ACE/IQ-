

import 'package:iq_plus/common/constants/user_role.dart' as HelperRole;

HelperRole.UserRole parseUserRole(String roleId) {
  switch (roleId.toLowerCase()) {
    case 'superadmin':
      return HelperRole.UserRole.superAdmin;
    case 'admin':
      return HelperRole.UserRole.admin;
    case 'consultant':
      return HelperRole.UserRole.consultant;
    case 'customer':
      return HelperRole.UserRole.customer;
    default:
      return HelperRole.UserRole.customer; // fallback
  }
}
