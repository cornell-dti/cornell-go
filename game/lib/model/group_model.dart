import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

/// GroupModel represents the model for groups. Whenever a group is updated, added, or deleted, the model
/// notifies the Consumer so the front end can be modified.
///
/// GroupModel extends [ChangeNotifier], and at the root of the application [ChangeNotifierProvider] creates a [GroupModel].
///
/// Overview of Group:
/// A group represents a group of users playing together on a specific challenge/journey. The group model
/// holds the group id, a join code (friendlyId), a current event id, a member list, and an optional host user.
/// When a user is created, a new group is made for that user, with the current event id being a default
/// event the user is assigned.
///
/// Parameters:
/// [curEventId] is the id of the event the group is currently playing.
/// [members] is the list of group members, containing each member's id, name, and number of points .
/// [group] is the [GroupDto] and contains the details of the group (id, friendlyId, members, curEventId, etc.)
///
/// Expected behavior:
/// The constructor takes in an [ApiClient client] to subscribe to two streams, never unsubscribing (the model is active for the app's whole duration).
///
/// 1. [updateGroupDataStream] The client listens to when the server sends group updates using this stream. The update is placed into [event].
/// First, we check if [event.group] is a [String]; if it is, then we ignore this update, since it is not
/// relevant to our group. If [event.group] is not a [String], we update [group] to match the new one given.Then, we run 
/// removeWhere, clear, and sort on [members] before calling [notifyListeners()].
///
/// 2. [connectedStream] If the user reconnects, we clear the [members], the member list of the group,
/// and set [curEventId] to null. Then, we call [requestGroupData] to get the most up-to-date group state.
///
/// Edge Cases:
/// - When [curEventId] is null: this is possible when the user has not yet reconnected. [groupModel.curEventId] should be null-checked when called.
/// - When [group] is null or [members] is empty: this is possible when [updateGroupDataStream] has just started and not yet sent any updates. To access
/// the member list, use [group?.members]. 
///
///
/// Runtime:
/// Accessing fields from [groupModel] like [curEventId], [members], or [group] is O(1).
/// [notifyListeners()] is O(n), where n is the number of listeners.
///

class GroupModel extends ChangeNotifier {
  String? curEventId;
  List<GroupMemberDto> members = [];

  GroupDto? group = null;

  GroupModel(ApiClient client) {
    client.clientApi.updateGroupDataStream.listen((event) {
      if (!(event.group is String)) {
        group = event.group;
        curEventId = event.group.curEventId;
        members.removeWhere(
          (element) =>
              event.group.members?.any((mem) => mem.id == element.id) ?? false,
        );
        members.clear();
        members.sort((mem1, mem2) => mem1.points - mem2.points);
        notifyListeners();
      }
    });

    client.clientApi.connectedStream.listen((event) {
      members.clear();
      curEventId = null;
      client.serverApi?.requestGroupData(RequestGroupDataDto());
    });
  }
}
