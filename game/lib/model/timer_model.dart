import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

/**
 * TimerModel - Manages timer state and syncs with backend using ChangeNotifier
 */
class TimerModel extends ChangeNotifier {
  final ApiClient _client;

  // Timer state (nullable since timer may not be active)
  String? _currentTimerId;
  String? _currentChallengeId;
  DateTime? _endTime;
  bool _isActive = false;

  //getter functions
  String? get currentTimerId => _currentTimerId;
  String? get currentChallengeId => _currentChallengeId;
  DateTime? get endTime => _endTime;
  bool get isActive => _isActive;

  TimerModel(ApiClient client) : _client = client {
    //listen for TimerStartedDto from backend
    client.clientApi.timerStartedStream.listen((event) {
      _currentTimerId = event.timerId;
      _currentChallengeId = event.challengeId;
      _endTime = DateTime.parse(event.endTime);
      _isActive = true;
      notifyListeners();
    });

    //listen for TimerExtendedDto from backend
    client.clientApi.timerExtendedStream.listen((event) {
      if (event.challengeId == _currentChallengeId) {
        _endTime = DateTime.parse(event.newEndTime);
        notifyListeners();
      }
    });

    //listen for TimerCompletedDto from backend
    client.clientApi.timerCompletedStream.listen((event) {
      if (event.challengeId == _currentChallengeId) {
        _isActive = false;
        notifyListeners();
      }
    });

    //listen for TimerWarningDto from backend
    client.clientApi.timerWarningStream.listen((event) {
      print(
          "Timer warning: ${event.timeRemaining} seconds remaining (milestone: ${event.milestone})");
      notifyListeners(); // TODO: this notifies UI to show warning; show warning in UI
    });

    //reset timer state when connected
    client.clientApi.connectedStream.listen((event) {
      _currentTimerId = null;
      _currentChallengeId = null;
      _endTime = null;
      _isActive = false;
      notifyListeners();
    });
  }

  //send StartChallengeTimerDto to backend to start timer
  void startTimer(String challengeId) {
    _client.serverApi
        ?.startChallengeTimer(StartChallengeTimerDto(challengeId: challengeId));
  }

  //send ExtendTimerDto to backend to extend timer
  void extendTimer(String challengeId, DateTime currentEndTime) {
    _client.serverApi?.extendTimer(ExtendTimerDto(
        challengeId: challengeId, endTime: currentEndTime.toIso8601String()));
  }

  //send TimerCompletedDto to backend to complete timer
  void completeTimer(String challengeId) {
    if (_currentTimerId != null) {
      _client.serverApi?.completeTimer(TimerCompletedDto(
          timerId: _currentTimerId!,
          challengeId: challengeId,
          challengeCompleted: false // false = timer expired, not completed
          ));
    }
  }

  //calculate remaining time in seconds
  int? getTimeRemaining() {
    if (_endTime == null || !_isActive) return null;
    final remaining = _endTime!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  //check if timer is for a specific challenge
  bool isTimerForChallenge(String challengeId) {
    return _isActive && _currentChallengeId == challengeId;
  }
}
