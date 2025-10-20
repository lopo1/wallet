import 'package:flutter/foundation.dart';
import '../models/dapp_connection.dart';

import '../models/web3_request.dart';
import 'storage_service.dart';

/// DApp连接请求模型
class DAppConnectionRequest {
  final String origin;
  final String name;
  final String iconUrl;
  final List<String> requestedAddresses;
  final String networkId;
  final List<DAppPermission> requestedPermissions;
  final Map<String, dynamic> metadata;

  const DAppConnectionRequest({
    required this.origin,
    required this.name,
    required this.iconUrl,
    required this.requestedAddresses,
    required this.networkId,
    required this.requestedPermissions,
    this.metadata = const {},
  });
}

/// DApp连接服务
///
/// 负责管理DApp连接状态、权限控制和会话管理
class DAppConnectionService extends ChangeNotifier {
  final StorageService _storageService;
  final Map<String, DAppConnection> _connections = {};
  final Map<String, Web3Request> _pendingRequests = {};
  final Set<String> _favoriteDApps = {};
  final List<String> _dappHistory = [];

  static const String _connectionsKey = 'dapp_connections';
  static const String _favoritesKey = 'dapp_favorites';
  static const String _historyKey = 'dapp_history';

  DAppConnectionService({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  /// 获取所有活跃连接
  Map<String, DAppConnection> get connections => Map.unmodifiable(_connections);

  /// 获取待处理的请求
  Map<String, Web3Request> get pendingRequests =>
      Map.unmodifiable(_pendingRequests);

  /// 获取收藏的DApp列表
  Set<String> get favoriteDApps => Set.unmodifiable(_favoriteDApps);

  /// 获取DApp访问历史
  List<String> get dappHistory => List.unmodifiable(_dappHistory);

  /// 获取活跃连接列表
  List<DAppConnection> getActiveConnections() {
    return _connections.values
        .where((conn) => conn.status == DAppConnectionStatus.connected)
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  }

  /// 初始化服务
  Future<void> initialize() async {
    try {
      await _loadConnections();
      await _loadFavorites();
      await _loadHistory();
      debugPrint(
          'DAppConnectionService initialized with ${_connections.length} connections, ${_favoriteDApps.length} favorites');
    } catch (e) {
      debugPrint('Failed to initialize DAppConnectionService: $e');
    }
  }

  /// 检查DApp是否已连接
  bool isConnected(String origin) {
    final connection = _connections[origin];
    return connection != null &&
        connection.status == DAppConnectionStatus.connected;
  }

  /// 获取DApp连接信息
  DAppConnection? getConnection(String origin) {
    return _connections[origin];
  }

  /// 连接DApp
  Future<bool> connectDApp(DAppConnectionRequest request) async {
    try {
      debugPrint('=== 开始连接DApp ===');
      debugPrint('Origin: ${request.origin}');
      debugPrint('Name: ${request.name}');
      debugPrint('Network: ${request.networkId}');
      debugPrint('Addresses: ${request.requestedAddresses}');
      debugPrint(
          'Permissions: ${request.requestedPermissions.map((p) => p.toString()).join(', ')}');

      // 验证请求参数
      if (request.origin.isEmpty) {
        throw Exception('Origin不能为空');
      }

      if (request.requestedAddresses.isEmpty) {
        throw Exception('请求的地址列表不能为空');
      }

      if (request.networkId.isEmpty) {
        throw Exception('网络ID不能为空');
      }

      // 验证地址格式
      for (final address in request.requestedAddresses) {
        if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address)) {
          throw Exception('地址格式无效: $address');
        }
      }

      final connection = DAppConnection(
        origin: request.origin,
        name: request.name,
        iconUrl: request.iconUrl,
        connectedAddresses: request.requestedAddresses,
        networkId: request.networkId,
        connectedAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
        permissions: request.requestedPermissions,
        status: DAppConnectionStatus.connected,
        metadata: request.metadata,
      );

      debugPrint('创建连接对象: ${connection.toJson()}');

      _connections[request.origin] = connection;

      // 保存连接数据
      try {
        await _saveConnections();
        debugPrint('连接数据已保存');
      } catch (e) {
        debugPrint('保存连接数据失败: $e');
        // 移除已添加的连接
        _connections.remove(request.origin);
        throw Exception('保存连接数据失败: $e');
      }

      // 通知监听器
      notifyListeners();

      debugPrint('=== DApp连接成功 ===');
      debugPrint('Origin: ${request.origin}');
      debugPrint('连接状态: ${connection.status}');
      debugPrint('总连接数: ${_connections.length}');

      return true;
    } catch (e) {
      debugPrint('=== DApp连接失败 ===');
      debugPrint('Origin: ${request.origin}');
      debugPrint('错误: $e');
      debugPrint('错误堆栈: ${StackTrace.current}');
      return false;
    }
  }

