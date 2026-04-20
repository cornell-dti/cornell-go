import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/constants/constants.dart';
import 'package:game/journeys/challenge_creation_page.dart';
import 'package:game/model/user_model.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Custom journey creation page
/// Fields: Journey Name (text box), Categories (selection pills), Difficulty Level (selection pills), Start Date (DateTime picker), Description
/// The Next button is disabled until all fields are filled out. 
/// 
/// Once the Next button is clicked, creates an [EventBase] with isJourney:true, and redirects to placeholder challenge_creation_page
/// The user creating the event is required to be a manager of an organization. 
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

  DateTime? _startDateTime;

  String? _selectedCategory;
  String? _selectedDifficulty;

  static const List<String> _categories = [
    'Food',
    'Cafe',
    'Nature',
    'Other',
  ];

  static const List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

  /// Default map center (Ithaca) — matches server `defaultEventData`.
  static const double _defaultLatitude = 42.44755580740012;
  static const double _defaultLongitude = -76.48504614830019;

  bool _isSubmitting = false;

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
        _selectedCategory != null &&
        _selectedDifficulty != null &&
        _startDateTime != null &&
        _descriptionController.text.trim().isNotEmpty;
  }

  EventCategoryDto _eventCategoryDtoFromUi(String label) {
    switch (label) {
      case 'Food':
        return EventCategoryDto.FOOD;
      case 'Cafe':
        return EventCategoryDto.CAFE;
      case 'Nature':
        return EventCategoryDto.NATURE;
      case 'Other':
        return EventCategoryDto.HISTORICAL;
      default:
        return EventCategoryDto.FOOD;
    }
  }

  EventDifficultyDto _mapDifficulty(String d) {
    switch (d) {
      case 'Easy':
        return EventDifficultyDto.Easy;
      case 'Medium':
        return EventDifficultyDto.Normal;
      case 'Hard':
        return EventDifficultyDto.Hard;
      default:
        return EventDifficultyDto.Normal;
    }
  }

  String _trimDescription(int maxChars) {
    final t = _descriptionController.text.trim();
    if (t.length <= maxChars) return t;
    return t.substring(0, maxChars);
  }

  String _longDescriptionForEvent() {
    final start =
        DateFormat('MM/dd/yyyy h:mm a', 'en_US').format(_startDateTime!);
    final body = _descriptionController.text.trim();
    return 'Scheduled start: $start\nCategory: $_selectedCategory\n\n$body';
  }

  /// Creates `EventBase` with `isJourney: true` on the server, then opens challenge flow.
  Future<void> _onTapNext() async {
    if (!_canProceed) {
      displayToast(
        'All fields must be filled out.',
        Status.error,
      );
      return;
    }
    if (_startDateTime!.isBefore(DateTime.now())) {
      displayToast(
        'Start date and time cannot be in the past.',
        Status.error,
      );
      return;
    }
    if (_isSubmitting) return;

    final api = Provider.of<ApiClient>(context, listen: false);
    final userModel = Provider.of<UserModel>(context, listen: false);
    final userId = userModel.userData?.id;

    if (userId == null) {
      displayToast('Sign in to create a journey.', Status.error);
      return;
    }

    String? managedOrgId;
    for (final org in userModel.orgData.values) {
      if (org.managers?.contains(userId) ?? false) {
        managedOrgId = org.id;
        break;
      }
    }
    if (managedOrgId == null) {
      displayToast(
        'You must manage an organization to create a journey.',
        Status.error,
      );
      return;
    }

    if (api.serverApi == null) {
      displayToast('Not connected to server.', Status.error);
      return;
    }

    setState(() => _isSubmitting = true);

    final longRaw = _longDescriptionForEvent();
    final longForServer =
        longRaw.length > 8192 ? longRaw.substring(0, 8192) : longRaw;

    final eventDto = EventDto(
      id: '',
      requiredMembers: 1,
      name: _nameController.text.trim(),
      description: _trimDescription(2048),
      longDescription: longForServer,
      category: _eventCategoryDtoFromUi(_selectedCategory!),
      timeLimitation: EventTimeLimitationDto.PERPETUAL,
      endTime: DateTime.utc(2060, 1, 1).toIso8601String(),
      initialOrganizationId: managedOrgId,
      difficulty: _mapDifficulty(_selectedDifficulty!),
      indexable: true,
      latitudeF: _defaultLatitude,
      longitudeF: _defaultLongitude,
      featured: false,
      isJourney: true,
    );

    try {
      final result = await api.serverApi!.updateEventData(
        UpdateEventDataDto(
          event: eventDto,
          deleted: false,
        ),
      );

      if (!mounted) return;

      if (result == null || result.isEmpty) {
        displayToast(
          'Could not create journey. Check permissions or try again.',
          Status.error,
        );
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => ChallengeCreationPage(
            createdEventId: result,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        displayToast(
          'Could not create journey. Try again.',
          Status.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormFieldChanged);
    _descriptionController.removeListener(_onFormFieldChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({String? hint, int? hintMaxLines}) {
    const radius = BorderRadius.all(Radius.circular(8));
    const borderSide = BorderSide(color: AppColors.borderGray);
    return InputDecoration(
      hintText: hint,
      hintMaxLines: hintMaxLines,
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: borderSide,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.primaryRed, width: 1.5),
      ),
      hintStyle: const TextStyle(
        color: AppColors.grayText,
        fontFamily: 'Poppins',
        fontSize: 14,
      ),
    );
  }

  TextStyle get _fieldTextStyle => const TextStyle(
        color: AppColors.darkText,
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

  /// Date first, then 12-hour time with AM/PM (`showTime12hPicker`).
  /// Past calendar days are disabled; combined start must not be before now.
  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final maxTime = DateTime(now.year + 5, 12, 31, 23, 59);

    var initial = _startDateTime ?? now;
    if (initial.isBefore(startOfToday)) {
      initial = now;
    }

    final pickedDate = await DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: startOfToday,
      maxTime: maxTime,
      currentTime: initial,
      locale: LocaleType.en,
    );
    if (!mounted || pickedDate == null) return;

    final timeSeed = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      initial.hour,
      initial.minute,
    );

    final pickedClock = await DatePicker.showTime12hPicker(
      context,
      showTitleActions: true,
      currentTime: timeSeed,
      locale: LocaleType.en,
    );
    if (!mounted || pickedClock == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedClock.hour,
      pickedClock.minute,
    );

    if (combined.isBefore(DateTime.now())) {
      displayToast(
        'Choose a time in the future for that date.',
        Status.error,
      );
      return;
    }

    setState(() => _startDateTime = combined);
  }

  Widget _startDateSelector() {
    final hasValue = _startDateTime != null;
    final label = hasValue
        ? DateFormat('MM/dd/yyyy h:mm a', 'en_US').format(_startDateTime!)
        : 'Choose date & time';

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: _pickStartDate,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderGray),
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
                    color: hasValue ? AppColors.darkText : AppColors.grayText,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: hasValue ? AppColors.darkText : AppColors.grayText,
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
                    decoration: _fieldDecoration(
                      hint: 'e.g. study spots',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel('Category'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((c) {
                      return _pill(
                        label: c,
                        selected: _selectedCategory == c,
                        onTap: () =>
                            setState(() => _selectedCategory = c),
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
                    decoration: _fieldDecoration(
                      hint:
                          'Add some more details to the locations so that your friends will join!',
                      hintMaxLines: 5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: _canProceed && !_isSubmitting
                          ? AppColors.primaryRed
                          : AppColors.primaryRed.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: _isSubmitting ? null : _onTapNext,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text(
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
