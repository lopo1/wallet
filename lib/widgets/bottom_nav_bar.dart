import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Persistent bottom navigation bar with Harbor branding and animated selection.
class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86, // 增加整体高度以提供更多底部间距
      decoration: const BoxDecoration(
        color: Color(0xFF2A2D3A),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NavItem(
            index: 0,
            label: 'Harbor',
            isSelected: selectedIndex == 0,
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
            onTap: () => onItemSelected(0),
          ),
          _NavItem(
            index: 1,
            label: '兑换',
            isSelected: selectedIndex == 1,
            iconBuilder: (selected) => Icon(
              Icons.swap_horiz,
              color: selected ? Colors.white : Colors.white70,
              size: 20,
            ),
            onTap: () => onItemSelected(1),
          ),
          _NavItem(
            index: 2,
            label: '发现',
            isSelected: selectedIndex == 2,
            iconBuilder: (selected) => Icon(
              Icons.explore,
              color: selected ? Colors.white : Colors.white70,
              size: 20,
            ),
            onTap: () => onItemSelected(2),
          ),
          _NavItem(
            index: 3,
            label: '设置',
            isSelected: selectedIndex == 3,
            iconBuilder: (selected) => Icon(
              Icons.settings,
              color: selected ? Colors.white : Colors.white70,
              size: 20,
            ),
            onTap: () => onItemSelected(3),
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
