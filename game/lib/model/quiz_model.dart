import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

/**
 * QuizModel - Manages quiz state and syncs with backend using ChangeNotifier
 */
class QuizModel extends ChangeNotifier {
  final ApiClient _client;

  // Quiz state
  String? _currentChallengeId;
  QuizQuestionDto? _currentQuestion;
  int _shufflesRemaining = 3;
  int? _selectedAnswerIndex;
  bool _isLoading = false;
  bool _isSubmitted = false;
  QuizResultDto? _lastResult;
  String? _errorMessage;

  // Track quiz points per challenge (challengeId -> points earned)
  Map<String, int> _pointsByChallenge = {};
  int _totalPointsEarned = 0; // Total across all challenges

  // Getter functions
  String? get currentChallengeId => _currentChallengeId;
  QuizQuestionDto? get currentQuestion => _currentQuestion;
  int get shufflesRemaining => _shufflesRemaining;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get isLoading => _isLoading;
  bool get isSubmitted => _isSubmitted;
  QuizResultDto? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;
  int get totalPointsEarned => _totalPointsEarned;

  // Get quiz points for a specific challenge
  int getPointsForChallenge(String challengeId) {
    return _pointsByChallenge[challengeId] ?? 0;
  }

  QuizModel(ApiClient client) : _client = client {
    // Listen for QuizQuestionDto from backend
    _client.clientApi.quizQuestionStream.listen((question) {
      _currentQuestion = question;
      _isLoading = false;
      _selectedAnswerIndex = null;
      _isSubmitted = false;
      _lastResult = null;
      _errorMessage = null;
      notifyListeners();
    });

    // Listen for QuizResultDto from backend
    _client.clientApi.quizResultStream.listen((result) {
      _lastResult = result;
      _isSubmitted = true;
      _isLoading = false;
      if (result.isCorrect && _currentChallengeId != null) {
        // Update points for this specific challenge
        _pointsByChallenge[_currentChallengeId!] =
            (_pointsByChallenge[_currentChallengeId!] ?? 0) +
                result.pointsEarned;
        // Update total points across all challenges
        _totalPointsEarned += result.pointsEarned;
      }
      notifyListeners();
    });

    // Listen for QuizErrorDto from backend
    _client.clientApi.quizErrorStream.listen((error) {
      _errorMessage = error.message;
      _isLoading = false;
      notifyListeners();
    });

    // Reset quiz state when connected
    _client.clientApi.connectedStream.listen((event) {
      _currentChallengeId = null;
      _currentQuestion = null;
      _shufflesRemaining = 3;
      _selectedAnswerIndex = null;
      _isLoading = false;
      _isSubmitted = false;
      _lastResult = null;
      _errorMessage = null;
      _totalPointsEarned = 0;
      notifyListeners();
    });
  }

  // Request a quiz question for a challenge
  void requestQuestion(String challengeId) {
    _currentChallengeId = challengeId;
    _isLoading = true;
    _errorMessage = null;
    _shufflesRemaining = 3; // Reset shuffles for new question
    _isSubmitted = false; // Reset submission state
    _lastResult = null; // Clear previous result
    _selectedAnswerIndex = null; // Clear previous selection
    notifyListeners();

    _client.serverApi?.requestQuizQuestion(
      RequestQuizQuestionDto(challengeId: challengeId),
    );
  }

  // Shuffle to get a different question
  void shuffleQuestion() {
    if (_shufflesRemaining <= 0 ||
        _isSubmitted ||
        _currentChallengeId == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _shufflesRemaining--;
    notifyListeners();

    _client.serverApi?.shuffleQuizQuestion(
      ShuffleQuizQuestionDto(
        challengeId: _currentChallengeId!,
        currentQuestionId: _currentQuestion?.id,
      ),
    );
  }

  // Select an answer
  void selectAnswer(int index) {
    if (!_isSubmitted && _currentQuestion != null) {
      _selectedAnswerIndex = index;
      notifyListeners();
    }
  }

  // Submit the selected answer
  void submitAnswer() {
    if (_selectedAnswerIndex == null ||
        _currentQuestion == null ||
        _isSubmitted ||
        _isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final selectedAnswerId =
        _currentQuestion!.answers[_selectedAnswerIndex!].id;

    _client.serverApi?.submitQuizAnswer(
      SubmitQuizAnswerDto(
        questionId: _currentQuestion!.id,
        selectedAnswerId: selectedAnswerId,
      ),
    );
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset quiz state (for new quiz session)
  void reset() {
    _currentChallengeId = null;
    _currentQuestion = null;
    _shufflesRemaining = 3;
    _selectedAnswerIndex = null;
    _isLoading = false;
    _isSubmitted = false;
    _lastResult = null;
    _errorMessage = null;
    _pointsByChallenge.clear();
    _totalPointsEarned = 0;
    notifyListeners();
  }
}
