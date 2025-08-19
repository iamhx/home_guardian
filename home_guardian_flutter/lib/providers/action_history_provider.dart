import 'package:flutter/material.dart';
import 'dart:async';
import '../models/action_log.dart';
import '../services/action_log_service.dart';

class ActionHistoryProvider extends ChangeNotifier {
  List<ActionLog> _actionLogs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _currentOffset = 0;

  // Getters
  List<ActionLog> get actionLogs => _actionLogs;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get isEmpty => _actionLogs.isEmpty;

  /// Load initial action logs
  Future<void> loadActionLogs() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _currentOffset = 0;
    notifyListeners();

    try {
      final logs = await ActionLogService.getUserActionLogsPaginated(
        limit: 20,
        offset: 0,
      );
      _actionLogs = logs;
      _hasMore = logs.length == 20;
      _currentOffset = logs.length;
    } catch (e) {
      _error = 'Failed to load action history: $e';
      _actionLogs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more action logs (pagination)
  Future<void> loadMoreActionLogs() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final logs = await ActionLogService.getUserActionLogsPaginated(
        limit: 20,
        offset: _currentOffset,
      );

      _actionLogs.addAll(logs);
      _hasMore = logs.length == 20;
      _currentOffset = _actionLogs.length;
    } catch (e) {
      _error = 'Failed to load more history: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh action logs (pull to refresh)
  Future<void> refreshActionLogs() async {
    _currentOffset = 0;
    _hasMore = true;
    await loadActionLogs();
  }

  /// Clear all action logs
  Future<void> clearActionLogs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ActionLogService.clearUserActionLogs();
      _actionLogs = [];
      _currentOffset = 0;
      _hasMore = true;
    } catch (e) {
      _error = 'Failed to clear history: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
