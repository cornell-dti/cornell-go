import {
  createContext,
  ReactNode,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { ChallengeDto } from "../dto/challenge.dto";
import { UpdateErrorDto } from "../dto/client.dto";
import { EventDto } from "../dto/event.dto";
import { UserDto } from "../dto/user.dto";
import { GroupDto } from "../dto/group.dto";
import { OrganizationDto } from "../dto/organization.dto";
import { RewardDto } from "../dto/reward.dto";
import { ServerApi } from "./ServerApi";
import { ServerConnectionContext } from "./ServerConnection";

/**  object to store user data fetched from server */
const defaultData = {
  events: new Map<string, EventDto>(),
  challenges: new Map<string, ChallengeDto>(),
  rewards: new Map<string, RewardDto>(),
  organizations: new Map<string, OrganizationDto>(),
  users: new Map<string, UserDto>(),
  groups: new Map<string, GroupDto>(),
  selectedEvent: "" as string,
  selectedOrg: "" as string,
  errors: new Map<string, UpdateErrorDto>(),
  selectEvent(id: string) {},
  selectOrg(id: string) {},
  setAdminStatus(id: string, granted: boolean) {},
  updateReward(reward: RewardDto) {},
  deleteReward(id: string) {},
  updateChallenge(challenge: ChallengeDto) {},
  deleteChallenge(id: string) {},
  updateEvent(event: EventDto) {},
  deleteEvent(id: string) {},
  updateOrganization(organization: OrganizationDto) {},
  deleteOrganization(id: string) {},
  deleteError(id: string) {},
  updateUser(user: UserDto) {},
  deleteUser(id: string) {},
  updateGroup(event: GroupDto) {},
  deleteGroup(id: string) {},
};

export const ServerDataContext = createContext(defaultData);

export function ServerDataProvider(props: { children: ReactNode }) {
  const connection = useContext(ServerConnectionContext);

  const sock = useMemo(
    () => new ServerApi(connection.connection!),
    [connection]
  );

  const [serverData, setServerData] = useState(() => ({ ...defaultData }));

  const methods = useMemo(
    () => ({
      selectEvent(id: string) {
        setServerData({ ...serverData, selectedEvent: id });
        sock.requestChallengeData({
          challengeIds: serverData.events.get(id)?.challengeIds ?? [],
        });
        sock.requestRewardData({
          rewardIds: serverData.events.get(id)?.rewardIds ?? [],
        });
      },
      selectOrg(id: string) {
        setServerData({ ...serverData, selectedOrg: id, selectedEvent: "" });
        sock.requestEventData({
          eventIds: serverData.organizations.get(id)?.events ?? [],
        });
      },
      selectOrganization(id: string) {
        setServerData({ ...serverData, selectedOrg: id, selectedEvent: "" });
        sock.requestEventData({
          eventIds: serverData.organizations.get(id)?.events ?? [],
        });
      },
      updateReward(reward: RewardDto) {
        sock.updateRewardData({ reward, deleted: false });
      },
      deleteReward(id: string) {
        sock.updateRewardData({ reward: id, deleted: true });
      },
      updateChallenge(challenge: ChallengeDto) {
        sock.updateChallengeData({ challenge, deleted: false });
      },
      deleteChallenge(id: string) {
        sock.updateChallengeData({ challenge: id, deleted: true });
      },
      updateEvent(event: EventDto) {
        sock.updateEventData({ event: event, deleted: false });
      },
      deleteEvent(id: string) {
        sock.updateEventData({ event: id, deleted: true });
      },
      deleteError(id: string) {
        serverData.errors.delete(id);
        setTimeout(() => setServerData({ ...serverData }), 0);
      },
      updateUser(user: UserDto) {
        sock.updateUsers({ user, deleted: false });
      },
      deleteUser(id: string) {
        sock.updateUsers({ user: id, deleted: true });
      },
      updateGroup(group: GroupDto) {
        sock.updateGroupData({ group, deleted: false });
      },
      deleteGroup(id: string) {
        sock.updateGroupData({ group: id, deleted: true });
      },
      updateOrganization(organization: OrganizationDto) {
        sock.updateOrganizationData({
          organization,
          deleted: false,
        });
      },
      deleteOrganization(id: string) {
        sock.updateOrganizationData({ organization: id, deleted: true });
      },
    }),
    [serverData, setServerData, sock]
  );

  useEffect(() => {
    sock.requestOrganizationData({ admin: true });
    sock.requestAllUserData({});
    sock.requestGroupData({});
  }, [sock]);

  /** Update defaultData object when ServerApi websocket receives a response */
  useEffect(() => {
    sock.onUpdateEventData((data) => {
      if (data.deleted) {
        serverData.events.delete(data.event as string);
        if (data.event === serverData.selectedEvent) {
          serverData.selectedEvent = "";
        }
      } else {
        const oldChallenges =
          serverData.events.get((data.event as EventDto).id)?.challengeIds ??
          [];

        const oldRewards =
          serverData.events.get((data.event as EventDto).id)?.rewardIds ?? [];

        sock.requestChallengeData({
          challengeIds: (data.event as EventDto).challengeIds.filter(
            (chal) => !(chal in oldChallenges)
          ),
        });

        sock.requestRewardData({
          rewardIds: (data.event as EventDto).rewardIds.filter(
            (rw) => !(rw in oldRewards)
          ),
        });

        serverData.events.set(
          (data.event as EventDto).id,
          data.event as EventDto
        );
      }

      setTimeout(() => setServerData({ ...serverData }), 0);
    });
    sock.onUpdateChallengeData((data) => {
      if (data.deleted) {
        serverData.challenges.delete(data.challenge as string);
      } else {
        serverData.challenges.set(
          (data.challenge as ChallengeDto).id,
          data.challenge as ChallengeDto
        );
      }

      setTimeout(() => setServerData({ ...serverData }), 0);
    });
    sock.onUpdateRewardData((data) => {
      if (data.deleted) {
        serverData.rewards.delete(data.reward as string);
      } else {
        serverData.rewards.set(
          (data.reward as RewardDto).id,
          data.reward as RewardDto
        );
      }

      setTimeout(() => setServerData({ ...serverData }), 0);
    });
    sock.onUpdateUserData((data) => {
      if (data.deleted) {
        serverData.users.delete((data.user as UserDto).id);
      } else {
        serverData.users.set((data.user as UserDto).id, data.user as UserDto);
      }

      setTimeout(() => setServerData({ ...serverData }), 0);
    });
    sock.onUpdateGroupData((data) => {
      if (data.deleted) {
        serverData.groups.delete((data.group as GroupDto).id);
      } else {
        serverData.groups.set(
          (data.group as GroupDto).id,
          data.group as GroupDto
        );
      }

      setTimeout(() => setServerData({ ...serverData }), 0);
    });
    sock.onUpdateOrganizationData((data) => {
      if (data.deleted) {
        serverData.organizations.delete(data.organization as string);
      } else {
        const oldEvents =
          serverData.organizations.get(
            (data.organization as OrganizationDto).id
          )?.events ?? [];

        sock.requestEventData({
          eventIds: (data.organization as OrganizationDto).events.filter(
            (ev) => !(ev in oldEvents)
          ),
        });

        serverData.organizations.set(
          (data.organization as OrganizationDto).id,
          data.organization as OrganizationDto
        );
      }

      setTimeout(() => setServerData({ ...serverData }), 0);
    });
    sock.onUpdateErrorData((data) => {
      serverData.errors.set("Error", data);
      setTimeout(() => setServerData({ ...serverData }), 0);
    });
  }, [sock, serverData, setServerData]);

  if (!connection.connection) return <>{props.children}</>;

  return (
    <ServerDataContext.Provider value={{ ...serverData, ...methods }}>
      {props.children}
    </ServerDataContext.Provider>
  );
}
