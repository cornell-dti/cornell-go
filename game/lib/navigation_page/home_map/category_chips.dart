import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:game/constants/constants.dart';
import 'package:game/navigation_page/home_map/home_map_categories.dart';

/**
 * Category Chips - Horizontal filter chips for Home Map.
 *
 * This widget renders the category "pills" used to filter visible map pins.
 *
 * @param selectedIndex - Currently selected category index (or null for none).
 * @param onCategorySelected - Callback when a category is tapped.
 */

class CategoryChipsRow extends StatelessWidget {
  const CategoryChipsRow({
    super.key,
    required this.selectedIndex,
    required this.onCategorySelected,
    this.categories = homeMapCategories,
  });

  final int? selectedIndex;
  final ValueChanged<int> onCategorySelected;
  final List<HomeMapCategory> categories;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _CategoryChipsScrollClipper(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 14),
          child: Row(
            children: [
              for (var i = 0; i < categories.length; i++) ...[
                _CategoryChip(
                  label: categories[i].label,
                  iconAsset: categories[i].chipIconAsset,
                  selected: selectedIndex != null && i == selectedIndex,
                  onTap: () => onCategorySelected(i),
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChipsScrollClipper extends CustomClipper<Path> {
  const _CategoryChipsScrollClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(Rect.fromLTRB(-16, -8, size.width, size.height + 20));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      tween: Tween<double>(end: selected ? 1 : 0),
      builder: (_, t, __) {
        final fg = Color.lerp(AppColors.mediumGray, AppColors.purple, t)!;
        final bc = Color.lerp(Colors.transparent, AppColors.purple, t)!;
        return Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bc, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black10,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    iconAsset,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
