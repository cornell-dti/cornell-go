import {
  createContext,
  ReactNode,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { RestrictionDto } from "../dto/request-restrictions.dto";
import { UpdateAdminDataAdminDto } from "../dto/update-admin-data.dto";
import { ChallengeDto } from "../dto/update-challenges.dto";
import { EventDto } from "../dto/update-events.dto";
import { RewardDto } from "../dto/update-rewards.dto";
import { UserDto} from "../dto/update-users.dto";
import { ServerApi } from "./ServerApi";
import { ServerConnectionContext } from "./ServerConnection";

const defaultData = {
  admins: new Map<string, UpdateAdminDataAdminDto>(),
  events: new Map<string, EventDto>(),
  challenges: new Map<string, ChallengeDto>(),
  rewards: new Map<string, RewardDto>(),
  users: new Map<string, UserDto>(),
  restrictions: new Map<string, RestrictionDto>(),
  selectedEvent: "" as string,
  selectEvent(id: string) {},
  setAdminStatus(id: string, granted: boolean) {},
  updateReward(reward: RewardDto) {},
  deleteReward(id: string) {},
  updateChallenge(challenge: ChallengeDto) {},
  deleteChallenge(id: string) {},
  updateEvent(event: EventDto) {},
  deleteEvent(id: string) {},
  updateUser(event: UserDto) {},
  deleteUser(id: string) {},
  updateRestriction(restriction: RestrictionDto) {},
  deleteRestriction(id: string) {},
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
        sock.requestChallenges({
          challengeIds: serverData.events.get(id)?.challengeIds ?? [],
        });
        sock.requestRewards({
          rewardIds: serverData.events.get(id)?.rewardIds ?? [],
        });
      },
      setAdminStatus(id: string, granted: boolean) {
        sock.updateAdmins({ adminUpdates: [{ id, granted }] });
      },
      updateReward(reward: RewardDto) {
        sock.updateRewards({ rewards: [reward], deletedIds: [] });
      },
      deleteReward(id: string) {
        sock.updateRewards({ rewards: [], deletedIds: [id] });
      },
      updateChallenge(challenge: ChallengeDto) {
        sock.updateChallenges({ challenges: [challenge], deletedIds: [] });
      },
      deleteChallenge(id: string) {
        sock.updateChallenges({ challenges: [], deletedIds: [id] });
      },
      updateEvent(event: EventDto) {
        sock.updateEvents({ events: [event], deletedIds: [] });
      },
      deleteEvent(id: string) {
        sock.updateEvents({ events: [], deletedIds: [id] });
      },
      updateUser(user: UserDto) {
        sock.updateUsers({ users: [user], deletedIds: [] });
      },
      deleteUser(id: string) {
        sock.updateUsers({ users: [], deletedIds: [id] });
      },
      updateRestriction(restriction: RestrictionDto) {
        sock.updateRestrictions({
          restrictions: [restriction],
          deletedIds: [],
        });
      },
      deleteRestriction(id: string) {
        sock.updateRestrictions({ restrictions: [], deletedIds: [id] });
      },
    }),
    [serverData, setServerData, sock]
  );

  useEffect(() => {
    sock.requestAdmins({});
    sock.requestEvents({});
    sock.requestRestrictions({});
  }, [sock]);

  useEffect(() => {
    sock.onUpdateAdminData((data) => {
      data.admins.forEach((adminUpdate) => {
        if (adminUpdate.requesting)
          serverData.admins.set(adminUpdate.id, adminUpdate);
        else serverData.admins.delete(adminUpdate.id);
      });
      setServerData({ ...serverData });
    });
    sock.onUpdateEventData((data) => {
      data.deletedIds.forEach((id) => serverData.events.delete(id));
      data.events.forEach((ev) => serverData.events.set(ev.id, ev));
      setTimeout(() => setServerData({ ...serverData }), 0);
    });
    sock.onUpdateChallengeData((data) => {
      data.deletedIds.forEach((id) => serverData.challenges.delete(id));
      data.challenges.forEach((ch) => serverData.challenges.set(ch.id, ch));
      setTimeout(() => setServerData({ ...serverData }), 0);
    });
    sock.onUpdateRewardData((data) => {
      data.deletedIds.forEach((id) => serverData.rewards.delete(id));
      data.rewards.forEach((rw) => serverData.rewards.set(rw.id, rw));
      setTimeout(() => setServerData({ ...serverData }), 0);
    });
    sock.onUpdateRestrictions((data) => {
      data.deletedIds.forEach((id) => serverData.restrictions.delete(id));
      data.restrictions.forEach((r) => serverData.restrictions.set(r.id, r));
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
