import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../utils/colors.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final MainTab selected;
  final ValueChanged<MainTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(color: AppColors.stroke.withValues(alpha: 0.6)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: MainTab.values
              .map(
                (tab) => NavItem(
                  tab: tab,
                  selected: selected == tab,
                  onTap: () => onSelected(tab),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final MainTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (tab) {
      MainTab.catalog => Icons.home_filled,
      MainTab.payment => Icons.credit_card,
      MainTab.cart => Icons.shopping_cart,
      MainTab.profile => Icons.person,
    };
    final label = switch (tab) {
      MainTab.catalog => 'KATALOG',
      MainTab.payment => 'PAYMENT',
      MainTab.cart => 'CART',
      MainTab.profile => 'PROFILE',
    };
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.cyan.withValues(alpha: 0.22) : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.cyan : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.cyan : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
