import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/api/geopoint.dart';
import 'package:game/constants/constants.dart';
import 'package:game/model/campus_event_model.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';

/// Draggable bottom sheet listing upcoming challenge events (same pool and
/// filters as [ChallengesPage]), with name, host, and a placeholder GO button.
class EventsDraggableSheet extends StatefulWidget {
  final String? difficulty;
  final List<String>? locations;
  final List<String>? categories;
  final String? searchText;

  const EventsDraggableSheet({
    super.key,
    this.difficulty,
    this.locations,
    this.categories,
    this.searchText,
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

  List<CampusEventDto> _filteredEvents(CampusEventModel campusEventModel) {
    final events = campusEventModel.currentList?.events ??
        campusEventModel.allCachedEvents;
    final rows = <({CampusEventDto event, DateTime start, double? distance})>[];

    for (final event in events) {
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
    return Positioned.fill(
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: 0.26,
        minChildSize: 0.26,
        maxChildSize: 1.0,
        snap: true,
        snapSizes: const [0.58, 1.0],
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
                  final events = _filteredEvents(campusEventModel);
                  final count = events.length;

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
                          if (showExpandedChrome)
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
                                  eventName: event.title,
                                  hostName: host,
                                  perkLine: perk,
                                  timeLabel: timeStr,
                                ),
                              );
                            }),
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
  final String eventName;
  final String hostName;
  final String perkLine;
  final String timeLabel;

  const _EventCard({
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
                    onTap: () {},
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
