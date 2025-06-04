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
    final screenWidth = MediaQuery.of(context).size.width;

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
        child: SizedBox(
          height: 75,
          child: Row(
            children: [
              _buildNavItem(
                context, 
                icon: Icons.home_rounded, 
                label: 'Ana Sayfa', 
                index: 0,
                width: screenWidth / 4,
              ),
              _buildNavItem(
                context, 
                icon: Icons.notifications_rounded, 
                label: 'Bildirim', 
                index: 1,
                width: screenWidth / 4,
              ),
              _buildNavItem(
                context, 
                icon: Icons.person_rounded, 
                label: 'Profil', 
                index: 2,
                width: screenWidth / 4,
              ),
              _buildNavItem(
                context, 
                icon: Icons.settings_rounded, 
                label: 'Ayarlar', 
                index: 3,
                width: screenWidth / 4,
              ),
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
    required double width,
  }) {
    final isSelected = index == selectedIndex;
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = Colors.grey.shade600;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? selectedColor.withOpacity(0.15) : Colors.transparent,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: width - 8,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? selectedColor : unselectedColor,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
