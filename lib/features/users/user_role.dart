

import 'package:iq_plus/common/constants/user_role.dart' as helper_role;

helper_role.UserRole parseUserRole(String roleId) {
  switch (roleId.toLowerCase()) {
    case 'superadmin':
      return helper_role.UserRole.superAdmin;
    case 'admin':
      return helper_role.UserRole.admin;
    case 'consultant':
      return helper_role.UserRole.consultant;
    case 'customer':
      return helper_role.UserRole.customer;
    default:
      return helper_role.UserRole.customer; // fallback
  }
}
