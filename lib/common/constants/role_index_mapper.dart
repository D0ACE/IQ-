class RoleIndexMapper {
  static String roleIdFromIndex(int index) {
    switch (index) {
      case 0: return '0'; // SuperAdmin
      case 1: return '1'; // Admin
      case 2: return '2'; // Consultant
      case 3: return '3'; // Customer
      default: return '';
    }
  }
}
  