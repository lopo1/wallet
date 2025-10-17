import 'package:flutter/material.dart';

/// 自定义裁剪器，用于创建圆形凹陷效果
class NotchedClipper extends CustomClipper<Path> {
  final bool hasTopNotch;
  final bool hasBottomNotch;
  final double notchRadius;
  final double notchMargin;

  NotchedClipper({
    this.hasTopNotch = false,
    this.hasBottomNotch = false,
    this.notchRadius = 24.0, // 图标半径22 + 2px间隔
    this.notchMargin = 2.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final double width = size.width;
    final double height = size.height;
    
    // 计算凹陷的实际半径（图标半径 + 边距）
    final double actualNotchRadius = notchRadius;
    
    // 开始绘制路径
    path.moveTo(0, 0);
    
    if (hasTopNotch) {
      // 绘制到顶部凹陷开始位置
      path.lineTo(width / 2 - actualNotchRadius, 0);
      // 绘制顶部凹陷（向内的半圆）
      path.arcToPoint(
        Offset(width / 2 + actualNotchRadius, 0),
        radius: Radius.circular(actualNotchRadius),
        clockwise: false,
      );
      // 继续到右上角
      path.lineTo(width, 0);
    } else {
      path.lineTo(width, 0);
    }
    
    // 右边
    path.lineTo(width, height);
    
    if (hasBottomNotch) {
      // 绘制到底部凹陷开始位置
      path.lineTo(width / 2 + actualNotchRadius, height);
      // 绘制底部凹陷（向内的半圆）
      path.arcToPoint(
        Offset(width / 2 - actualNotchRadius, height),
        radius: Radius.circular(actualNotchRadius),
        clockwise: false,
      );
      // 继续到左下角
      path.lineTo(0, height);
    } else {
      path.lineTo(0, height);
    }
    
    // 左边
    path.lineTo(0, 0);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// 带凹陷效果的容器组件
class NotchedContainer extends StatelessWidget {
  final Widget child;
  final bool hasTopNotch;
  final bool hasBottomNotch;
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final Border? border;
  final EdgeInsets padding;
  final double notchRadius;
  final double notchMargin;

  const NotchedContainer({
    super.key,
    required this.child,
    this.hasTopNotch = false,
    this.hasBottomNotch = false,
    this.backgroundColor = const Color(0xFF1A1A2E),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.border,
    this.padding = const EdgeInsets.all(16),
    this.notchRadius = 24.0,
    this.notchMargin = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    // 计算动态内边距，避免内容被凹陷区域覆盖
    EdgeInsets dynamicPadding = padding;
    
    if (hasTopNotch) {
      // 顶部有凹陷时，增加顶部内边距
      dynamicPadding = EdgeInsets.fromLTRB(
        padding.left,
        padding.top + notchRadius / 2, // 增加凹陷半径的一半作为安全距离
        padding.right,
        padding.bottom,
      );
    }
    
    if (hasBottomNotch) {
      // 底部有凹陷时，增加底部内边距
      dynamicPadding = EdgeInsets.fromLTRB(
        dynamicPadding.left,
        dynamicPadding.top,
        dynamicPadding.right,
        dynamicPadding.bottom + notchRadius / 2, // 增加凹陷半径的一半作为安全距离
      );
    }
    
    return ClipPath(
      clipper: NotchedClipper(
        hasTopNotch: hasTopNotch,
        hasBottomNotch: hasBottomNotch,
        notchRadius: notchRadius,
        notchMargin: notchMargin,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: border,
        ),
        padding: dynamicPadding,
        child: child,
      ),
    );
  }
}