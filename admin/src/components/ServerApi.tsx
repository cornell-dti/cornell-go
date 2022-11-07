import { Socket } from "socket.io-client";
import { RequestAdminsDto } from "../dto/request-admins.dto";
import { RequestChallengesDto } from "../dto/request-challenges.dto";
import { RequestEventsDto } from "../dto/request-events.dto";
import { RequestOrganizationsDto } from "../dto/request-organizations.dto";
import { RequestRewardsDto } from "../dto/request-rewards.dto";
import { UpdateAdminDataDto } from "../dto/update-admin-data.dto";
import { UpdateAdminsDto } from "../dto/update-admins.dto";
import { UpdateChallengeDataDto } from "../dto/update-challenge-data.dto";
import { UpdateChallengesDto } from "../dto/update-challenges.dto";
import { UpdateEventDataDto } from "../dto/update-event-data.dto";
import { UpdateEventsDto } from "../dto/update-events.dto";
import { UpdateOrganizationsDto } from "../dto/update-organizations.dto";
import { UpdateRewardDataDto } from "../dto/update-reward-data.dto";
import { UpdateRewardsDto } from "../dto/update-rewards.dto";

export class ServerApi {
  constructor(private socket: Socket) {}

  requestEvents(data: RequestEventsDto) {
    this.socket.emit("requestEvents", data);
  }
  requestChallenges(data: RequestChallengesDto) {
    this.socket.emit("requestChallenges", data);
  }
  requestRewards(data: RequestRewardsDto) {
    this.socket.emit("requestRewards", data);
  }
  requestAdmins(data: RequestAdminsDto) {
    this.socket.emit("requestAdmins", data);
  }
  requestOrganizations(data: RequestOrganizationsDto) {
    this.socket.emit("requestOrganizations", data);
  }

  updateEvents(data: UpdateEventsDto) {
    this.socket.emit("updateEvents", data);
  }
  updateChallenges(data: UpdateChallengesDto) {
    this.socket.emit("updateChallenges", data);
  }
  updateRewards(data: UpdateRewardsDto) {
    this.socket.emit("updateRewards", data);
  }
  updateAdmins(data: UpdateAdminsDto) {
    this.socket.emit("updateAdmins", data);
  }
  updateOrganizations(data: UpdateOrganizationsDto) {
    this.socket.emit("updateOrganizations", data);
  }

  onUpdateAdminData(callback: (data: UpdateAdminDataDto) => void) {
    this.socket.removeAllListeners("updateAdminData");
    this.socket.on("updateAdminData", (data) => callback(data));
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
  onUpdateOrganizations(callback: (data: UpdateOrganizationsDto) => void) {
    this.socket.removeAllListeners("updateOrganizations");
    this.socket.on("updateOrganizations", (data) => callback(data));
  }
}
