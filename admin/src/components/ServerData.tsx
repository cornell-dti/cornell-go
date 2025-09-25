import {
  createContext,
  ReactNode,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import {
  ChallengeDto,
  UpdateErrorDto,
  EventDto,
  GroupDto,
  UserDto,
  OrganizationDto,
  AchievementDto,
} from "../all.dto";

import { ServerApi } from "./ServerApi";
import { ServerConnectionContext } from "./ServerConnection";

/**  object to store user data fetched from server */
const defaultData = {
  events: new Map<string, EventDto>(),
  achievements: new Map<string, AchievementDto>(),
  challenges: new Map<string, ChallengeDto>(),
  organizations: new Map<string, OrganizationDto>(),
  users: new Map<string, UserDto>(),
  groups: new Map<string, GroupDto>(),
  selectedEvent: "" as string,
  selectedOrg: "" as string,
  errors: new Map<string, UpdateErrorDto>(),
  selectEvent(id: string) {},
  selectOrg(id: string) {},
  setAdminStatus(id: string, granted: boolean) {},
  async updateChallenge(challenge: ChallengeDto): Promise<string | undefined> {
    return undefined;
  },
  async deleteChallenge(id: string): Promise<string | undefined> {
    return undefined;
  },
  async updateEvent(event: EventDto): Promise<string | undefined> {
    return undefined;
  },
  async deleteEvent(id: string): Promise<string | undefined> {
    return undefined;
  },
  async updateAchievement(
    achievement: AchievementDto,
  ): Promise<string | undefined> {
    return undefined;
  },
  async deleteAchievement(id: string): Promise<string | undefined> {
    return undefined;
  },
  async updateOrganization(
    organization: OrganizationDto,
  ): Promise<string | undefined> {
    return undefined;
  },
  async deleteOrganization(id: string): Promise<string | undefined> {
    return undefined;
  },
  async addManager(
    email: string,
    orgniazationId: string,
  ): Promise<string | undefined> {
    return undefined;
  },
  deleteError(id: string) {},
  async updateUser(user: UserDto): Promise<boolean | undefined> {
    return undefined;
  },
  async deleteUser(id: string): Promise<boolean | undefined> {
    return undefined;
  },
  async updateGroup(event: GroupDto): Promise<boolean | undefined> {
    return undefined;
  },
  async deleteGroup(id: string): Promise<boolean | undefined> {
    return undefined;
  },
};

export const ServerDataContext = createContext(defaultData);

export function ServerDataProvider(props: { children: ReactNode }) {
  const connection = useContext(ServerConnectionContext);

  const sock = useMemo(
    () => new ServerApi(connection.connection!),
    [connection],
  );

  const [serverData, setServerData] = useState(() => ({ ...defaultData }));

  const methods = useMemo(
    () => ({
      selectEvent(id: string) {
        setServerData({ ...serverData, selectedEvent: id });
        sock.requestChallengeData({
          challenges: serverData.events.get(id)?.challenges ?? [],
        });
      },
      selectOrg(id: string) {
        setServerData({ ...serverData, selectedOrg: id, selectedEvent: "" });
        sock.requestEventData({
          events: serverData.organizations.get(id)?.events ?? [],
        });
      },
      selectOrganization(id: string) {
        setServerData({ ...serverData, selectedOrg: id, selectedEvent: "" });
        sock.requestEventData({
          events: serverData.organizations.get(id)?.events ?? [],
        });
      },
      updateChallenge(challenge: ChallengeDto) {
        return sock.updateChallengeData({ challenge, deleted: false });
      },
      deleteChallenge(id: string) {
        return sock.updateChallengeData({ challenge: { id }, deleted: true });
      },
      updateEvent(event: EventDto) {
        return sock.updateEventData({ event: event, deleted: false });
      },
      deleteEvent(id: string) {
        return sock.updateEventData({ event: { id }, deleted: true });
      },
      updateAchievement(achievement: AchievementDto) {
        return sock.updateAchievementData({ achievement, deleted: false });
      },
      deleteAchievement(id: string) {
        return sock.updateAchievementData({
          achievement: { id },
          deleted: true,
        });
      },
      deleteError(id: string) {
        serverData.errors.delete(id);
        setTimeout(() => setServerData({ ...serverData }), 0);
      },
      updateUser(user: UserDto) {
        return sock.updateUserData({ user, deleted: false });
      },
      deleteUser(id: string) {
        return sock.updateUserData({ user: { id }, deleted: true });
      },
      updateGroup(group: GroupDto) {
        return sock.updateGroupData({ group, deleted: false });
      },
      deleteGroup(id: string) {
        return sock.updateGroupData({ group: { id }, deleted: true });
      },
      updateOrganization(organization: OrganizationDto) {
        return sock.updateOrganizationData({
          organization,
          deleted: false,
        });
      },
      addManager(email: string, organizationId: string) {
        return sock.addManager({ email, organizationId });
      },
      deleteOrganization(id: string) {
        return sock.updateOrganizationData({
          organization: { id },
          deleted: true,
        });
      },
    }),
    [serverData, setServerData, sock],
  );

  useEffect(() => {
    sock.requestOrganizationData({ admin: true });
    sock.requestAllUserData({});
    sock.requestGroupData({});
  }, [sock]);

  /** Update defaultData object when ServerApi websocket receives a response */
  useEffect(() => {
    sock.onUpdateAchievementData((data) => {
      if (data.deleted) {
        serverData.achievements.delete(data.achievement.id);
      } else {
        serverData.achievements.set(
          (data.achievement as AchievementDto).id,
          data.achievement as AchievementDto,
        );
      }

      setTimeout(() => setServerData({ ...serverData }), 0);
    });
    sock.onUpdateEventData((data) => {
      if (data.deleted) {
        serverData.events.delete(data.event.id);
        if (data.event.id === serverData.selectedEvent) {
          serverData.selectedEvent = "";
        }
      } else {
        const oldChallenges =
          serverData.events.get((data.event as EventDto).id)?.challenges ?? [];

        sock.requestChallengeData({
          challenges:
            (data.event as EventDto).challenges?.filter(
              (chal: string) => !(chal in oldChallenges),
            ) ?? [],
        });

        serverData.events.set(
          (data.event as EventDto).id,
          data.event as EventDto,
        );
      }

      setTimeout(() => setServerData({ ...serverData }), 0);
    });
    sock.onUpdateChallengeData((data) => {
      if (data.deleted) {
        serverData.challenges.delete(data.challenge.id);
      } else {
        serverData.challenges.set(
          (data.challenge as ChallengeDto).id,
          data.challenge as ChallengeDto,
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
          data.group as GroupDto,
        );
      }

      setTimeout(() => setServerData({ ...serverData }), 0);
    });
    sock.onUpdateOrganizationData((data) => {
      if (data.deleted) {
        serverData.organizations.delete(data.organization.id);
      } else {
        const oldEvents =
          serverData.organizations.get(
            (data.organization as OrganizationDto).id,
          )?.events ?? [];

        const oldAchievements =
          serverData.organizations.get(
            (data.organization as OrganizationDto).id,
          )?.achivements ?? [];

        sock.requestEventData({
          events: (data.organization as OrganizationDto).events?.filter(
            (ev: string) => !(ev in oldEvents),
          ),
        });

        if (data.organization.achivements) {
          sock.requestAchievementData({
            achievements: data.organization.achivements?.filter(
              (achId) => !(achId in oldAchievements),
            ),
          });
        }

        serverData.organizations.set(
          (data.organization as OrganizationDto).id,
          data.organization as OrganizationDto,
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
