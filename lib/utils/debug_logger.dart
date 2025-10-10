import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 调试日志工具类
class DebugLogger {
  static const String _tag = 'WalletApp';
  static bool _isDebugMode = kDebugMode;
  static bool _isEnabled = true;

  /// 启用或禁用日志
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// 设置调试模式
  static void setDebugMode(bool debugMode) {
    _isDebugMode = debugMode;
  }

  /// 记录信息日志
  static void info(String message, {String? tag}) {
    if (!_isEnabled) return;
    final logTag = tag ?? _tag;
    final logMessage = '[$logTag] INFO: $message';
    
    if (_isDebugMode) {
      developer.log(logMessage, name: logTag);
    } else {
      print(logMessage);
    }
  }

  /// 记录警告日志
  static void warning(String message, {String? tag, dynamic error}) {
    if (!_isEnabled) return;
    final logTag = tag ?? _tag;
    var logMessage = '[$logTag] WARNING: $message';
    
    if (error != null) {
      logMessage += '\nError: $error';
    }
    
    if (_isDebugMode) {
      developer.log(logMessage, name: logTag, level: 2000);
    } else {
      print(logMessage);
    }
  }

  /// 记录错误日志
  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (!_isEnabled) return;
    final logTag = tag ?? _tag;
    var logMessage = '[$logTag] ERROR: $message';
    
    if (error != null) {
      logMessage += '\nError: $error';
    }
    
    if (stackTrace != null) {
      logMessage += '\nStackTrace: $stackTrace';
    }
    
    if (_isDebugMode) {
      developer.log(logMessage, name: logTag, level: 3000, error: error, stackTrace: stackTrace);
    } else {
      print(logMessage);
    }
  }

  /// 记录调试日志
  static void debug(String message, {String? tag}) {
    if (!_isEnabled || !_isDebugMode) return;
    final logTag = tag ?? _tag;
    final logMessage = '[$logTag] DEBUG: $message';
    
    developer.log(logMessage, name: logTag, level: 1000);
  }

  /// 记录网络请求日志
  static void network(String method, String url, {
    String? tag,
    Map<String, dynamic>? headers,
    dynamic body,
    int? statusCode,
    dynamic response,
  }) {
    if (!_isEnabled) return;
    final logTag = tag ?? _tag;
    var logMessage = '[$logTag] NETWORK: $method $url';
    
    if (headers != null) {
      logMessage += '\nHeaders: $headers';
    }
    
    if (body != null) {
      logMessage += '\nBody: $body';
    }
    
    if (statusCode != null) {
      logMessage += '\nStatus: $statusCode';
    }
    
    if (response != null) {
      logMessage += '\nResponse: $response';
    }
    
    if (_isDebugMode) {
      developer.log(logMessage, name: logTag, level: 1500);
    } else {
      print(logMessage);
    }
  }

  /// 记录Web3 Provider日志
  static void web3(String method, {
    String? tag,
    dynamic params,
    dynamic result,
    dynamic error,
  }) {
    if (!_isEnabled) return;
    final logTag = tag ?? _tag;
    var logMessage = '[$logTag] WEB3: $method';
    
    if (params != null) {
      logMessage += '\nParams: $params';
    }
    
    if (result != null) {
      logMessage += '\nResult: $result';
    }
    
    if (error != null) {
      logMessage += '\nError: $error';
    }
    
    if (_isDebugMode) {
      developer.log(logMessage, name: logTag, level: 1200);
    } else {
      print(logMessage);
    }
  }

  /// 记录WalletConnect日志
  static void walletConnect(String event, {
    String? tag,
    dynamic data,
    dynamic error,
  }) {
    if (!_isEnabled) return;
    final logTag = tag ?? _tag;
    var logMessage = '[$logTag] WALLETCONNECT: $event';
    
    if (data != null) {
      logMessage += '\nData: $data';
    }
    
    if (error != null) {
      logMessage += '\nError: $error';
    }
    
    if (_isDebugMode) {
      developer.log(logMessage, name: logTag, level: 1300);
    } else {
      print(logMessage);
    }
  }

  /// 清除控制台日志（仅在调试模式下有效）
  static void clearConsole() {
    if (_isDebugMode && _isEnabled) {
      developer.log('', name: 'CLEAR');
    }
  }
}