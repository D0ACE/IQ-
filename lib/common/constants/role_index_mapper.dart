class RoleIndexMapper {
  static String roleIdFromIndex(int index) {
    switch (index) {
      case 0: return '1'; // Admin
      case 1: return '2'; // Consultant
      case 2: return '3'; // Customer
      case 3: return '0'; // SuperAdmin
      default: return '';
    }
  }
}
