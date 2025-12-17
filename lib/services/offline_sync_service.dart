/// Offline Data Synchronization Service
///
/// Manages offline data operations and syncs with Firestore when connectivity is restored.
/// Implements a queue-based approach with conflict resolution.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../config/firebase_config.dart';

/// Enum for sync operations
enum SyncOperationType {
  create,
  update,
  delete,
}

/// Represents a queued sync operation
class SyncQueueItem {
  final String id;
  final String collection;
  final String documentId;
  final SyncOperationType operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  SyncQueueItem({
    required this.id,
    required this.collection,
    required this.documentId,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'collection': collection,
        'documentId': documentId,
        'operation': operation.name,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) => SyncQueueItem(
        id: map['id'] ?? '',
        collection: map['collection'] ?? '',
        documentId: map['documentId'] ?? '',
        operation: SyncOperationType.values.firstWhere(
          (e) => e.name == map['operation'],
          orElse: () => SyncOperationType.update,
        ),
        data: Map<String, dynamic>.from(map['data'] ?? {}),
        createdAt: DateTime.parse(
            map['createdAt'] ?? DateTime.now().toIso8601String()),
        retryCount: map['retryCount'] ?? 0,
      );
}

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();

  late FirebaseFirestore _firestore;
  late Box<Map> _syncQueueBox;
  late Box<Map> _conflictResolverBox;

  // Constants
  static const String _syncQueueBoxName = 'sync_queue';
  static const String _conflictBoxName = 'conflict_resolver';
  static const int _maxRetries = 3;

  factory OfflineSyncService() {
    return _instance;
  }

  OfflineSyncService._internal() {
    _firestore = firebaseConfig.firestore;
  }

  /// Initialize the offline sync service
  Future<void> initialize() async {
    try {
      _syncQueueBox = await Hive.openBox<Map>(_syncQueueBoxName);
      _conflictResolverBox = await Hive.openBox<Map>(_conflictBoxName);
      print('OfflineSyncService initialized');
    } catch (e) {
      throw Exception('Failed to initialize OfflineSyncService: $e');
    }
  }

  // ========================================================================
  // QUEUE MANAGEMENT
  // ========================================================================

