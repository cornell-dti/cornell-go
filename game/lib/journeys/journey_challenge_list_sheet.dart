import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/api/geopoint.dart';
import 'package:game/constants/constants.dart';
import 'package:game/gameplay/gameplay_page.dart';
import 'package:game/journeys/journey_flow_result.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:game/widget/cached_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class JourneyChallengeListSheet extends StatefulWidget {
  final String eventId;

  const JourneyChallengeListSheet({Key? key, required this.eventId})
      : super(key: key);

  static Future<dynamic> show(BuildContext context, String eventId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => JourneyChallengeListSheet(eventId: eventId),
    );
  }

  @override
  State<JourneyChallengeListSheet> createState() =>
      _JourneyChallengeListSheetState();
}

class _JourneyChallengeListSheetState extends State<JourneyChallengeListSheet> {
  List<ChallengeDto> availableChallenges = [];
  GeoPoint? currentLocation;
  bool isLoading = true;
  bool isSelectingChallenge = false;

  late StreamSubscription<Position> positionStream;

  @override
  void initState() {
    super.initState();
    _startPositionStream();
    _loadAvailableChallenges();
  }

  @override
  void dispose() {
    positionStream.cancel();
    super.dispose();
  }

  void _startPositionStream() async {
    GeoPoint.current().then((location) {
      if (mounted) {
        setState(() {
          currentLocation = location;
        });
      }
    });

    positionStream = Geolocator.getPositionStream(
      locationSettings: GeoPoint.getLocationSettings(),
    ).listen((Position? newPos) {
      if (newPos != null && mounted) {
        currentLocation = GeoPoint(
          newPos.latitude,
          newPos.longitude,
          newPos.heading,
        );
        setState(() {});
      }
    });
  }

  Future<void> _loadAvailableChallenges() async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final response = await apiClient.serverApi?.requestAvailableChallenges(
      RequestAvailableChallengesDto(),
    );

