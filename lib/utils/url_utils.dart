import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../screens/webview_screen.dart';

class UrlUtils {
  /// 验证输入是否为有效的 URL 或域名
  static bool isValidUrl(String input) {
    if (input.isEmpty) return false;
    
    // 移除前后空格
    input = input.trim();
    
    try {
      // 尝试解析为URI
      Uri uri;
      if (input.startsWith('http://') || input.startsWith('https://')) {
        uri = Uri.parse(input);
      } else {
        // 如果没有协议，添加https://再解析
        uri = Uri.parse('https://$input');
      }
      
      // 检查是否有有效的host
      if (uri.host.isEmpty) return false;
      
      // 检查host是否包含至少一个点（域名格式）
      if (!uri.host.contains('.')) return false;
      
      // 检查顶级域名是否至少2个字符
      final parts = uri.host.split('.');
      if (parts.isEmpty || parts.last.length < 2) return false;
      
      // 简单的域名格式检查
      final domainRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]*\.[a-zA-Z]{2,}$');
      final simpleUrlRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9\-\.]*[a-zA-Z0-9]\.[a-zA-Z]{2,}');
      
      return domainRegex.hasMatch(uri.host) || simpleUrlRegex.hasMatch(uri.host);
    } catch (e) {
      // 如果URI解析失败，尝试简单的域名匹配
      final simpleRegex = RegExp(
        r'^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+'  // 子域名
        r'[a-zA-Z]{2,}$', // 顶级域名
        caseSensitive: false,
      );
      return simpleRegex.hasMatch(input);
    }
  }
  
  /// 格式化 URL，自动添加 https:// 前缀
  static String formatUrl(String input) {
    if (input.isEmpty) return input;
    
    input = input.trim();
    
    // 如果已经有协议，直接返回
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }
    
    // 如果是有效的域名或 URL，添加 https:// 前缀
    if (isValidUrl(input)) {
      return 'https://$input';
    }
    
    return input;
  }
  
  /// 打开 URL
  static Future<bool> openUrl(String url) async {
    try {
      final formattedUrl = formatUrl(url);
      final uri = Uri.parse(formattedUrl);
      
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// 在应用内打开 URL
  static Future<bool> openUrlInApp(BuildContext context, String url) async {
    try {
      final formattedUrl = formatUrl(url);
      
      // 导航到 WebView 页面
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: formattedUrl,
            title: _extractDomainFromUrl(formattedUrl),
          ),
        ),
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 从 URL 中提取域名作为标题
  static String _extractDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : 'DApp';
    } catch (e) {
      return 'DApp';
    }
  }
  
  /// 检查是否为搜索查询（非 URL）
  static bool isSearchQuery(String input) {
    return !isValidUrl(input);
  }
}