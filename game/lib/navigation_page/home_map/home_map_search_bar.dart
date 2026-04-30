import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:game/constants/constants.dart';

/**
 * Search Bar - Expandable Home Map search + filters UI.
 *
 * A self-contained widget that renders the Home Map search field and the
 * expandable filter panel (distance/time/date).
 *
 * @remarks
 * This widget currently manages its filter state locally. When we wire this to
 * backend search/filtering, we can hoist state out via callbacks.
 */

class HomeMapSearchBarExpandable extends StatefulWidget {
  const HomeMapSearchBarExpandable({super.key});

  @override
  State<HomeMapSearchBarExpandable> createState() =>
      _HomeMapSearchBarExpandableState();
}

class _HomeMapSearchBarExpandableState
    extends State<HomeMapSearchBarExpandable> {
  // Local filter state
  bool _expanded = false;
  String? _distance = '5 min';
  String? _time;
  String? _date;

  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() => setState(() {});

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChanged);
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleFilter() {
    setState(() => _expanded = !_expanded);
  }

  ColorFilter? get _filterIconColorFilter {
    // Filter icon color priority: focus > expanded > idle.
    if (_searchFocus.hasFocus) {
      return const ColorFilter.mode(AppColors.grayText, BlendMode.srcIn);
    }
    if (_expanded) {
      return const ColorFilter.mode(AppColors.purple, BlendMode.srcIn);
    }
    return const ColorFilter.mode(AppColors.black30, BlendMode.srcIn);
  }

  @override
  Widget build(BuildContext context) {
    final searchFocused = _searchFocus.hasFocus;
    final dH = MediaQuery.sizeOf(context).height;
    final barH = dH * 0.055;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          width: 1,
          color: searchFocused ? AppColors.lightGray : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: searchFocused ? AppColors.black20 : AppColors.black10,
            blurRadius: searchFocused ? 16 : 10,
            offset: Offset(0, searchFocused ? 6 : 4),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: barH,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  TextField(
                    focusNode: _searchFocus,
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    textAlignVertical: TextAlignVertical.center,
                    cursorWidth: 1.5,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      color: AppColors.grayText,
                    ),
                    cursorColor: AppColors.darkText,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      prefixIcon: Icon(
                        Icons.search,
                        color: searchFocused
                            ? AppColors.darkText
                            : AppColors.black30,
                        size: 20,
                      ),
                      hintText: searchFocused
                          ? null
                          : 'Search a name, location, etc...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: AppColors.black30,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: 50,
                      height: 36,
                      child: Center(
                        child: InkResponse(
                          onTap: _toggleFilter,
                          radius: 22,
                          child: SvgPicture.asset(
                            'assets/icons/Group 578.svg',
                            width: 32,
                            height: 32,
                            colorFilter: _filterIconColorFilter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.lightGrayBorder,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FilterColumn(
                        title: 'Distance',
                        children: [
                          _FilterCheckboxRow(
                            label: '5 min',
                            value: _distance == '5 min',
                            onChanged: (v) =>
                                setState(() => _distance = v ? '5 min' : null),
                          ),
                          _FilterCheckboxRow(
                            label: '15 min',
                            value: _distance == '15 min',
                            onChanged: (v) =>
                                setState(() => _distance = v ? '15 min' : null),
                          ),
                          _FilterCheckboxRow(
                            label: '20+ min',
                            value: _distance == '20+ min',
                            onChanged: (v) => setState(
                                () => _distance = v ? '20+ min' : null),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _FilterColumn(
                        title: 'Time',
                        children: [
                          _FilterCheckboxRow(
                            label: 'Current',
                            value: _time == 'Current',
                            onChanged: (v) =>
                                setState(() => _time = v ? 'Current' : null),
                          ),
                          _FilterCheckboxRow(
                            label: '30 mins',
                            value: _time == '30 mins',
                            onChanged: (v) =>
                                setState(() => _time = v ? '30 mins' : null),
                          ),
                          _FilterCheckboxRow(
                            label: '1+ hour',
                            value: _time == '1+ hour',
                            onChanged: (v) =>
                                setState(() => _time = v ? '1+ hour' : null),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _FilterColumn(
                        title: 'Date',
                        children: [
                          _FilterCheckboxRow(
                            label: 'Today',
                            value: _date == 'Today',
                            onChanged: (v) =>
                                setState(() => _date = v ? 'Today' : null),
                          ),
                          _FilterCheckboxRow(
                            label: 'Tomorrow',
                            value: _date == 'Tomorrow',
                            onChanged: (v) =>
                                setState(() => _date = v ? 'Tomorrow' : null),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: InkWell(
                              onTap: () => setState(() => _date = 'Custom'),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 18,
                                      color: _date == 'Custom'
                                          ? AppColors.purple
                                          : AppColors.grayText,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Custom',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                        color: _date == 'Custom'
                                            ? AppColors.purple
                                            : AppColors.darkText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ElevatedButton(
                  onPressed: () => setState(() => _expanded = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterColumn extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FilterColumn({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _FilterCheckboxRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FilterCheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Checkbox(
                    value: value,
                    onChanged: (v) => onChanged(v ?? false),
                    checkColor: Colors.transparent,
                    fillColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? const Color(0x4C865C7F)
                          : Colors.white,
                    ),
                    side: WidgetStateBorderSide.resolveWith(
                      (states) => BorderSide(
                        color: states.contains(WidgetState.selected)
                            ? AppColors.purple
                            : AppColors.borderGray,
                        width: states.contains(WidgetState.selected) ? 2 : 1.5,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  if (value)
                    const Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.purple,
                        ),
                        Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: AppColors.purple,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: value ? AppColors.purple : AppColors.darkText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
