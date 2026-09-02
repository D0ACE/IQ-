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

  Stream<List<PeriodicComplianceTask>> getTasksStream({String? customerId, String? createdBy}) {
    Query query = _tasksCollection.orderBy('createdAt', descending: true);
    
    if (customerId != null) {
      query = query.where('assignedCustomerId', isEqualTo: customerId);
    }

    if (createdBy != null) {
      query = query.where('createdBy', isEqualTo: createdBy);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PeriodicComplianceTask.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }
}
