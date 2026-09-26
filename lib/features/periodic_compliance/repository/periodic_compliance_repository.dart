import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/periodic_compliance_model.dart';

class PeriodicComplianceRepository {
  final FirebaseFirestore _firestore;

  PeriodicComplianceRepository(this._firestore);

  CollectionReference get _tasksCollection =>
      _firestore.collection('periodic_compliance_tasks');

  Future<void> createTask(PeriodicComplianceTask task) async {
    await _tasksCollection.add(task.toJson());
  }

  Future<void> updateTask(PeriodicComplianceTask task) async {
    await _tasksCollection.doc(task.id).update(task.toJson());
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  Future<void> completeTask(String taskId) async {
    await _tasksCollection.doc(taskId).update({'status': 'completed'});
  }

  Stream<List<PeriodicComplianceTask>> getTasksStream({
    String? customerId,
    String? createdBy,
    bool isConsultant = false,
  }) {
    if (customerId != null && customerId.isNotEmpty) {
      return _tasksCollection
          .where('assignedCustomerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return PeriodicComplianceTask.fromJson(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    }

    if (isConsultant && createdBy != null && createdBy.isNotEmpty) {
      return _tasksCollection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((tasksSnapshot) async {
        final custSnapshot = await _firestore
            .collection('customers')
            .where('consultantId', isEqualTo: createdBy)
            .get();
        final assignedCustomerIds =
            custSnapshot.docs.map((doc) => doc.id).toSet();

        final allTasks = tasksSnapshot.docs.map((doc) {
          return PeriodicComplianceTask.fromJson(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        return allTasks.where((task) {
          final isMyTask = task.createdBy == createdBy;
          final isMyCustomerTask =
              assignedCustomerIds.contains(task.assignedCustomerId);
          return isMyTask || isMyCustomerTask;
        }).toList();
      });
    }

    if (createdBy != null && createdBy.isNotEmpty) {
      return _tasksCollection
          .where('createdBy', isEqualTo: createdBy)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return PeriodicComplianceTask.fromJson(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    }

    return _tasksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PeriodicComplianceTask.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }
}
