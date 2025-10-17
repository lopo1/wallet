import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Persistent bottom navigation bar with Harbor branding and animated selection.
class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _lineController;
  late Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _lineAnimation = Tween<double>(
      begin: widget.selectedIndex.toDouble(),
      end: widget.selectedIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _lineController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _lineAnimation = Tween<double>(
        begin: oldWidget.selectedIndex.toDouble(),
        end: widget.selectedIndex.toDouble(),
      ).animate(CurvedAnimation(
        parent: _lineController,
        curve: Curves.easeInOut,
      ));
      _lineController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2D3A),
      ),
      child: Stack(
        children: [
          // 动态水平线 - 跟随突出图标
          AnimatedBuilder(
            animation: _lineAnimation,
            builder: (context, child) {
              final screenWidth = MediaQuery.of(context).size.width;
              final itemWidth = screenWidth / 4;

              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(screenWidth, 35), // 增加高度以适应半圆的高度
                  painter: _TopLinePainter(
                    selectedPosition: _lineAnimation.value,
                    itemWidth: itemWidth,
                  ),
                ),
              );
            },
          ),
          // 导航项
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NavItem(
                index: 0,
                label: 'Harbor',
                isSelected: widget.selectedIndex == 0,
                iconBuilder: (selected) => SvgPicture.asset(
                  'assets/images/harbor_logo.svg',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    selected ? Colors.white : Colors.white70,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () => widget.onItemSelected(0),
              ),
              _NavItem(
                index: 1,
                label: '兑换',
                isSelected: widget.selectedIndex == 1,
                iconBuilder: (selected) => Icon(
                  Icons.swap_horiz,
                  color: selected ? Colors.white : Colors.white70,
                  size: 20,
                ),
                onTap: () => widget.onItemSelected(1),
              ),
              _NavItem(
                index: 2,
                label: '发现',
                isSelected: widget.selectedIndex == 2,
                iconBuilder: (selected) => Icon(
                  Icons.explore,
                  color: selected ? Colors.white : Colors.white70,
                  size: 20,
                ),
                onTap: () => widget.onItemSelected(2),
              ),
              _NavItem(
                index: 3,
                label: '设置',
                isSelected: widget.selectedIndex == 3,
                iconBuilder: (selected) => Icon(
                  Icons.settings,
                  color: selected ? Colors.white : Colors.white70,
                  size: 20,
                ),
                onTap: () => widget.onItemSelected(3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final String label;
  final bool isSelected;
  final Widget Function(bool selected) iconBuilder;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.label,
    required this.isSelected,
    required this.iconBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Top protruding circle + ripple appears only when selected
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              top: isSelected ? -12 : -6,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: isSelected ? 1 : 0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple
                    AnimatedScale(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOut,
                      scale: isSelected ? 1.1 : 0.0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF8B5CF6).withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Main circle with icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: iconBuilder(true)),
                    ),
                  ],
                ),
              ),
            ),

            // Content; when not selected, show the icon (dimmed)
            Positioned(
              bottom: 30, // 增加底部间距，从8调整到16
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isSelected
                        ? const SizedBox(height: 6) // 进一步减少占位空间，从16调整到12
                        : Opacity(
                            key: const ValueKey('unselected_icon'),
                            opacity: 0.75,
                            child: iconBuilder(false),
                          ),
                  ),
                  const SizedBox(height: 2), // 进一步减少图标和文字之间的间距，从4调整到2
                  Text(
                    label,
                    style: TextStyle(
                      color:
                          isSelected ? const Color(0xFF8B5CF6) : Colors.white70,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 自定义画笔，绘制被突出图标"顶起"的水平线效果
class _TopLinePainter extends CustomPainter {
  final double selectedPosition;
  final double itemWidth;

  _TopLinePainter({
    required this.selectedPosition,
    required this.itemWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 使用与底部菜单背景相同的颜色
    final paint = Paint()
      ..color = const Color(0xFF2A2D3A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = selectedPosition * itemWidth + itemWidth / 2;
    const lineY = 15.0; // 固定的水平线Y位置，不会被推起

    // 破土参数
    const holeWidth = 50.0; // 破土洞口的宽度
    const crackWidth = 8.0; // 裂缝的宽度

    // 创建主水平线路径
    final mainPath = Path();
    mainPath.moveTo(0, lineY);

    // 绘制到破土区域左侧
    if (centerX - holeWidth / 2 > 0) {
      mainPath.lineTo(centerX - holeWidth / 2, lineY);
    }

    // 跳过破土区域，从右侧继续
    if (centerX + holeWidth / 2 < size.width) {
      mainPath.moveTo(centerX + holeWidth / 2, lineY);
      mainPath.lineTo(size.width, lineY);
    }

    // 绘制主水平线
    canvas.drawPath(mainPath, paint);

    // 绘制破土的裂缝效果
    final crackPaint = Paint()
      ..color = const Color(0xFF2A2D3A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 左侧裂缝
    final leftCrackPath = Path();
    leftCrackPath.moveTo(centerX - holeWidth / 2, lineY);
    leftCrackPath.quadraticBezierTo(
      centerX - holeWidth / 3,
      lineY - crackWidth / 2,
      centerX - holeWidth / 4,
      lineY - crackWidth,
    );
    leftCrackPath.quadraticBezierTo(
      centerX - holeWidth / 6,
      lineY - crackWidth * 1.2,
      centerX - holeWidth / 8,
      lineY - crackWidth * 0.8,
    );

    // 右侧裂缝
    final rightCrackPath = Path();
    rightCrackPath.moveTo(centerX + holeWidth / 2, lineY);
    rightCrackPath.quadraticBezierTo(
      centerX + holeWidth / 3,
      lineY - crackWidth / 2,
      centerX + holeWidth / 4,
      lineY - crackWidth,
    );
    rightCrackPath.quadraticBezierTo(
      centerX + holeWidth / 6,
      lineY - crackWidth * 1.2,
      centerX + holeWidth / 8,
      lineY - crackWidth * 0.8,
    );

    // 绘制裂缝
    canvas.drawPath(leftCrackPath, crackPaint);
    canvas.drawPath(rightCrackPath, crackPaint);

    // 添加破土边缘的碎片效果
    final fragmentPaint = Paint()
      ..color = const Color(0xFF2A2D3A).withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 绘制一些小碎片
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (3.14159 / 180); // 转换为弧度
      final fragmentX = centerX + (holeWidth / 3) * cos(angle);
      final fragmentY = lineY - 3 + 2 * sin(angle * 2);

      canvas.drawCircle(
        Offset(fragmentX, fragmentY),
        1.0,
        fragmentPaint,
      );
    }

    // 添加阴影效果
    final shadowPaint = Paint()
      ..color = const Color(0xFF2A2D3A).withValues(alpha: 0.3)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawPath(mainPath, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant _TopLinePainter oldDelegate) {
    return oldDelegate.selectedPosition != selectedPosition ||
        oldDelegate.itemWidth != itemWidth;
  }
}
