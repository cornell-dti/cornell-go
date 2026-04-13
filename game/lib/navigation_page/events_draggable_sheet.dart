import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/constants/constants.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/utils/utility_functions.dart';
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

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  String _hostLabel(EventDto event, UserModel userModel) {
    final oid = event.initialOrganizationId;
    if (oid != null && userModel.orgData.containsKey(oid)) {
      return userModel.orgData[oid]?.name ?? 'Host';
    }
    for (final org in userModel.orgData.values) {
      if (org.events?.contains(event.id) ?? false) {
        return org.name ?? 'Host';
      }
    }
    return 'Host';
  }

  String _perkLine(EventDto event) {
    final d = event.description?.trim();
    if (d != null && d.isNotEmpty) {
      final first = d.split(RegExp(r'\n')).first.trim();
      if (first.length <= 48) return first;
    }
    if (event.category != null) {
      return friendlyCategory[event.category!] ?? 'Event';
    }
    return 'Event';
  }

  String _timeLabel(EventDto event) {
    try {
      final end = HttpDate.parse(event.endTime ?? '');
      final diff = end.difference(DateTime.now());
      if (diff.isNegative) return 'ended';
      if (diff.inDays > 0) return 'in ${diff.inDays}d';
      if (diff.inHours > 0) return 'in ${diff.inHours} hours';
      if (diff.inMinutes > 0) return 'in ${diff.inMinutes} min';
      return 'soon';
    } catch (_) {
      return '';
    }
  }

  List<EventDto> _filteredEvents(
    UserModel userModel,
    EventModel eventModel,
    TrackerModel trackerModel,
    ChallengeModel challengeModel,
    GroupModel groupModel,
    ApiClient apiClient,
  ) {
    final allowedEventIds = userModel.getAvailableEventIds();
    final events = allowedEventIds
        .map((id) => eventModel.getEventById(id))
        .filter((e) => e != null)
        .map((e) => e!)
        .toList();

    final List<EventDto> out = [];

    for (final event in events) {
      final tracker = trackerModel.trackerByEventId(event.id);
      final numberCompleted = tracker?.prevChallenges.length ?? 0;
      final complete = numberCompleted == (event.challenges?.length ?? 0);
      DateTime endtime;
      try {
        endtime = HttpDate.parse(event.endTime ?? '');
      } catch (_) {
        continue;
      }
      final timeTillExpire = endtime.difference(DateTime.now());
      if (event.isJourney == true) continue;
      if (event.indexable == false) continue;
      if (event.challenges == null || event.challenges!.isEmpty) continue;
      final challenge = challengeModel.getChallengeById(event.challenges![0]);
      if (challenge == null) continue;

      final challengeLocation = challenge.location?.name ?? '';
      final matches = eventMatchesFilters(
        event: event,
        difficulty: widget.difficulty,
        locations: widget.locations,
        categories: widget.categories,
        searchText: widget.searchText,
        challengeLocation: challengeLocation,
        challengeName: challenge.name,
      );

      if (!complete && !timeTillExpire.isNegative && matches) {
        out.add(event);
      } else if (event.id == groupModel.curEventId) {
        apiClient.serverApi?.setCurrentEvent(SetCurrentEventDto(eventId: ""));
      }
    }

    out.sort((a, b) {
      try {
        return HttpDate.parse(a.endTime ?? '')
            .compareTo(HttpDate.parse(b.endTime ?? ''));
      } catch (_) {
        return 0;
      }
    });

    return out;
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

              return Consumer6<UserModel, EventModel, GroupModel,
                  TrackerModel, ChallengeModel, ApiClient>(
                builder: (
                  context,
                  userModel,
                  eventModel,
                  groupModel,
                  trackerModel,
                  challengeModel,
                  apiClient,
                  _,
                ) {
                  final events = _filteredEvents(
                    userModel,
                    eventModel,
                    trackerModel,
                    challengeModel,
                    groupModel,
                    apiClient,
                  );
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              padding: EdgeInsets.only(
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
                          Expanded(
                            child: events.isEmpty
                                ? Center(
                                    child: Text(
                                      'No events match your filters.',
                                      style: TextStyle(
                                        color: AppColors.grayText,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      24,
                                    ),
                                    itemCount: events.length,
                                    itemBuilder: (context, index) {
                                      final event = events[index];
                                      final host = _hostLabel(
                                        event,
                                        userModel,
                                      );
                                      final perk = _perkLine(event);
                                      final timeStr = _timeLabel(event);

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _EventCard(
                                          eventName: event.name ?? 'Event',
                                          hostName: host,
                                          perkLine: perk,
                                          timeLabel: timeStr,
                                        ),
                                      );
                                    },
                                  ),
                          ),
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
