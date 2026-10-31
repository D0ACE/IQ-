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

  Future<bool> saveTaskProgress(
    String taskId, {
    required String evidenceUrl,
    required String evidenceFileName,
    String comment = '',
    String achieved = '',
    String achievedType = '',
  }) async {
    final docSnap = await _tasksCollection.doc(taskId).get();
    String updatedUrl = evidenceUrl;
    String updatedName = evidenceFileName;
    String updatedComment = comment;
    bool isNonCompliant = false;

    if (docSnap.exists && docSnap.data() != null) {
      final data = docSnap.data() as Map<String, dynamic>;
      final status = (data['status'] as String? ?? '').toLowerCase();
      DateTime? dueDate;
      if (data['dueDate'] is Timestamp) {
        dueDate = (data['dueDate'] as Timestamp).toDate();
      }
      if (status == 'non_compliant' || status == 'non compliant') {
        isNonCompliant = true;
      } else if (dueDate != null && dueDate.isBefore(DateTime.now())) {
        isNonCompliant = true;
      }

      final existingUrl = data['evidenceUrl'] as String? ?? '';
      final existingName = data['evidenceFileName'] as String? ?? '';
      final existingComment = data['comment'] as String? ?? data['comments'] as String? ?? '';

      if (existingUrl.isNotEmpty && evidenceUrl.isNotEmpty) {
        updatedUrl = '$existingUrl,$evidenceUrl';
      } else if (existingUrl.isNotEmpty) {
        updatedUrl = existingUrl;
      }

      if (existingName.isNotEmpty && evidenceFileName.isNotEmpty) {
        updatedName = '$existingName,$evidenceFileName';
      } else if (existingName.isNotEmpty) {
        updatedName = existingName;
      }

      if (existingComment.isNotEmpty && comment.isNotEmpty) {
        updatedComment = '$existingComment\n$comment';
      } else if (existingComment.isNotEmpty) {
        updatedComment = existingComment;
      }
    }

    final Map<String, dynamic> updateData = {
      'status': 'in_progress',
      'evidenceUrl': updatedUrl,
      'evidenceFileName': updatedName,
    };
    if (updatedComment.isNotEmpty) {
      updateData['comment'] = updatedComment;
    }
    if (achieved.isNotEmpty) {
      updateData['achieved'] = achieved;
    }
    if (achievedType.isNotEmpty) {
      updateData['achievedType'] = achievedType;
    }

    await _tasksCollection.doc(taskId).update(updateData);
    return isNonCompliant;
  }

  Future<void> completeTask(
    String taskId, {
    String evidenceUrl = '',
    String evidenceFileName = '',
    String comment = '',
    String achieved = '',
    String achievedType = '',
  }) async {
    final docSnap = await _tasksCollection.doc(taskId).get();
    String updatedUrl = evidenceUrl;
    String updatedName = evidenceFileName;
    String updatedComment = comment;

    if (docSnap.exists && docSnap.data() != null) {
      final data = docSnap.data() as Map<String, dynamic>;
      final existingUrl = data['evidenceUrl'] as String? ?? '';
      final existingName = data['evidenceFileName'] as String? ?? '';
      final existingComment = data['comment'] as String? ?? data['comments'] as String? ?? '';

      if (existingUrl.isNotEmpty && evidenceUrl.isNotEmpty) {
        updatedUrl = '$existingUrl,$evidenceUrl';
      } else if (existingUrl.isNotEmpty) {
        updatedUrl = existingUrl;
      }

      if (existingName.isNotEmpty && evidenceFileName.isNotEmpty) {
        updatedName = '$existingName,$evidenceFileName';
      } else if (existingName.isNotEmpty) {
        updatedName = existingName;
      }

      if (existingComment.isNotEmpty && comment.isNotEmpty) {
        updatedComment = '$existingComment\n$comment';
      } else if (existingComment.isNotEmpty) {
        updatedComment = existingComment;
      }
    }

    final Map<String, dynamic> updateData = {'status': 'completed'};
    if (updatedUrl.isNotEmpty) {
      updateData['evidenceUrl'] = updatedUrl;
    }
    if (updatedName.isNotEmpty) {
      updateData['evidenceFileName'] = updatedName;
    }
    if (updatedComment.isNotEmpty) {
      updateData['comment'] = updatedComment;
    }
    if (achieved.isNotEmpty) {
      updateData['achieved'] = achieved;
    }
    if (achievedType.isNotEmpty) {
      updateData['achievedType'] = achievedType;
    }

    await _tasksCollection.doc(taskId).update(updateData);
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
