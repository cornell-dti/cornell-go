// CODE AUTOGENERATED BY npm run updateapi
// IF YOU MODIFY THIS FILE, MAKE SURE TO ALSO MODIFY THE updateapi SCRIPT!
// OTHERWISE YOUR CHANGES MAY BE OVERWRITTEN!

import { Socket } from "socket.io-client";
import * as dto from "../all.dto";

export class ServerApi {
  constructor(private socket: Socket) {}

  send(ev: string, data: {}) {
    console.log(`Sending ${ev} with ${JSON.stringify(data)}`);
    this.socket.emit(ev, data);
  }

  requestChallengeData(data: dto.RequestChallengeDataDto) {
    this.send("requestChallengeData", data);
  }

  setCurrentChallenge(data: dto.SetCurrentChallengeDto) {
    this.send("setCurrentChallenge", data);
  }

  completedChallenge(data: dto.CompletedChallengeDto) {
    this.send("completedChallenge", data);
  }

  requestGlobalLeaderData(data: dto.RequestGlobalLeaderDataDto) {
    this.send("requestGlobalLeaderData", data);
  }

  updateChallengeData(data: dto.UpdateChallengeDataDto) {
    this.send("updateChallengeData", data);
  }

  requestEventData(data: dto.RequestEventDataDto) {
    this.send("requestEventData", data);
  }

  requestFilteredEventIds(data: dto.RequestFilteredEventsDto) {
    this.send("requestFilteredEventIds", data);
  }

  requestRecommendedEvents(data: dto.RequestRecommendedEventsDto) {
    this.send("requestRecommendedEvents", data);
  }

  requestEventLeaderData(data: dto.RequestEventLeaderDataDto) {
    this.send("requestEventLeaderData", data);
  }

  requestEventTrackerData(data: dto.RequestEventTrackerDataDto) {
    this.send("requestEventTrackerData", data);
  }

  updateEventData(data: dto.UpdateEventDataDto) {
    this.send("updateEventData", data);
  }

  requestGroupData(data: dto.RequestGroupDataDto) {
    this.send("requestGroupData", data);
  }

  joinGroup(data: dto.JoinGroupDto) {
    this.send("joinGroup", data);
  }

  leaveGroup(data: dto.LeaveGroupDto) {
    this.send("leaveGroup", data);
  }

  setCurrentEvent(data: dto.SetCurrentEventDto) {
    this.send("setCurrentEvent", data);
  }

  updateGroupData(data: dto.UpdateGroupDataDto) {
    this.send("updateGroupData", data);
  }

  sendGroupInvite(data: dto.SendGroupInviteDto) {
    this.send("sendGroupInvite", data);
  }

  requestOrganizationData(data: dto.RequestOrganizationDataDto) {
    this.send("requestOrganizationData", data);
  }

  updateOrganizationData(data: dto.UpdateOrganizationDataDto) {
    this.send("updateOrganizationData", data);
  }

  requestAllUserData(data: dto.RequestAllUserDataDto) {
    this.send("requestAllUserData", data);
  }

  requestUserData(data: dto.RequestUserDataDto) {
    this.send("requestUserData", data);
  }

  updateUserData(data: dto.UpdateUserDataDto) {
    this.send("updateUserData", data);
  }

  setAuthToDevice(data: dto.SetAuthToDeviceDto) {
    this.send("setAuthToDevice", data);
  }

  setAuthToOAuth(data: dto.SetAuthToOAuthDto) {
    this.send("setAuthToOAuth", data);
  }

  banUser(data: dto.BanUserDto) {
    this.send("banUser", data);
  }

  addManager(data: dto.AddManagerDto) {
    this.send("addManager", data);
  }

  joinOrganization(data: dto.JoinOrganizationDto) {
    this.send("joinOrganization", data);
  }

  closeAccount(data: dto.CloseAccountDto) {
    this.send("closeAccount", data);
  }

  onUpdateUserData(callback: (data: dto.UpdateUserDataDto) => void) {
    this.socket.removeAllListeners("updateUserData");
    this.socket.on("updateUserData", (data) => callback(data));
  }

  onUpdateErrorData(callback: (data: dto.UpdateErrorDto) => void) {
    this.socket.removeAllListeners("updateErrorData");
    this.socket.on("updateErrorData", (data) => callback(data));
  }

  onUpdateChallengeData(callback: (data: dto.UpdateChallengeDataDto) => void) {
    this.socket.removeAllListeners("updateChallengeData");
    this.socket.on("updateChallengeData", (data) => callback(data));
  }

  onUpdateEventTrackerData(callback: (data: dto.EventTrackerDto) => void) {
    this.socket.removeAllListeners("updateEventTrackerData");
    this.socket.on("updateEventTrackerData", (data) => callback(data));
  }

  onUpdateEventData(callback: (data: dto.UpdateEventDataDto) => void) {
    this.socket.removeAllListeners("updateEventData");
    this.socket.on("updateEventData", (data) => callback(data));
  }

  onUpdateLeaderData(callback: (data: dto.UpdateLeaderDataDto) => void) {
    this.socket.removeAllListeners("updateLeaderData");
    this.socket.on("updateLeaderData", (data) => callback(data));
  }

  onGroupInvitation(callback: (data: dto.GroupInviteDto) => void) {
    this.socket.removeAllListeners("groupInvitation");
    this.socket.on("groupInvitation", (data) => callback(data));
  }

  onUpdateGroupData(callback: (data: dto.UpdateGroupDataDto) => void) {
    this.socket.removeAllListeners("updateGroupData");
    this.socket.on("updateGroupData", (data) => callback(data));
  }

  onUpdateOrganizationData(
    callback: (data: dto.UpdateOrganizationDataDto) => void
  ) {
    this.socket.removeAllListeners("updateOrganizationData");
    this.socket.on("updateOrganizationData", (data) => callback(data));
  }
}