  /// Add operation to sync queue
  Future<void> queueOperation({
    required String collection,
    required String documentId,
    required SyncOperationType operation,
    required Map<String, dynamic> data,
  }) async {
    try {
      final item = SyncQueueItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        collection: collection,
        documentId: documentId,
        operation: operation,
        data: data,
        createdAt: DateTime.now(),
      );

      await _syncQueueBox.put(item.id, item.toMap());
      print('Queued $operation operation for $collection/$documentId');
    } catch (e) {
      print('Failed to queue operation: $e');
      throw Exception('Failed to queue operation: $e');
    }
  }

  /// Get all queued operations
  Future<List<SyncQueueItem>> getQueuedOperations() async {
    try {
      return _syncQueueBox.values
          .map((item) => SyncQueueItem.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Failed to get queued operations: $e');
      return [];
    }
  }

  /// Clear sync queue (use after successful sync)
  Future<void> clearQueue() async {
    try {
      await _syncQueueBox.clear();
      print('Sync queue cleared');
    } catch (e) {
      print('Failed to clear queue: $e');
    }
  }

  // ========================================================================
  // SYNC OPERATIONS
  // ========================================================================

  /// Sync all queued operations with Firestore
  Future<SyncResult> syncAllOperations() async {
    try {
      final queuedOps = await getQueuedOperations();

      if (queuedOps.isEmpty) {
        return SyncResult(successful: 0, failed: 0, conflicts: 0);
      }

      int successful = 0;
      int failed = 0;
      int conflicts = 0;

      for (final op in queuedOps) {
        try {
          final result = await _syncSingleOperation(op);

          if (result == SyncOperationResult.success) {
            successful++;
            await _syncQueueBox.delete(op.id);
          } else if (result == SyncOperationResult.conflict) {
            conflicts++;
            await _handleConflict(op);
          } else {
            failed++;
            await _incrementRetryCount(op);
          }
        } catch (e) {
          failed++;
          print('Error syncing operation ${op.id}: $e');
        }

        // Small delay between operations to avoid overwhelming server
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print(
          'Sync complete: $successful successful, $failed failed, $conflicts conflicts');
      return SyncResult(
        successful: successful,
        failed: failed,
        conflicts: conflicts,
      );
    } catch (e) {
      print('Failed to sync operations: $e');
      return SyncResult(successful: 0, failed: 0, conflicts: 0);
    }
  }

  /// Sync a single operation
  Future<SyncOperationResult> _syncSingleOperation(SyncQueueItem item) async {
    try {
      final docRef =
          _firestore.collection(item.collection).doc(item.documentId);

      switch (item.operation) {
        case SyncOperationType.create:
          await docRef.set(item.data, SetOptions(merge: false));
          break;

        case SyncOperationType.update:
          // Check if document exists
          final doc = await docRef.get();
          if (!doc.exists) {
            // Document doesn't exist, create it
            await docRef.set(item.data, SetOptions(merge: true));
          } else {
            // Detect conflicts
            if (_hasConflicts(doc.data() as Map<String, dynamic>, item.data)) {
              return SyncOperationResult.conflict;
            }
            await docRef.update(item.data);
          }
          break;

        case SyncOperationType.delete:
          await docRef.delete();
          break;
      }

      return SyncOperationResult.success;
    } catch (e) {
      print('Error syncing operation: $e');
      return SyncOperationResult.failure;
    }
  }

  /// Check for conflicts between local and remote data
  bool _hasConflicts(Map<String, dynamic> remote, Map<String, dynamic> local) {
    // Simple conflict detection: if remote was updated after our local operation
    // In a real scenario, implement more sophisticated conflict resolution

    final remoteTimestamp = remote['updatedAt'];
    final localTimestamp = local['updatedAt'];

    if (remoteTimestamp == null || localTimestamp == null) {
      return false;
    }

    // If remote timestamp is significantly later, mark as conflict
    final remoteTime = remoteTimestamp is Timestamp
        ? remoteTimestamp.toDate()
        : DateTime.parse(remoteTimestamp.toString());

    final localTime = localTimestamp is DateTime
        ? localTimestamp
        : DateTime.parse(localTimestamp.toString());

    return remoteTime.isAfter(localTime.add(const Duration(seconds: 5)));
  }

  /// Handle conflict resolution
  Future<void> _handleConflict(SyncQueueItem item) async {
    try {
      // Store conflict for manual resolution or automatic merge
      final conflictKey = '${item.collection}_${item.documentId}';

      final conflictData = {
        'queueItem': item.toMap(),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending', // pending, resolved, ignored
      };

      await _conflictResolverBox.put(conflictKey, conflictData);
      print('Conflict stored for manual resolution: $conflictKey');
    } catch (e) {
      print('Failed to handle conflict: $e');
    }
  }

  /// Resolve conflict by choosing local or remote version
  Future<void> resolveConflict({
    required String conflictKey,
    required bool useLocal,
  }) async {
    try {
      if (useLocal) {
        // Local version is correct, retry sync
        final conflictData = _conflictResolverBox.get(conflictKey);
        if (conflictData != null) {
          final item = SyncQueueItem.fromMap(
            Map<String, dynamic>.from(conflictData['queueItem']),
          );
          await _syncSingleOperation(item);
        }
      }

      // Mark conflict as resolved
      final conflictData = _conflictResolverBox.get(conflictKey);
      if (conflictData != null) {
        conflictData['status'] = 'resolved';
        await _conflictResolverBox.put(conflictKey, conflictData);
      }
    } catch (e) {
      print('Failed to resolve conflict: $e');
    }
  }

  /// Get pending conflicts
  Future<List<Map<String, dynamic>>> getPendingConflicts() async {
    try {
      return _conflictResolverBox.values
          .map((item) {
            final data = Map<String, dynamic>.from(item);
            return data['status'] == 'pending' ? data : null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      print('Failed to get conflicts: $e');
      return [];
    }
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================

  /// Increment retry count for failed operation
  Future<void> _incrementRetryCount(SyncQueueItem item) async {
    try {
      if (item.retryCount < _maxRetries) {
        final updated = item.toMap();
        updated['retryCount'] = item.retryCount + 1;
        await _syncQueueBox.put(item.id, updated);
      } else {
        // Remove item after max retries
        await _syncQueueBox.delete(item.id);
        print('Operation ${item.id} removed after max retries');
      }
    } catch (e) {
      print('Failed to increment retry count: $e');
    }
  }

  /// Clear offline data (careful with this!)
  Future<void> clearAllOfflineData() async {
    try {
      await _syncQueueBox.clear();
      await _conflictResolverBox.clear();
      print('All offline data cleared');
    } catch (e) {
      print('Failed to clear offline data: $e');
    }
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    return _syncQueueBox.length;
  }
}

/// Result of sync operation
class SyncResult {
  final int successful;
  final int failed;
  final int conflicts;

  SyncResult({
    required this.successful,
    required this.failed,
    required this.conflicts,
  });

  int get total => successful + failed + conflicts;
  bool get hasFailures => failed > 0 || conflicts > 0;

  @override
  String toString() =>
      'SyncResult(successful: $successful, failed: $failed, conflicts: $conflicts)';
}

/// Result of individual sync operation
enum SyncOperationResult {
  success,
  failure,
  conflict,
}

/// Global offline sync service instance
final offlineSyncService = OfflineSyncService();
