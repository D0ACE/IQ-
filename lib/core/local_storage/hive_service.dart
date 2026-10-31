import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:universal_html/html.dart' as html;

class HiveService {
  static const defaultUserBox = 'userBox';
  static const defaultCustomerBox = 'customerBox';

  String get _tabSessionId {
    if (kIsWeb) {
      try {
        var sessionId = html.window.sessionStorage['tab_session_id'];
        if (sessionId == null || sessionId.isEmpty) {
          sessionId = DateTime.now().microsecondsSinceEpoch.toString();
          html.window.sessionStorage['tab_session_id'] = sessionId;
          html.window.sessionStorage['is_logged_in_tab'] = 'true';
        }
        return sessionId;
      } catch (e) {
        debugPrint('SessionStorage get/set error: $e');
        return 'default';
      }
    }
    return 'default';
  }

  String get userBox => kIsWeb ? 'userBox_$_tabSessionId' : defaultUserBox;
  String get customerBox => kIsWeb ? 'customerBox_$_tabSessionId' : defaultCustomerBox;

  Future<void> initSessionBoxes() async {
    try {
      final sessionId = _tabSessionId;
      final uBox = kIsWeb ? 'userBox_$sessionId' : defaultUserBox;
      final cBox = kIsWeb ? 'customerBox_$sessionId' : defaultCustomerBox;

      if (!Hive.isBoxOpen(uBox)) {
        await Hive.openBox<UserModel>(uBox);
      }
      if (!Hive.isBoxOpen(cBox)) {
        await Hive.openBox<CustomerModel>(cBox);
      }
    } catch (e) {
      debugPrint('initSessionBoxes error: $e');
    }
  }

  /// Mark tab session active in sessionStorage on web
  void setTabSessionActive() {
    if (kIsWeb) {
      try {
        html.window.sessionStorage['is_logged_in_tab'] = 'true';
        _tabSessionId; // ensure ID exists
      } catch (e) {
        debugPrint('SessionStorage set error: $e');
      }
    }
  }

  /// Check if the current browser tab has an active session
  bool isTabSessionActive() {
    if (kIsWeb) {
      try {
        return html.window.sessionStorage['is_logged_in_tab'] == 'true' &&
            html.window.sessionStorage['tab_session_id'] != null;
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  /// USER
  Future<void> saveUser(UserModel user) async {
    try {
      setTabSessionActive();
      await initSessionBoxes();
      final box = Hive.box<UserModel>(userBox);

      /// Clear previous user session
      await box.clear();

      /// Save new user
      await box.put('user', user);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  UserModel? getUser() {
    if (!isTabSessionActive()) return null;
    try {
      if (!Hive.isBoxOpen(userBox)) {
        return null;
      }
      final box = Hive.box<UserModel>(userBox);
      return box.get('user');
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }

  /// CUSTOMER
  Future<void> saveCustomer(CustomerModel customer) async {
    try {
      setTabSessionActive();
      await initSessionBoxes();
      final box = Hive.box<CustomerModel>(customerBox);

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
    if (!isTabSessionActive()) return null;
    try {
      if (!Hive.isBoxOpen(customerBox)) {
        return null;
      }
      final box = Hive.box<CustomerModel>(customerBox);
      return box.get('customer');
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }

  /// CLEAR ALL
  Future<void> clearAll() async {
    try {
      if (kIsWeb) {
        try {
          final sessionId = html.window.sessionStorage['tab_session_id'];
          if (sessionId != null) {
            final uBox = 'userBox_$sessionId';
            final cBox = 'customerBox_$sessionId';
            if (Hive.isBoxOpen(uBox)) {
              await Hive.box<UserModel>(uBox).clear();
            }
            if (Hive.isBoxOpen(cBox)) {
              await Hive.box<CustomerModel>(cBox).clear();
            }
          }
          html.window.sessionStorage.remove('is_logged_in_tab');
          html.window.sessionStorage.remove('tab_session_id');
        } catch (e) {
          debugPrint('SessionStorage clear error: $e');
        }
      }
      if (Hive.isBoxOpen(defaultUserBox)) {
        await Hive.box<UserModel>(defaultUserBox).clear();
      }
      if (Hive.isBoxOpen(defaultCustomerBox)) {
        await Hive.box<CustomerModel>(defaultCustomerBox).clear();
      }
    } catch (e) {
      debugPrint('Hive clearAll error: $e');
    }
  }
}
