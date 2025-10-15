import 'dart:async';
import 'package:flutter/material.dart';
import 'storage_service.dart';

/// 屏幕锁定服务
/// 负责管理应用的自动锁屏功能
class ScreenLockService {
  static final ScreenLockService _instance = ScreenLockService._internal();
  factory ScreenLockService() => _instance;
  ScreenLockService._internal();

  Timer? _lockTimer;
  final StorageService _storageService = StorageService();
  VoidCallback? _onLockScreen;
  
  /// 设置锁屏回调函数
  void setLockScreenCallback(VoidCallback callback) {
    _onLockScreen = callback;
  }

  /// 重置锁屏计时器
  void resetTimer() {
    _cancelTimer();
    _startTimer();
  }

  /// 开始锁屏计时器
  Future<void> _startTimer() async {
    try {
      final timeout = await _storageService.getLockScreenTimeout();
      
      // 如果设置为永不锁屏，则不启动计时器
      if (timeout <= 0) {
        return;
      }

      _lockTimer = Timer(Duration(seconds: timeout), () {
        _triggerLockScreen();
      });
    } catch (e) {
      debugPrint('启动锁屏计时器失败: $e');
    }
  }

  /// 取消锁屏计时器
  void _cancelTimer() {
    _lockTimer?.cancel();
    _lockTimer = null;
  }

  /// 触发锁屏
  void _triggerLockScreen() {
    debugPrint('触发自动锁屏');
    _onLockScreen?.call();
  }

  /// 停止锁屏服务
  void stop() {
    _cancelTimer();
    _onLockScreen = null;
  }

  /// 暂停锁屏服务（应用进入后台时）
  void pause() {
    _cancelTimer();
  }

  /// 恢复锁屏服务（应用回到前台时）
  void resume() {
    resetTimer();
  }

  /// 立即锁屏
  void lockNow() {
    _cancelTimer();
    _triggerLockScreen();
  }
}