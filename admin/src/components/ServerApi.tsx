import { Socket } from "socket.io-client";
import {
  RequestChallengeDataDto,
  UpdateChallengeDataDto,
  RequestAllUserDataDto,
  RequestUserDataDto,
  RequestEventDataDto,
  UpdateEventDataDto,
  RequestGroupDataDto,
  UpdateGroupDataDto,
  RequestOrganizationDataDto,
  UpdateOrganizationDataDto,
  UpdateUserDataDto,
  UpdateErrorDto,
} from "../all.dto";

//** Web Sockets callback functions are in ./ServerData.tsx*/
export class ServerApi {
  constructor(private socket: Socket) {}

  send(ev: string, data: {}) {
    console.log(`Sending ${ev} with ${JSON.stringify(data)}`);
    this.socket.emit(ev, data);
  }

  requestEventData(data: RequestEventDataDto) {
    this.send("requestEventData", data);
  }
  requestChallengeData(data: RequestChallengeDataDto) {
    this.send("requestChallengeData", data);
  }
  requestUserData(data: RequestUserDataDto) {
    this.send("requestUserData", data);
  }
  requestAllUserData(data: RequestAllUserDataDto) {
    this.send("requestAllUserData", data);
  }
  requestGroupData(data: RequestGroupDataDto) {
    this.send("requestGroupData", data);
  }
  requestOrganizationData(data: RequestOrganizationDataDto) {
    this.send("requestOrganizationData", data);
  }
  updateEventData(data: UpdateEventDataDto) {
    this.send("updateEventData", data);
  }
  updateChallengeData(data: UpdateChallengeDataDto) {
    this.send("updateChallengeData", data);
  }
  updateUserData(data: UpdateUserDataDto) {
    this.send("updateUserData", data);
  }
  updateGroupData(data: UpdateGroupDataDto) {
    this.send("updateGroupData", data);
  }
  updateOrganizationData(data: UpdateOrganizationDataDto) {
    this.send("updateOrganizationData", data);
  }
  addManager(email: string, organizationId: string) {
    this.send("addManager", {
      email: email,
      organizationId: organizationId,
    });
  }

  onUpdateChallengeData(callback: (data: UpdateChallengeDataDto) => void) {
    this.socket.removeAllListeners("updateChallengeData");
    this.socket.on("updateChallengeData", (data) => callback(data));
  }
  onUpdateEventData(callback: (data: UpdateEventDataDto) => void) {
    this.socket.removeAllListeners("updateEventData");
    this.socket.on("updateEventData", (data) => callback(data));
  }
  onUpdateOrganizationData(
    callback: (data: UpdateOrganizationDataDto) => void
  ) {
    this.socket.removeAllListeners("updateOrganizationData");
    this.socket.on("updateOrganizationData", (data) => callback(data));
  }
  onUpdateUserData(callback: (data: UpdateUserDataDto) => void) {
    this.socket.removeAllListeners("updateUserData");
    this.socket.on("updateUserData", (data) => callback(data));
  }
  onAddManager(callback: (email: string) => void) {
    this.socket.removeAllListeners("addManager");
    this.socket.on("addManager", (email) => callback(email));
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
