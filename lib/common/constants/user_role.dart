enum UserRole {
  superAdmin,
  admin,
  consultant,
  customer,
}

UserRole mapUserRole(String role) {
  switch (role) {
    case 'SUPER_ADMIN':
      return UserRole.superAdmin;
    case 'ADMIN':
      return UserRole.admin;
    case 'CONSULTANT':
      return UserRole.consultant;
    default:
      return UserRole.customer;
  }
}
