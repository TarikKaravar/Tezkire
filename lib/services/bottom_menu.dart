import 'package:flutter/material.dart';

class BottomMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomMenu({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unselectedColor = theme.iconTheme.color ?? Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, icon: Icons.home_rounded, label: 'Ana Sayfa', index: 0, selectedIndex: selectedIndex),
              _buildNavItem(context, icon: Icons.notifications_rounded, label: 'Bildirimler', index: 1, selectedIndex: selectedIndex),
              _buildNavItem(context, icon: Icons.person_rounded, label: 'Profil', index: 2, selectedIndex: selectedIndex),
              _buildNavItem(context, icon: Icons.settings_rounded, label: 'Ayarlar', index: 3, selectedIndex: selectedIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required int selectedIndex,
  }) {
    final isSelected = index == selectedIndex;
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = Theme.of(context).iconTheme.color ?? Colors.grey;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? selectedColor.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 28 : 24,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 12 : 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