  /// 断开DApp连接
  Future<void> disconnectDApp(String origin) async {
    try {
      final connection = _connections[origin];
      if (connection != null) {
        _connections[origin] = connection.copyWith(
          status: DAppConnectionStatus.disconnected,
        );

        // 移除待处理的请求
        _pendingRequests
            .removeWhere((key, request) => request.origin == origin);

        await _saveConnections();
        notifyListeners();

        debugPrint('DApp disconnected: $origin');
      }
    } catch (e) {
      debugPrint('Failed to disconnect DApp $origin: $e');
    }
  }

  /// 更新DApp最后使用时间
  Future<void> updateLastUsed(String origin) async {
    try {
      final connection = _connections[origin];
      if (connection != null) {
        _connections[origin] = connection.updateLastUsed();
        await _saveConnections();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update last used for $origin: $e');
    }
  }

  /// 添加待处理的Web3请求
  void addPendingRequest(Web3Request request) {
    _pendingRequests[request.id] = request;
    notifyListeners();
  }

  /// 移除待处理的Web3请求
  void removePendingRequest(String requestId) {
    _pendingRequests.remove(requestId);
    notifyListeners();
  }

  /// 获取待处理的请求
  Web3Request? getPendingRequest(String requestId) {
    return _pendingRequests[requestId];
  }

  /// 更新Web3请求状态
  void updateRequestStatus(String requestId, Web3Request updatedRequest) {
    if (_pendingRequests.containsKey(requestId)) {
      _pendingRequests[requestId] = updatedRequest;
      notifyListeners();
    }
  }

  /// 检查DApp是否有特定权限
  bool hasPermission(String origin, DAppPermission permission) {
    final connection = _connections[origin];
    return connection?.hasPermission(permission) ?? false;
  }

  /// 为DApp添加权限
  Future<void> addPermission(String origin, DAppPermission permission) async {
    try {
      final connection = _connections[origin];
      if (connection != null) {
        _connections[origin] = connection.addPermission(permission);
        await _saveConnections();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to add permission for $origin: $e');
    }
  }

  /// 为DApp移除权限
  Future<void> removePermission(
      String origin, DAppPermission permission) async {
    try {
      final connection = _connections[origin];
      if (connection != null) {
        _connections[origin] = connection.removePermission(permission);
        await _saveConnections();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to remove permission for $origin: $e');
    }
  }

  /// 清理过期连接（超过30天未使用）
  Future<void> cleanupExpiredConnections() async {
    try {
      final now = DateTime.now();
      final expiredOrigins = <String>[];

      for (final entry in _connections.entries) {
        final daysSinceLastUsed = now.difference(entry.value.lastUsedAt).inDays;
        if (daysSinceLastUsed > 30) {
          expiredOrigins.add(entry.key);
        }
      }

      for (final origin in expiredOrigins) {
        _connections.remove(origin);
      }

      if (expiredOrigins.isNotEmpty) {
        await _saveConnections();
        notifyListeners();
        debugPrint('Cleaned up ${expiredOrigins.length} expired connections');
      }
    } catch (e) {
      debugPrint('Failed to cleanup expired connections: $e');
    }
  }

  /// 获取连接统计信息
  Map<String, int> getConnectionStats() {
    final stats = <String, int>{
      'total': _connections.length,
      'active': 0,
      'inactive': 0,
    };

    for (final connection in _connections.values) {
      if (connection.isActive) {
        stats['active'] = (stats['active'] ?? 0) + 1;
      } else {
        stats['inactive'] = (stats['inactive'] ?? 0) + 1;
      }
    }

    return stats;
  }

  /// 加载连接数据
  Future<void> _loadConnections() async {
    try {
      final connectionsData = await _storageService.getData(_connectionsKey);
      if (connectionsData != null && connectionsData is List) {
        _connections.clear();
        for (final data in connectionsData) {
          if (data is Map<String, dynamic>) {
            final connection = DAppConnection.fromJson(data);
            _connections[connection.origin] = connection;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load connections: $e');
    }
  }

  /// 保存连接数据
  Future<void> _saveConnections() async {
    try {
      final connectionsData =
          _connections.values.map((connection) => connection.toJson()).toList();
      await _storageService.saveData(_connectionsKey, connectionsData);
    } catch (e) {
      debugPrint('Failed to save connections: $e');
    }
  }

  /// 添加DApp到收藏
  Future<void> addToFavorites(String origin) async {
    try {
      _favoriteDApps.add(origin);
      await _saveFavorites();
      notifyListeners();
      debugPrint('Added DApp to favorites: $origin');
    } catch (e) {
      debugPrint('Failed to add DApp to favorites: $e');
    }
  }

  /// 从收藏中移除DApp
  Future<void> removeFromFavorites(String origin) async {
    try {
      _favoriteDApps.remove(origin);
      await _saveFavorites();
      notifyListeners();
      debugPrint('Removed DApp from favorites: $origin');
    } catch (e) {
      debugPrint('Failed to remove DApp from favorites: $e');
    }
  }

  /// 检查DApp是否已收藏
  bool isFavorite(String origin) {
    return _favoriteDApps.contains(origin);
  }

  /// 切换DApp收藏状态
  Future<void> toggleFavorite(String origin) async {
    if (isFavorite(origin)) {
      await removeFromFavorites(origin);
    } else {
      await addToFavorites(origin);
    }
  }

  /// 添加DApp到访问历史
  Future<void> addToHistory(String origin) async {
    try {
      // 移除已存在的记录（如果有）
      _dappHistory.remove(origin);
      // 添加到开头
      _dappHistory.insert(0, origin);
      // 限制历史记录数量为50个
      if (_dappHistory.length > 50) {
        _dappHistory.removeRange(50, _dappHistory.length);
      }
      await _saveHistory();
      notifyListeners();
      debugPrint('Added DApp to history: $origin');
    } catch (e) {
      debugPrint('Failed to add DApp to history: $e');
    }
  }

  /// 从访问历史中移除
  Future<void> removeFromHistory(String origin) async {
    try {
      _dappHistory.remove(origin);
      await _saveHistory();
      notifyListeners();
      debugPrint('Removed DApp from history: $origin');
    } catch (e) {
      debugPrint('Failed to remove DApp from history: $e');
    }
  }

  /// 清除访问历史
  Future<void> clearHistory() async {
    try {
      _dappHistory.clear();
      await _saveHistory();
      notifyListeners();
      debugPrint('DApp history cleared');
    } catch (e) {
      debugPrint('Failed to clear DApp history: $e');
    }
  }

  /// 获取最近访问的DApp（去重）
  List<String> getRecentDApps({int limit = 10}) {
    return _dappHistory.take(limit).toList();
  }

  /// 批量连接多个DApp
  Future<Map<String, bool>> connectMultipleDApps(
      List<DAppConnectionRequest> requests) async {
    final results = <String, bool>{};

    for (final request in requests) {
      try {
        final success = await connectDApp(request);
        results[request.origin] = success;
      } catch (e) {
        debugPrint('Failed to connect DApp ${request.origin}: $e');
        results[request.origin] = false;
      }
    }

    return results;
  }

  /// 批量断开多个DApp连接
  Future<void> disconnectMultipleDApps(List<String> origins) async {
    for (final origin in origins) {
      await disconnectDApp(origin);
    }
  }

  /// 获取DApp连接详细信息
  Map<String, dynamic> getConnectionDetails(String origin) {
    final connection = _connections[origin];
    if (connection == null) {
      return {};
    }

    return {
      'connection': connection.toJson(),
      'isFavorite': isFavorite(origin),
      'isInHistory': _dappHistory.contains(origin),
      'historyPosition': _dappHistory.indexOf(origin),
      'daysSinceLastUsed':
          DateTime.now().difference(connection.lastUsedAt).inDays,
      'totalPermissions': connection.permissions.length,
      'isActive': connection.isActive,
    };
  }

  /// 搜索DApp连接
  List<DAppConnection> searchConnections(String query) {
    if (query.trim().isEmpty) {
      return getActiveConnections();
    }

    final lowerQuery = query.toLowerCase();
    return _connections.values.where((connection) {
      return connection.name.toLowerCase().contains(lowerQuery) ||
          connection.origin.toLowerCase().contains(lowerQuery) ||
          connection.domain.toLowerCase().contains(lowerQuery);
    }).toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  }

  /// 按权限筛选连接
  List<DAppConnection> getConnectionsByPermission(DAppPermission permission) {
    return _connections.values
        .where((connection) => connection.hasPermission(permission))
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  }

  /// 获取网络相关的连接
  List<DAppConnection> getConnectionsByNetwork(String networkId) {
    return _connections.values
        .where((connection) => connection.networkId == networkId)
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  }

  /// 撤销DApp权限
  Future<void> revokePermissions(
      String origin, Map<String, dynamic> permissions) async {
    try {
      final connection = _connections[origin];
      if (connection == null) {
        debugPrint('Connection not found for origin: $origin');
        return;
      }

      // 解析权限参数
      if (permissions.containsKey('eth_accounts')) {
        // 撤销账户访问权限
        await removePermission(origin, DAppPermission.readAccounts);
        debugPrint('Revoked eth_accounts permission for $origin');
      }

      // 可以根据需要添加更多权限类型的处理
      // 例如：sendTransactions, signMessages等

      debugPrint('Permissions revoked for DApp: $origin');
    } catch (e) {
      debugPrint('Failed to revoke permissions for $origin: $e');
      rethrow;
    }
  }

  /// 导出连接数据（用于备份）
  Map<String, dynamic> exportData() {
    return {
      'connections': _connections.values.map((c) => c.toJson()).toList(),
      'favorites': _favoriteDApps.toList(),
      'history': _dappHistory,
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  /// 导入连接数据（用于恢复）
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      // 验证数据格式
      if (!data.containsKey('connections') || !data.containsKey('favorites')) {
        throw Exception('Invalid data format');
      }

      // 清除现有数据
      _connections.clear();
      _favoriteDApps.clear();
      _dappHistory.clear();

      // 导入连接
      final connections = data['connections'] as List<dynamic>;
      for (final connData in connections) {
        if (connData is Map<String, dynamic>) {
          final connection = DAppConnection.fromJson(connData);
          _connections[connection.origin] = connection;
        }
      }

      // 导入收藏
      final favorites = data['favorites'] as List<dynamic>;
      _favoriteDApps.addAll(favorites.cast<String>());

      // 导入历史
      if (data.containsKey('history')) {
        final history = data['history'] as List<dynamic>;
        _dappHistory.addAll(history.cast<String>());
      }

      // 保存数据
      await _saveConnections();
      await _saveFavorites();
      await _saveHistory();

      notifyListeners();
      debugPrint('Successfully imported DApp data');
      return true;
    } catch (e) {
      debugPrint('Failed to import DApp data: $e');
      return false;
    }
  }

  /// 加载收藏数据
  Future<void> _loadFavorites() async {
    try {
      final favoritesData = await _storageService.getData(_favoritesKey);
      if (favoritesData != null && favoritesData is List) {
        _favoriteDApps.clear();
        _favoriteDApps.addAll(favoritesData.cast<String>());
      }
    } catch (e) {
      debugPrint('Failed to load favorites: $e');
    }
  }

  /// 保存收藏数据
  Future<void> _saveFavorites() async {
    try {
      await _storageService.saveData(_favoritesKey, _favoriteDApps.toList());
    } catch (e) {
      debugPrint('Failed to save favorites: $e');
    }
  }

  /// 加载历史数据
  Future<void> _loadHistory() async {
    try {
      final historyData = await _storageService.getData(_historyKey);
      if (historyData != null && historyData is List) {
        _dappHistory.clear();
        _dappHistory.addAll(historyData.cast<String>());
      }
    } catch (e) {
      debugPrint('Failed to load history: $e');
    }
  }

  /// 保存历史数据
  Future<void> _saveHistory() async {
    try {
      await _storageService.saveData(_historyKey, _dappHistory);
    } catch (e) {
      debugPrint('Failed to save history: $e');
    }
  }

  /// 清理所有数据
  Future<void> clearAllData() async {
    try {
      _connections.clear();
      _pendingRequests.clear();
      _favoriteDApps.clear();
      _dappHistory.clear();

      await _storageService.removeData(_connectionsKey);
      await _storageService.removeData(_favoritesKey);
      await _storageService.removeData(_historyKey);

      notifyListeners();
      debugPrint('All DApp connection data cleared');
    } catch (e) {
      debugPrint('Failed to clear DApp connection data: $e');
    }
  }

  @override
  void dispose() {
    _connections.clear();
    _pendingRequests.clear();
    _favoriteDApps.clear();
    _dappHistory.clear();
    super.dispose();
  }
}
