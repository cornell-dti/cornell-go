import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/constants/constants.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:intl/intl.dart';

/**
 * Custom journey creation page 
 * TODO: connect to backend 
 */
class CustomJourneyCreationsPage extends StatefulWidget {
  const CustomJourneyCreationsPage({super.key});

  @override
  State<CustomJourneyCreationsPage> createState() =>
      _CustomJourneyCreationsPageState();
}

class _CustomJourneyCreationsPageState
    extends State<CustomJourneyCreationsPage> {
  static const double _fieldWidth = 345;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  /// Set only via datetime picker (not typed).
  DateTime? _startDateTime;

  final Set<String> _selectedCategories = {};
  String? _selectedDifficulty;

  static const List<String> _categories = [
    'Food',
    'Cafe',
    'Libraries',
    'Other',
  ];

  static const List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFormFieldChanged);
    _descriptionController.addListener(_onFormFieldChanged);
  }

  void _onFormFieldChanged() => setState(() {});

  // True when all fields are filled out
  bool get _canProceed {
    return _nameController.text.trim().isNotEmpty &&
        _selectedCategories.isNotEmpty &&
        _selectedDifficulty != null &&
        _startDateTime != null &&
        _descriptionController.text.trim().isNotEmpty;
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormFieldChanged);
    _descriptionController.removeListener(_onFormFieldChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _darkFieldDecoration({String? hint, int? hintMaxLines}) {
    return InputDecoration(
      hintText: hint,
      hintMaxLines: hintMaxLines,
      filled: true,
      fillColor: AppColors.black50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(
        color: AppColors.white50,
        fontFamily: 'Poppins',
        fontSize: 14,
      ),
    );
  }

  TextStyle get _fieldTextStyle => const TextStyle(
        color: AppColors.white,
        fontFamily: 'Poppins',
        fontSize: 14,
      );

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
      ),
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.cream : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.darkText,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    await DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(now.year - 1, 1, 1),
      maxTime: DateTime(now.year + 5, 12, 31, 23, 59),
      currentTime: _startDateTime ?? now,
      locale: LocaleType.en,
      onConfirm: (date) {
        if (!mounted) return;
        setState(() => _startDateTime = date);
      },
    );
  }

  Widget _startDateSelector() {
    final hasValue = _startDateTime != null;
    final label = hasValue
        ? DateFormat('MM/dd/yyyy HH:mm').format(_startDateTime!)
        : 'Choose date & time';

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: _pickStartDate,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.black50,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: hasValue ? AppColors.white : AppColors.white50,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: hasValue ? AppColors.white : AppColors.white50,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: SizedBox(
              width: _fieldWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Journey Name'),
                  TextField(
                    controller: _nameController,
                    style: _fieldTextStyle,
                    decoration: _darkFieldDecoration(
                      hint: 'e.g. study spots',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel('Categories'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((c) {
                      return _pill(
                        label: c,
                        selected: _selectedCategories.contains(c),
                        onTap: () => _toggleCategory(c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel('Difficulty Level'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _difficulties.map((d) {
                      return _pill(
                        label: d,
                        selected: _selectedDifficulty == d,
                        onTap: () => setState(() => _selectedDifficulty = d),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Points',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SvgPicture.asset(
                        'assets/icons/bearcoins.svg',
                        width: 28,
                        height: 28,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '100 PTS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel('Start Date'),
                  _startDateSelector(),
                  const SizedBox(height: 24),
                  _sectionLabel('Description'),
                  TextField(
                    controller: _descriptionController,
                    style: _fieldTextStyle,
                    maxLines: 5,
                    decoration: _darkFieldDecoration(
                      hint:
                          'Add some more details to the locations so that your friends will join!',
                      hintMaxLines: 5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: _canProceed
                          ? AppColors.primaryRed
                          : AppColors.primaryRed.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap:
                            () {}, //TODO: redirect to first page of Challenge Selection flow
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          child: Text(
                            'Next',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
