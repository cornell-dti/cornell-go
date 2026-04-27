import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/api/geopoint.dart';
import 'package:game/constants/constants.dart';
import 'package:game/model/campus_event_model.dart';
import 'package:game/utils/google_calendar_utils.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';

/// Draggable bottom sheet listing upcoming challenge events (same pool and
/// filters as [ChallengesPage]), with name, host, and a placeholder GO button.
class EventsDraggableSheet extends StatefulWidget {
  final String? difficulty;
  final List<String>? locations;
  final List<String>? categories;
  final String? searchText;
  final ValueChanged<CampusEventDto>? onGoToEvent;
  final String? selectedEventId;
  final String? routedEventId;
  final VoidCallback? onClearSelection;

  const EventsDraggableSheet({
    super.key,
    this.difficulty,
    this.locations,
    this.categories,
    this.searchText,
    this.onGoToEvent,
    this.selectedEventId,
    this.routedEventId,
    this.onClearSelection,
  });

  @override
  State<EventsDraggableSheet> createState() => _EventsDraggableSheetState();
}

class _EventsDraggableSheetState extends State<EventsDraggableSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  /// User location for distance tie-break (first challenge coords vs. user).
  GeoPoint? _currentUserLocation;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CampusEventModel>().requestCampusEvents(limit: 50);
    });
  }

  Future<void> _loadUserLocation() async {
    try {
      final location = await GeoPoint.current();
      if (mounted) {
        setState(() => _currentUserLocation = location);
      }
    } catch (e) {
      print('Error loading user location for events sheet: $e');
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EventsDraggableSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routedEventId != null &&
        widget.routedEventId != oldWidget.routedEventId) {
      // After GO, keep navigation card compact; do not let sheet fill the screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _snapSheetForRouteView();
      });
    }
  }

  Future<void> _snapSheetForRouteView() async {
    if (!_sheetController.isAttached) return;
    final current = _sheetController.size;
    const target = 0.38;
    if (current > 0.48) {
      await _sheetController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _sheetController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _hostLabel(CampusEventDto event) {
    final organizer = event.organizerName?.trim();
    if (organizer != null && organizer.isNotEmpty) {
      return organizer;
    }
    return 'Cornell';
  }

  String _perkLine(CampusEventDto event) {
    final d = event.description?.trim();
    if (d != null && d.isNotEmpty) {
      final first = d.split(RegExp(r'\n')).first.trim();
      if (first.length <= 48) return first;
    }
    if (event.tags.isNotEmpty) {
      return event.tags.first;
    }
    return event.locationName;
  }

  String _timeLabel(CampusEventDto event) {
    final end = _parseCampusEventTime(event.endTime);
    if (end == null) return '';
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return 'ended';
    if (diff.inDays > 0) return 'in ${diff.inDays}d';
    if (diff.inHours > 0) return 'in ${diff.inHours} hours';
    if (diff.inMinutes > 0) return 'in ${diff.inMinutes} min';
    return 'soon';
  }

  String _formatHourMinute(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute =
        dt.minute == 0 ? '' : ':${dt.minute.toString().padLeft(2, '0')}';
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '$hour12$minute$ampm';
  }

  String _timeRangeLabel(CampusEventDto event) {
    final start = _parseCampusEventTime(event.startTime);
    final end = _parseCampusEventTime(event.endTime);
    if (start == null || end == null) return '';
    final startHour = start.hour % 12 == 0 ? 12 : start.hour % 12;
    final endHour = end.hour % 12 == 0 ? 12 : end.hour % 12;
    final endSuffix = end.hour >= 12 ? 'pm' : 'am';
    if (start.minute == 0 &&
        end.minute == 0 &&
        (start.hour >= 12) == (end.hour >= 12)) {
      return '$startHour-$endHour$endSuffix';
    }
    return '${_formatHourMinute(start)}-${_formatHourMinute(end)}';
  }

  double? _distanceMetersToEvent(CampusEventDto event) {
    final userLoc = _currentUserLocation;
    if (userLoc == null) return null;
    try {
      return userLoc.distanceTo(
        GeoPoint(event.latitude.toDouble(), event.longitude.toDouble(), 0),
      );
    } catch (_) {
      return null;
    }
  }

  String _walkMinutesLabel(CampusEventDto event) {
    final distanceMeters = _distanceMetersToEvent(event);
    if (distanceMeters == null) return '';
    const walkingMetersPerMinute = 84.0; // ~1.4 m/s
    final min = (distanceMeters / walkingMetersPerMinute).round().clamp(1, 999);
    return '$min min';
  }

  String _milesLabel(CampusEventDto event) {
    final distanceMeters = _distanceMetersToEvent(event);
    if (distanceMeters == null) return '';
    final miles = distanceMeters / 1609.344;
    return '${miles.toStringAsFixed(1)} mi';
  }

  CampusEventDto? _eventById(List<CampusEventDto> events, String? id) {
    if (id == null) return null;
    for (final event in events) {
      if (event.id == id) return event;
    }
    return null;
  }

  bool _showAddToGoogleCalendar(CampusEventDto event) {
    final start = _parseCampusEventTime(event.startTime);
    if (start == null) return false;
    return start.isAfter(DateTime.now().add(const Duration(hours: 1)));
  }

  String _locationLineForCalendar(CampusEventDto event) {
    final addr = event.address?.trim();
    if (addr != null && addr.isNotEmpty) {
      return '${event.locationName}, $addr';
    }
    return event.locationName;
  }

  Future<void> _openCampusEventInGoogleCalendar(CampusEventDto event) async {
    final start = _parseCampusEventTime(event.startTime);
    if (start == null) return;
    final endParsed = _parseCampusEventTime(event.endTime);
    final end = (endParsed != null && endParsed.isAfter(start))
        ? endParsed
        : start.add(const Duration(hours: 1));
    await openGoogleCalendarCreateEvent(
      title: event.title,
      location: _locationLineForCalendar(event),
      start: start,
      end: end,
      details: event.description,
      allDay: event.allDay,
    );
  }

  DateTime? _parseCampusEventTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso.toLocal();
    try {
      return HttpDate.parse(trimmed).toLocal();
    } catch (_) {
      return null;
    }
  }

  bool _matchesCampusEventFilters(CampusEventDto event) {
    final matchesLocation = widget.locations == null ||
        widget.locations!.isEmpty ||
        widget.locations!.contains(event.locationName);

    final matchesCategory = widget.categories == null ||
        widget.categories!.isEmpty ||
        event.categories.any((c) => widget.categories!.contains(c.name));

    final searchTerm = widget.searchText?.trim().toLowerCase() ?? '';
    final matchesSearch = searchTerm.isEmpty ||
        event.title.toLowerCase().contains(searchTerm) ||
        event.description.toLowerCase().contains(searchTerm) ||
        event.locationName.toLowerCase().contains(searchTerm) ||
        event.tags.any((tag) => tag.toLowerCase().contains(searchTerm));

    return matchesLocation && matchesCategory && matchesSearch;
  }

  bool _hasPhysicalLocation(CampusEventDto event) {
    final location = event.locationName.trim();
    final hasNamedLocation = location.isNotEmpty &&
        location.toLowerCase() != 'virtual' &&
        location.toLowerCase() != 'online';
    final hasCoords = event.latitude.isFinite &&
        event.longitude.isFinite &&
        !(event.latitude == 0 && event.longitude == 0);
    return hasNamedLocation && hasCoords;
  }

  List<CampusEventDto> _filteredEvents(CampusEventModel campusEventModel) {
    final events = campusEventModel.currentList?.events ??
        campusEventModel.allCachedEvents;
    final rows = <({CampusEventDto event, DateTime start, double? distance})>[];

    for (final event in events) {
      if (!_hasPhysicalLocation(event)) {
        continue;
      }
      final start = _parseCampusEventTime(event.startTime);
      final end = _parseCampusEventTime(event.endTime);
      if (start == null || end == null) {
        continue;
      }
      if (end.isBefore(DateTime.now())) {
        continue;
      }
      if (!_matchesCampusEventFilters(event)) {
        continue;
      }

      double? distanceMeters;
      final userLoc = _currentUserLocation;
      if (userLoc != null) {
        try {
          distanceMeters = userLoc.distanceTo(
            GeoPoint(event.latitude.toDouble(), event.longitude.toDouble(), 0),
          );
        } catch (_) {
          distanceMeters = null;
        }
      }
      rows.add((event: event, start: start, distance: distanceMeters));
    }

    rows.sort((a, b) {
      final aIsTbd = a.event.locationName.trim().toUpperCase() == 'TBD';
      final bIsTbd = b.event.locationName.trim().toUpperCase() == 'TBD';
      if (aIsTbd != bIsTbd) {
        return aIsTbd ? 1 : -1;
      }

      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      if (a.distance == null && b.distance == null) return 0;
      if (a.distance == null) return 1;
      if (b.distance == null) return -1;
      return a.distance!.compareTo(b.distance!);
    });

    return rows.map((r) => r.event).toList();
  }

  Future<void> _collapseToPeek() async {
    if (!_sheetController.isAttached) return;
    await _sheetController.animateTo(
      0.26,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inRouteMode = widget.routedEventId != null;
    // Post-GO: cap height so the sheet never expands to the full page.
    const routeMax = 0.52;
    const routeSnap = <double>[0.32, 0.42, routeMax];
    return Positioned.fill(
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: 0.26,
        minChildSize: 0.26,
        maxChildSize: inRouteMode ? routeMax : 1.0,
        snap: true,
        snapSizes: inRouteMode ? routeSnap : const [0.58, 1.0],
        builder: (context, scrollController) {
          return AnimatedBuilder(
            animation: _sheetController,
            builder: (context, _) {
              final extent =
                  _sheetController.isAttached ? _sheetController.size : 0.26;
              final showExpandedChrome = extent > 0.88;

              return Consumer<CampusEventModel>(
                builder: (
                  context,
                  campusEventModel,
                  _,
                ) {
                  final allEvents = campusEventModel.currentList?.events ??
                      campusEventModel.allCachedEvents;
                  final events = _filteredEvents(campusEventModel);
                  final count = events.length;
                  final selectedEvent = _eventById(
                    allEvents,
                    widget.selectedEventId,
                  );
                  final routedEvent = _eventById(
                    allEvents,
                    widget.routedEventId,
                  );
                  final focusedEvent = routedEvent ?? selectedEvent;
                  final isRoutedView = focusedEvent != null &&
                      routedEvent?.id == focusedEvent.id;

                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 4),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.dragHandle,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          if (showExpandedChrome && focusedEvent == null)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                right: 8,
                                top: 4,
                                bottom: 4,
                              ),
                              child: Row(
                                children: [
                                  TextButton(
                                    onPressed: _collapseToPeek,
                                    child: Text(
                                      '< Exit',
                                      style: TextStyle(
                                        color: AppColors.grayText,
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'Events',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 64),
                                ],
                              ),
                            ),
                          if (focusedEvent == null) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                              child: Text(
                                '$count Events Happening Soon',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: AppColors.darkText,
                                ),
                              ),
                            ),
                            if (events.isEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  24,
                                ),
                                child: Text(
                                  'No events match your filters.',
                                  style: TextStyle(
                                    color: AppColors.grayText,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              )
                            else
                              ...events.map((event) {
                                final host = _hostLabel(event);
                                final perk = _perkLine(event);
                                final timeStr = _timeLabel(event);

                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    12,
                                  ),
                                  child: _EventCard(
                                    onGo: () => widget.onGoToEvent?.call(event),
                                    eventName: event.title,
                                    hostName: host,
                                    perkLine: perk,
                                    timeLabel: timeStr,
                                  ),
                                );
                              }),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                              child: _FocusedEventCard(
                                event: focusedEvent,
                                isRoutedView: isRoutedView,
                                walkLabel: _walkMinutesLabel(focusedEvent),
                                milesLabel: _milesLabel(focusedEvent),
                                timeRangeLabel: _timeRangeLabel(focusedEvent),
                                hostLabel: _hostLabel(focusedEvent),
                                showAddToGoogleCalendar:
                                    _showAddToGoogleCalendar(focusedEvent),
                                onAddToGoogleCalendar: () =>
                                    _openCampusEventInGoogleCalendar(
                                  focusedEvent,
                                ),
                                onGo: isRoutedView
                                    ? null
                                    : () => widget.onGoToEvent?.call(
                                          focusedEvent,
                                        ),
                                onClose: widget.onClearSelection,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final VoidCallback onGo;
  final String eventName;
  final String hostName;
  final String perkLine;
  final String timeLabel;

  const _EventCard({
    required this.onGo,
    required this.eventName,
    required this.hostName,
    required this.perkLine,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.restaurant_rounded,
                  size: 20,
                  color: AppColors.purple,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    perkLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.purple,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (timeLabel.isNotEmpty)
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryRed,
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              eventName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Hosted by',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grayText,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.darkText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          hostName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onGo,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Text(
                        'GO!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusedEventCard extends StatelessWidget {
  final CampusEventDto event;
  final bool isRoutedView;
  final String walkLabel;
  final String milesLabel;
  final String timeRangeLabel;
  final String hostLabel;
  final bool showAddToGoogleCalendar;
  final Future<void> Function() onAddToGoogleCalendar;
  final VoidCallback? onGo;
  final VoidCallback? onClose;

  _FocusedEventCard({
    required this.event,
    required this.isRoutedView,
    required this.walkLabel,
    required this.milesLabel,
    required this.timeRangeLabel,
    required this.hostLabel,
    required this.showAddToGoogleCalendar,
    required this.onAddToGoogleCalendar,
    this.onGo,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: isRoutedView
                      ? Row(
                          children: [
                            const Icon(Icons.directions_walk, size: 21),
                            const SizedBox(width: 8),
                            Text(
                              [walkLabel, milesLabel]
                                  .where((s) => s.isNotEmpty)
                                  .join(' \u2022 '),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                                color: AppColors.darkText,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: AppColors.darkText,
                          ),
                        ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.cancel,
                    size: 36,
                    color: AppColors.black30,
                  ),
                ),
              ],
            ),
            if (!isRoutedView) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.directions_walk, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    walkLabel,
                    style: const TextStyle(fontSize: 17, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(width: 20),
                  const Icon(Icons.location_on_outlined, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    timeRangeLabel,
                    style: const TextStyle(fontSize: 17, fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              event.description,
              maxLines: isRoutedView ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                fontFamily: 'Poppins',
                color: AppColors.darkText,
              ),
            ),
            if (isRoutedView) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Hosted by',
                    style: TextStyle(
                      fontSize: 19,
                      color: AppColors.grayText,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.black30,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      hostLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontFamily: 'Poppins',
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              if (showAddToGoogleCalendar)
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () {
                        onAddToGoogleCalendar();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Center(
                          child: Text(
                            'Add to GCal',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 42 / 2,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: onGo,
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Center(
                          child: Text(
                            'GO!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 42 / 2,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
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
