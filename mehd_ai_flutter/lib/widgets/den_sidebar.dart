import 'package:flutter/material.dart';
import 'dart:ui';

class DenSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;

  const DenSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _SideItem(
        icon: Icons.terminal,
        label: 'Terminal',
        color: const Color(0xFF58A6FF)),
      _SideItem(
        icon: Icons.candlestick_chart,
        label: 'Markets',
        color: const Color(0xFF00FF88)),
      _SideItem(
        icon: Icons.show_chart,
        label: 'Positions',
        color: const Color(0xFFD29922)),
      _SideItem(
        icon: Icons.history,
        label: 'History',
        color: const Color(0xFF4ECDC4)),
      _SideItem(
        icon: Icons.shield,
        label: 'War Room',
        color: const Color(0xFFFF3B3B)),
      _SideItem(
        icon: Icons.groups,
        label: 'Platoon',
        color: const Color(0xFF00FF88)),
      _SideItem(
        icon: Icons.hub,
        label: 'Data Moat',
        color: const Color(0xFF00E5FF)),
      _SideItem(
        icon: Icons.settings,
        label: 'Settings',
        color: const Color(0xFF888888)),
    ];

    return Container(
      width: 72,
      color: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: items.asMap().entries
          .map((e) => _buildItem(e.value, e.key, context))
          .toList(),
      ),
    );
  }

  Widget _buildItem(_SideItem item, int index, BuildContext ctx) {
    final isSelected = selectedIndex == index;

    return Tooltip(
      message: item.label,
      preferBelow: false,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: item.color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4)),
      textStyle: TextStyle(
        color: item.color,
        fontSize: 10,
        letterSpacing: 0.5),
      child: GestureDetector(
        onTap: () => onSelect(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          width: 56,
          height: 56,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? item.color.withOpacity(0.15) : Colors.white.withOpacity(0.02),
                  border: Border.all(
                    color: isSelected ? item.color.withOpacity(0.6) : Colors.white.withOpacity(0.05),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: item.color.withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
                  ] : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon,
                      size: 20,
                      color: isSelected ? item.color : const Color(0xFF888888),
                      shadows: isSelected
                        ? [Shadow(color: item.color.withOpacity(0.8), blurRadius: 12)]
                        : []),
                    const SizedBox(height: 2),
                    Text(item.label,
                      style: TextStyle(
                        color: isSelected ? item.color : const Color(0xFF666666),
                        fontSize: 6,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        letterSpacing: 0.3),
                      overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _SideItem {
  final IconData icon;
  final String label;
  final Color color;
  _SideItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
