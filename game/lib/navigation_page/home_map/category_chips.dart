import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:game/constants/constants.dart';

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
  });

  final int? selectedIndex;
  final ValueChanged<int> onCategorySelected;

  static const _chips = <_CategoryChipData>[
    _CategoryChipData(label: 'Food', iconAsset: 'assets/icons/burger.svg'),
    _CategoryChipData(label: 'Swag', iconAsset: 'assets/icons/fund.svg'),
    _CategoryChipData(label: 'Concerts', iconAsset: 'assets/icons/mic.svg'),
    _CategoryChipData(label: 'Speakers', iconAsset: 'assets/icons/speaker.svg'),
  ];

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
              for (var i = 0; i < _chips.length; i++) ...[
                _CategoryChip(
                  data: _chips[i],
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

class _CategoryChipData {
  final String label;
  final String iconAsset;

  const _CategoryChipData({required this.label, required this.iconAsset});
}

class _CategoryChip extends StatelessWidget {
  final _CategoryChipData data;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.data,
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
          clipBehavior: Clip.none,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: bc, width: 1.5),
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
                    data.iconAsset,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
