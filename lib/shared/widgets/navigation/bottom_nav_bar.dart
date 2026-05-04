// lib/widgets/navigation/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: AppAssets.home, activeIcon: AppAssets.home),
      (icon: AppAssets.store, activeIcon: AppAssets.store),
      (icon: AppAssets.heart, activeIcon: AppAssets.heart),
      (icon: AppAssets.personOutline, activeIcon: AppAssets.personOutline),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary1,
          unselectedItemColor: Colors.black,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          onTap: onItemTapped,
          items:
              items.map((item) {
                return BottomNavigationBarItem(
                  icon: _buildIcon(item.icon, false),
                  activeIcon: _buildIcon(item.activeIcon, true),
                  label: '',
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildIcon(String assetPath, bool isSelected) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SvgPicture.asset(
          assetPath,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            isSelected ? AppColors.primary1 : Colors.black,
            BlendMode.srcIn,
          ),
        ),
        if (isSelected)
          const Positioned(bottom: -8, left: 0, right: 0, child: _Dot()),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.primary1,
        shape: BoxShape.circle,
      ),
    );
  }
}