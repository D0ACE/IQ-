import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:iq_plus/common/themes/app_const.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/email_services/email_service.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/role_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/features/auth/model/consultant_user_model.dart';

class AuthRepository {
  final FirebaseFirestore firestore;

  AuthRepository(this.firestore);

  /// USER SIGNUP
  Future<void> createUser(Map<String, dynamic> data) async {
    await firestore.collection('users').add({
      ...data,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// CUSTOMER SIGNUP
  Future<void> createCustomer(CustomerModel customer) async {
    // 1️⃣ Check if email already exists
    final existing = await firestore
        .collection('customers')
        .where('email', isEqualTo: customer.email)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception("Email already registered");
    }

    try {
      // 1️⃣ Create customer in Firestore
      final docRef = await firestore.collection('customers').add({
        "companyName": customer.companyName,
        "email": customer.email,
        "phoneNumber": customer.phoneNumber,
        "password": customer.password,
        "certificateStandard": customer.certificateStandard,
        "numberOfLocations": customer.numberOfLocations,
        "numberOfEmployees": customer.numberOfEmployees,
        "companyFunction": customer.companyFunction,
        "legitDocumentUrl": customer.legitDocumentUrl,
        "isProfileApproved": customer.isProfileApproved,
        "fcmToken": customer.fcmToken,
        "roleId": customer.roleId,
        "address": customer.address,
        "lowLevelDepartment": {
          "name": customer.lowLevelName,
          "email": customer.lowLevelEmail,
          "mobile": customer.lowLevelMobile,
        },
        "mediumLevelDepartment": {
          "name": customer.mediumLevelName,
          "email": customer.mediumLevelEmail,
          "mobile": customer.mediumLevelMobile,
        },
        "topLevelDepartment": {
          "name": customer.topLevelName,
          "email": customer.topLevelEmail,
          "mobile": customer.topLevelMobile,
        },
        "createdAt": FieldValue.serverTimestamp(),
      });

      // ✅ Firestore success confirmed
      if (docRef.id.isNotEmpty) {
        // 2️⃣ Send email (DO NOT block user if email fails)
        await BrevoEmailService.sendCustomerCreatedMail(
          companyName: customer.companyName,
          email: customer.email,
        );
      }
    } catch (e) {
      debugPrint("Create customer error: $e");
      rethrow;
    }
  }

  /// LOGIN (Firestore based)
  Future<RoleModel> login(String email, String password,int selectedRole) async {
    final hiveService = getIt<HiveService>();
    final userQuery = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      final doc = userQuery.docs.first;
      final data = doc.data();

      if (data['blockStatus'] == true) {
        throw Exception("Your account is blocked");
      }

      // if (data['activeUser'] != true) {
      //   throw Exception("Your account is inactive");
      // }
      await hiveService.saveUser(
        UserModel(
          userId: doc.id,
          userName: data['userName'],
          email: data['email'],
          phoneNumber: data['phoneNumber'],
          password: data['password'],
          roleId: data['roleId'],
          activeUser: data['activeUser'],
          blockStatus: data['blockStatus'],
          fcmToken: data['fcmToken'],
          createdAt: data['createdAt'].toDate(),
        ),
      );

      return RoleModel(id: data['roleId'].toString(),name:data['userName'] );
    }

    final customerQuery = await firestore
        .collection('customers')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (customerQuery.docs.isNotEmpty) {
      final doc = customerQuery.docs.first;
      final data = doc.data();
      final approved = customerQuery.docs.first['isProfileApproved'] as bool;

      if (!approved) {
        throw Exception("Profile not approved by admin");
      }
      await hiveService.saveCustomer(
        CustomerModel(
          customerId: doc.id,
          companyName: data['companyName'] ?? "",
          email: data['email'] ?? '',
          phoneNumber: data['phoneNumber'] ?? "",
          password: data['password'] ?? "",
          certificateStandard: data['certificateStandard'] ?? "",
          numberOfLocations: data['numberOfLocations'] ?? "0",
          numberOfEmployees: data['numberOfEmployees'] ?? "0",
          companyFunction: data['companyFunction'] ?? '',
          legitDocumentUrl: data['legitDocumentUrl'] ?? '',
          isProfileApproved: data['isProfileApproved'] ?? "",
          fcmToken: data['fcmToken'] ?? '',
          roleId: data['roleId'] ?? '',
          createdAt: data['createdAt'].toDate(),
          address: data['address'] ?? '',
          // 🔽 LOW LEVEL DEPARTMENT
          lowLevelName: data['lowLevelDepartment']?['name'] ?? '',
          lowLevelEmail: data['lowLevelDepartment']?['email'] ?? '',
          lowLevelMobile: data['lowLevelDepartment']?['mobile'] ?? '',

          // 🔶 MEDIUM LEVEL DEPARTMENT
          mediumLevelName: data['mediumLevelDepartment']?['name'] ?? '',
          mediumLevelEmail: data['mediumLevelDepartment']?['email'] ?? '',
          mediumLevelMobile: data['mediumLevelDepartment']?['mobile'] ?? '',

          // 🔺 TOP LEVEL DEPARTMENT
          topLevelName: data['topLevelDepartment']?['name'] ?? '',
          topLevelEmail: data['topLevelDepartment']?['email'] ?? '',
          topLevelMobile: data['topLevelDepartment']?['mobile'] ?? '',
        ),
      );
      if ((data['password']??"").startsWith(AppConst.autoGeneratedPasswordBase)) {
        return  RoleModel(id:doc.id,name: AppConst.isAutoGeneratedPassCustomer );
      }else{
        return RoleModel(id:doc.id,name: AppConst.isCustomer );
      }
    }

    throw Exception("Invalid email or password");
  }

  /// GET ALL CUSTOMERS
  Future<List<CustomerModel>> getAllCustomers() async {
    final snapshot = await firestore
        .collection('customers')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CustomerModel(
        customerId: doc.id,
        companyName: data['companyName'] ?? '',
        email: data['email'] ?? '',
        phoneNumber: data['phoneNumber'] ?? '',
        password: data['password'] ?? '',
        certificateStandard: data['certificateStandard'] ?? '',
        numberOfLocations: data['numberOfLocations'] ?? '',
        numberOfEmployees: data['numberOfEmployees'] ?? '',
        companyFunction: data['companyFunction'] ?? '',
        legitDocumentUrl: data['legitDocumentUrl'] ?? '',
        isProfileApproved: data['isProfileApproved'] ?? false,
        fcmToken: data['fcmToken'] ?? '',
        roleId: data['roleId'] ?? '',
        createdAt: data['createdAt'].toDate(),
        address: data['address'] ?? '',
        // 🔽 LOW LEVEL DEPARTMENT
        lowLevelName: data['lowLevelDepartment']?['name'] ?? '',
        lowLevelEmail: data['lowLevelDepartment']?['email'] ?? '',
        lowLevelMobile: data['lowLevelDepartment']?['mobile'] ?? '',

        // 🔶 MEDIUM LEVEL DEPARTMENT
        mediumLevelName: data['mediumLevelDepartment']?['name'] ?? '',
        mediumLevelEmail: data['mediumLevelDepartment']?['email'] ?? '',
        mediumLevelMobile: data['mediumLevelDepartment']?['mobile'] ?? '',

        // 🔺 TOP LEVEL DEPARTMENT
        topLevelName: data['topLevelDepartment']?['name'] ?? '',
        topLevelEmail: data['topLevelDepartment']?['email'] ?? '',
        topLevelMobile: data['topLevelDepartment']?['mobile'] ?? '',
      );
    }).toList();
  }

  /// APPROVE CUSTOMER
  Future<void> approveCustomer({required String customerId,required String companyName,required String customerEmail,required String consultantId,}) async {
    final hiveService = getIt<HiveService>();
    UserModel? adminUserModel=hiveService.getUser();
    ConsultantUserModel consultantUserModel=await getConsultantById(consultantId);
    final autoGeneratePassword = Utility.autoGeneratePassword();
    await firestore.collection('customers').doc(customerId).update({
      "isProfileApproved": true,
      "password": autoGeneratePassword,
      "approvedByUserId": adminUserModel?.userId,
      "consultantId": consultantUserModel.userId,
      "approvedAt": FieldValue.serverTimestamp(),
    });
    // Send approval email
    await BrevoEmailService.sendCustomerApprovedMail(
      companyName: companyName,
      email: customerEmail,
      password: autoGeneratePassword,
    );
  }

  Future<ConsultantUserModel> getConsultantById(String consultantId) async {
    final doc =
    await firestore.collection('users').doc(consultantId).get();

    if (!doc.exists) {
      throw Exception("Consultant not found");
    }

    final data = doc.data()!;

    if (data['roleId'] != '2') {
      throw Exception("User is not a consultant");
    }

    return ConsultantUserModel.fromFirestore(doc.id, data);
  }

  Future<void> updateCustomerPassword({
    required String customerId,
    required String newPassword,
  }) async {
    await firestore.collection('customers').doc(customerId).update({
      "password": newPassword,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }
}

