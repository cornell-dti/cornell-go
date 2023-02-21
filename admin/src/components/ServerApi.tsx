import { Socket } from "socket.io-client";
import {
  RequestChallengeDataDto,
  UpdateChallengeDataDto,
} from "../dto/challenge.dto";
import { UpdateErrorDto } from "../dto/client.dto";
import { RequestEventDataDto, UpdateEventDataDto } from "../dto/event.dto";
import { RequestGroupDataDto, UpdateGroupDataDto } from "../dto/group.dto";
import {
  RequestOrganizationDataDto,
  UpdateOrganizationDataDto,
} from "../dto/organization.dto";
import { RequestRewardDataDto, UpdateRewardDataDto } from "../dto/reward.dto";

//** Web Sockets callback functions are in ./ServerData.tsx*/
export class ServerApi {
  constructor(private socket: Socket) {}

  requestEventData(data: RequestEventDataDto) {
    this.socket.emit("requestEventData", data);
  }
  requestChallengeData(data: RequestChallengeDataDto) {
    this.socket.emit("requestChallengeData", data);
  }
  requestRewardData(data: RequestRewardDataDto) {
    this.socket.emit("requestRewardData", data);
  }
  requestGroupData(data: RequestGroupDataDto) {
    this.socket.emit("requestGroupData", data);
  }
  requestOrganizationData(data: RequestOrganizationDataDto) {
    this.socket.emit("requestOrganizationData", data);
  }
  updateEventData(data: UpdateEventDataDto) {
    this.socket.emit("updateEventData", data);
  }
  updateChallengeData(data: UpdateChallengeDataDto) {
    this.socket.emit("updateChallengeData", data);
  }
  updateRewardData(data: UpdateRewardDataDto) {
    this.socket.emit("updateRewardData", data);
  }
  updateGroupData(data: UpdateGroupDataDto) {
    this.socket.emit("updateGroupData", data);
  }
  updateOrganizationData(data: UpdateOrganizationDataDto) {
    this.socket.emit("updateOrganizationData", data);
  }

  onUpdateChallengeData(callback: (data: UpdateChallengeDataDto) => void) {
    this.socket.removeAllListeners("updateChallengeData");
    this.socket.on("updateChallengeData", (data) => callback(data));
  }
  onUpdateEventData(callback: (data: UpdateEventDataDto) => void) {
    this.socket.removeAllListeners("updateEventData");
    this.socket.on("updateEventData", (data) => callback(data));
  }
  onUpdateRewardData(callback: (data: UpdateRewardDataDto) => void) {
    this.socket.removeAllListeners("updateRewardData");
    this.socket.on("updateRewardData", (data) => callback(data));
  }
  onUpdateOrganizationData(
    callback: (data: UpdateOrganizationDataDto) => void
  ) {
    this.socket.removeAllListeners("updateOrganizationData");
    this.socket.on("updateOrganizationData", (data) => callback(data));
  }
  onUpdateGroupData(callback: (data: UpdateGroupDataDto) => void) {
    this.socket.removeAllListeners("updateGroupData");
    this.socket.on("updateGroupData", (data) => callback(data));
  }
  onUpdateErrorData(callback: (data: UpdateErrorDto) => void) {
    this.socket.removeAllListeners("updateErrorData");
    this.socket.on("updateErrorData", (data) => callback(data));
  }
}
