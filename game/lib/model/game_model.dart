class GameModel {
  // How close (0 to 1) to the "close" mark if close < distance < infinity
  double completionProgress = 0;
  // How close (0 to 1) to the "completion" mark if completion < distance < close
  double closeProgress = 0;
  // How far (-1 to 1) off is the person from walking in the right direction
  double directionDistance = 0;

  String challengeId = "";
  String imageUrl = "";
  String name = "";
  String description = "";
  String walkingTime = "";

  bool hasConnection = false;
  bool withinCloseRadius = false; // completion < distance < close
  bool withinCompletionRadius = false; // 0 < distance < completion
}
