import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';

class HiveService {
  static const userBox = 'userBox';
  static const customerBox = 'customerBox';

  /// USER
  Future<void> saveUser(UserModel user) async {
    try {
      final box = await Hive.openBox<UserModel>(userBox);

      /// Clear previous user session
      await box.clear();

      /// Save new user
      await box.put('user', user);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  UserModel? getUser() {
  try{
    final box = Hive.box<UserModel>(userBox);
    return box.get('user');
  }catch(e){
    print(e);
    return null;
  }
  }

  /// CUSTOMER
  Future<void> saveCustomer(CustomerModel customer) async {
    try {
      final box = await Hive.openBox<CustomerModel>(customerBox);

      /// Clear previous user session
      await box.clear();

      /// Save new user
      await box.put('customer', customer);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }

  CustomerModel? getCustomer() {
    final box = Hive.box<CustomerModel>(customerBox);
    return box.get('customer');
  }

  /// CLEAR ALL
  Future<void> clearAll() async {
    try {
      if (Hive.isBoxOpen(userBox)) {
        await Hive.box<UserModel>(userBox).clear();
      }
      if (Hive.isBoxOpen(customerBox)) {
        await Hive.box<CustomerModel>(customerBox).clear();
      }
    } catch (e) {
      debugPrint('Hive clearAll error: $e');
    }
  }
}
