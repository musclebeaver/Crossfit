import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'local_record_service.dart';

class SyncManager {
  static bool _isSyncing = false;

  static Future<void> syncPendingRecords() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingList = await LocalRecordService.getPendingRecords();
      if (pendingList.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('SyncManager: Starting sync for ${pendingList.length} records...');

      for (var item in pendingList) {
        final id = item['id'] as int;
        final data = jsonDecode(item['data'] as String);

        try {
          final res = await ApiClient().dio.post('/records', data: data);
          if (res.data['success'] == true) {
            await LocalRecordService.deleteRecord(id);
            debugPrint('SyncManager: Successfully synced record $id');
          }
        } catch (e) {
          debugPrint('SyncManager: Failed to sync record $id, will retry later. Error: $e');
          // 전송 실패 시 루프 중단 (네트워크가 아직 불안정할 가능성이 높음)
          break;
        }
      }
    } catch (e) {
      debugPrint('SyncManager: Error during sync process: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
