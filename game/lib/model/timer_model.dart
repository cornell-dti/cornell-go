import 'dart:async';
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
  int _extensionsUsed = 0; // Track extensions used for current challenge

  //getter functions
  String? get currentTimerId => _currentTimerId;
  String? get currentChallengeId => _currentChallengeId;
  DateTime? get endTime => _endTime;
  bool get isActive => _isActive;
  int get extensionsUsed => _extensionsUsed;

  TimerModel(ApiClient client) : _client = client {
    //listen for TimerStartedDto from backend
    client.clientApi.timerStartedStream.listen((event) {
      // print(
      //     "TimerModel: Received TimerStartedDto - timerId=${event.timerId}, challengeId=${event.challengeId}, endTime=${event.endTime}");
      _currentTimerId = event.timerId;
      _currentChallengeId = event.challengeId;
      _endTime = DateTime.parse(event.endTime);
      _isActive = true;
      _extensionsUsed =
          event.extensionsUsed; // Preserve extensions from backend
      notifyListeners();
    });

    //listen for TimerExtendedDto from backend
    client.clientApi.timerExtendedStream.listen((event) {
      if (event.challengeId == _currentChallengeId) {
        _endTime = DateTime.parse(event.newEndTime);
        _isActive = true; // Reactivate timer when extended
        _extensionsUsed = event.extensionsUsed; // Update extensions count
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
      _extensionsUsed = 0; // Reset extensions when disconnected
      notifyListeners();
    });
  }

  //send StartChallengeTimerDto to backend to start timer
  void startTimer(String challengeId) {
    // print(
    //     "TimerModel: Sending startTimer request for challengeId=$challengeId");
    _client.serverApi
        ?.startChallengeTimer(StartChallengeTimerDto(challengeId: challengeId));
  }

  // tries to extend timer: returns null if success, error message if fail (frontend displays error message)
  Future<String?> extendTimer(
      String challengeId, DateTime currentEndTime) async {
    final completer = Completer<String?>();
    late Timer timeoutTimer;
    late StreamSubscription extendedSubscription;
    late StreamSubscription errorSubscription;

    // timeout for if backend doesn't respond within 5 seconds
    timeoutTimer = Timer(Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        completer.complete('Request timeout');
      }
    });

    // listen for TimerExtendedDto from backend - completes with null if success
    extendedSubscription =
        _client.clientApi.timerExtendedStream.listen((event) {
      if (event.challengeId == challengeId && !completer.isCompleted) {
        completer.complete(null);
      }
    });

    // listen for errors from backend, and complete with error message if error is related to timer extension
    errorSubscription = _client.clientApi.updateErrorDataStream.listen((error) {
      final errorMessage = error.message.toLowerCase();
      if (errorMessage.contains('timer') ||
          errorMessage.contains('challenge') ||
          errorMessage.contains('extend') ||
          errorMessage.contains('coin')) {
        if (!completer.isCompleted) {
          completer.complete(error.message);
        }
      }
    });

    try {
      // send ExtendTimerDto to backend to extend timer
      final result = await _client.serverApi?.extendTimer(ExtendTimerDto(
          challengeId: challengeId, endTime: currentEndTime.toIso8601String()));

      if (result == null && !completer.isCompleted) {
        completer.complete('Failed to extend timer');
      }

      final errorMessage = await completer.future;
      return errorMessage;
    } finally {
      // clean up
      timeoutTimer.cancel();
      await extendedSubscription.cancel();
      await errorSubscription.cancel();
    }
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
