// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// Future<void> createAdmin(String email, String password) async {
//   final userCredential =
//       await FirebaseAuth.instance.createUserWithEmailAndPassword(
//     email: email,
//     password: password,
//   );

//   await FirebaseFirestore.instance
//       .collection('users')
//       .doc(userCredential.user!.uid)
//       .set({
//     'email': email,
//     'role': 'ADMIN',
//     'createdAt': FieldValue.serverTimestamp(),
//   });
// }