    if (mounted && response != null) {
      Map<String, dynamic>? parsed;
      if (response is Map<String, dynamic>) {
        parsed = response;
      } else if (response is String) {
        parsed = jsonDecode(response) as Map<String, dynamic>?;
      } else if (response is Map) {
        parsed = Map<String, dynamic>.from(response);
      }

      if (parsed != null) {
        final dto = AvailableChallengesResponseDto.fromJson(parsed);
        setState(() {
          availableChallenges = dto.challenges;
          isLoading = false;
        });
      } else {
        print(
            'requestAvailableChallenges: unexpected type ${response.runtimeType}');
        setState(() => isLoading = false);
      }
    } else if (mounted) {
      print('requestAvailableChallenges: null response (5s timeout?)');
      setState(() => isLoading = false);
    }
  }

  double? _distanceTo(ChallengeDto challenge) {
    if (currentLocation == null ||
        challenge.latF == null ||
        challenge.longF == null) {
      return null;
    }
    return currentLocation!.distanceTo(
      GeoPoint(challenge.latF!, challenge.longF!, 0),
    );
  }

  String _walkingTime(double? distanceMeters) {
    if (distanceMeters == null) return '? min';
    int minutes = ((distanceMeters / 1609.34) * 20).round();
    if (minutes < 1) minutes = 1;
    return '$minutes min';
  }

  Future<void> _selectChallenge(String challengeId) async {
    if (isSelectingChallenge) return;
    setState(() => isSelectingChallenge = true);

    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final response = await apiClient.serverApi?.setCurrentChallenge(
      SetCurrentChallengeDto(challengeId: challengeId),
    );

    if (!mounted) return;

    bool success = false;
    dynamic parsed = response;
    if (parsed is String) {
      try {
        parsed = jsonDecode(parsed);
      } catch (_) {}
    }
    if (parsed is Map) {
      success = parsed['success'] == true;
    } else if (parsed is bool) {
      success = parsed;
    }

    if (success) {
      Navigator.pop(context, challengeSelectedResult);
    } else {
      print(
          'setCurrentChallenge failed - response: $response (${response.runtimeType})');
      displayToast('Could not select challenge', Status.error);
      setState(() => isSelectingChallenge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeModel = Provider.of<ChallengeModel>(context);
    final eventModel = Provider.of<EventModel>(context);
    final trackerModel = Provider.of<TrackerModel>(context);
    final eventId = widget.eventId;
    final event = eventModel.getEventById(eventId);
    final tracker = trackerModel.trackerByEventId(eventId);

    final completedChallengeIds =
        tracker?.prevChallenges.map((p) => p.challengeId).toSet() ?? {};
    final totalChallenges = event?.challenges?.length ?? 0;
    final remaining = availableChallenges.length;

    // Sort available challenges by distance
    final sortedAvailable = List<ChallengeDto>.from(availableChallenges);
    sortedAvailable.sort((a, b) {
      final distA = _distanceTo(a);
      final distB = _distanceTo(b);
      if (distA == null && distB == null) return 0;
      if (distA == null) return 1;
      if (distB == null) return -1;
      return distA.compareTo(distB);
    });

    // Build completed challenges list with prev challenge data
    final prevChallengeMap = <String, PrevChallengeDto>{};
    List<ChallengeDto> completedChallenges = [];
    for (var prevChallenge in (tracker?.prevChallenges ?? [])) {
      prevChallengeMap[prevChallenge.challengeId] = prevChallenge;
      final chal = challengeModel.getChallengeById(prevChallenge.challengeId);
      if (chal != null) {
        completedChallenges.add(chal);
      }
    }

    final bool journeyComplete =
        completedChallengeIds.length == totalChallenges && totalChallenges > 0;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 10),
                  child: Container(
                    width: 88,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.dragHandle,
                      borderRadius: BorderRadius.circular(19),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/flag.svg',
                        width: 18,
                        height: 23,
                        colorFilter: ColorFilter.mode(
                          AppColors.darkGrayText,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Challenges',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrayText,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.darkGrayText,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Text(
                        journeyComplete ? 'Complete!' : '$remaining Remaining',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrayText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Challenge list
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryRed,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          children: [
                            // Journey Complete banner
                            if (journeyComplete)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 16),
                                child: Column(
                                  children: [
                                    Text(
                                      'Journey Complete!',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.green,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: AppColors.primaryRed,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BottomNavBar(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Return Home',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Nearest to you section
                            if (sortedAvailable.isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 4, bottom: 4),
                                child: Text(
                                  'Nearest to you',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.grayText,
                                  ),
                                ),
                              ),
                              ...sortedAvailable.map(
                                (challenge) => _JourneyChallengeCard(
                                  challenge: challenge,
                                  isCompleted: false,
                                  walkingTime:
                                      _walkingTime(_distanceTo(challenge)),
                                  onTap: () => _selectChallenge(challenge.id),
                                ),
                              ),
                            ],
                            // Completed section
                            if (completedChallenges.isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 12, bottom: 4),
                                child: Text(
                                  'Completed',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.grayText,
                                  ),
                                ),
                              ),
                              ...completedChallenges.map(
                                (challenge) {
                                  final prev = prevChallengeMap[challenge.id];
                                  final totalPts = challenge.points ?? 0;
                                  int earned;
                                  if (prev?.failed == true) {
                                    earned = 0;
                                  } else if (prev != null) {
                                    final extAdj =
                                        calculateExtensionAdjustedPoints(
                                      totalPts,
                                      prev.extensionsUsed ?? 0,
                                    );
                                    earned = calculateHintAdjustedPoints(
                                      extAdj,
                                      prev.hintsUsed,
                                    );
                                  } else {
                                    earned = totalPts;
                                  }
                                  return _JourneyChallengeCard(
                                    challenge: challenge,
                                    isCompleted: true,
                                    walkingTime:
                                        _walkingTime(_distanceTo(challenge)),
                                    earnedPoints: earned,
                                    onTap: null,
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyChallengeCard extends StatelessWidget {
  final ChallengeDto challenge;
  final bool isCompleted;
  final String walkingTime;
  final int? earnedPoints;
  final VoidCallback? onTap;

  const _JourneyChallengeCard({
    required this.challenge,
    required this.isCompleted,
    required this.walkingTime,
    this.earnedPoints,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.black10,
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            // Left content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + walking time row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          challenge.name ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGrayText,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.darkGrayText,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.directions_walk,
                        size: 18,
                        color: AppColors.darkGrayText,
                      ),
                      SizedBox(width: 2),
                      Text(
                        walkingTime,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrayText,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Description
                  Text(
                    challenge.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight:
                          isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: AppColors.grayText,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Points
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/bearcoins.svg',
                        width: 20,
                        height: 20,
                      ),
                      SizedBox(width: 5),
                      Text(
                        isCompleted
                            ? '${earnedPoints ?? challenge.points ?? 0} PTS / ${challenge.points ?? 0} PTS'
                            : '${challenge.points ?? 0} PTS',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AppCachedImage(
                imageUrl: challenge.imageUrl ?? '',
                width: 82,
                height: 81,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Launcher scaffold that immediately shows the challenge list bottom sheet.
/// Used from ChallengeCompletedPage where we can't show a bottom sheet directly.
class ChallengeListLauncher extends StatefulWidget {
  final String eventId;

  const ChallengeListLauncher({Key? key, required this.eventId})
      : super(key: key);

  @override
  State<ChallengeListLauncher> createState() => _ChallengeListLauncherState();
}

class _ChallengeListLauncherState extends State<ChallengeListLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      JourneyChallengeListSheet.show(context, widget.eventId).then((result) {
        if (!mounted) return;
        if (result == challengeSelectedResult) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => GameplayPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BottomNavBar()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
    );
  }
}
