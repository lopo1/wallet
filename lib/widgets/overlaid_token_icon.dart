import 'package:flutter/material.dart';

/// 叠加图标组件，用于显示代币图标和链图标的叠加效果
class OverlaidTokenIcon extends StatelessWidget {
  /// 代币图标（主图标）
  final Widget tokenIcon;

  /// 链图标（叠加图标）
  final Widget chainIcon;

  /// 主图标尺寸
  final double size;

  /// 链图标相对于主图标的比例（默认1/3）
  final double chainIconRatio;

  /// 链图标边框宽度
  final double borderWidth;

  /// 链图标边框颜色
  final Color borderColor;

  const OverlaidTokenIcon({
    super.key,
    required this.tokenIcon,
    required this.chainIcon,
    this.size = 48.0,
    this.chainIconRatio = 0.33,
    this.borderWidth = 2.0,
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final chainIconSize = size * chainIconRatio;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // 主代币图标
          Positioned.fill(
            child: tokenIcon,
          ),
          // 链图标叠加在右下角
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: chainIconSize,
              height: chainIconSize,
              decoration: BoxDecoration(
                color: borderColor,
                shape: BoxShape.circle,
              ),
              child: Container(
                margin: EdgeInsets.all(borderWidth),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: chainIcon,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 便捷构造函数，用于创建带有网络图标的代币图标
class TokenWithNetworkIcon extends StatelessWidget {
  /// 代币信息
  final Map<String, dynamic> asset;

  /// 网络ID
  final String? networkId;

  /// 图标尺寸
  final double size;

  /// 链图标相对比例
  final double chainIconRatio;

  const TokenWithNetworkIcon({
    super.key,
    required this.asset,
    this.networkId,
    this.size = 48.0,
    this.chainIconRatio = 0.33,
  });

  @override
  Widget build(BuildContext context) {
    // 构建代币图标
    final tokenIcon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: (asset['color'] as Color).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: asset['logoUrl'] != null
            ? ClipOval(
                child: Image.network(
                  asset['logoUrl']!,
                  width: size * 0.67, // 约2/3的尺寸
                  height: size * 0.67,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      asset['icon'] as IconData,
                      color: asset['color'] as Color,
                      size: size * 0.5,
                    );
                  },
                ),
              )
            : Icon(
                asset['icon'] as IconData,
                color: asset['color'] as Color,
                size: size * 0.5,
              ),
      ),
    );

    // 确定网络ID，原生代币使用其自身ID作为网络ID
    final effectiveNetworkId = networkId ?? asset['networkId'] ?? asset['id'];

    // 如果没有有效的网络ID，只显示代币图标
    if (effectiveNetworkId == null) {
      return tokenIcon;
    }

    // 构建链图标
    final chainIcon = Container(
      decoration: BoxDecoration(
        color: _getNetworkColor(effectiveNetworkId),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getNetworkIcon(effectiveNetworkId),
        color: Colors.white,
        size: size * chainIconRatio * 0.6, // 链图标内部icon的大小
      ),
    );

    return OverlaidTokenIcon(
      tokenIcon: tokenIcon,
      chainIcon: chainIcon,
      size: size,
      chainIconRatio: chainIconRatio,
    );
  }

  /// 获取网络图标
  IconData _getNetworkIcon(String networkId) {
    switch (networkId) {
      case 'ethereum':
        return Icons.diamond; // 更合适的以太坊图标
      case 'polygon':
        return Icons.hexagon;
      case 'bsc':
        return Icons.currency_exchange;
      case 'bitcoin':
        return Icons.currency_bitcoin;
      case 'solana':
        return Icons.wb_sunny;
      default:
        return Icons.network_check;
    }
  }

  /// 获取网络颜色
  Color _getNetworkColor(String networkId) {
    switch (networkId) {
      case 'ethereum':
        return const Color(0xFF627EEA);
      case 'polygon':
        return const Color(0xFF8247E5);
      case 'bsc':
        return const Color(0xFFF3BA2F);
      case 'bitcoin':
        return const Color(0xFFF7931A);
      case 'solana':
        return const Color(0xFF9945FF);
      default:
        return const Color(0xFF6366F1);
    }
  }
}
