import {
  createContext,
  ReactNode,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { UpdateAdminDataAdminDto } from "../dto/update-admin-data.dto";
import { ChallengeDto } from "../dto/update-challenges.dto";
import { EventDto } from "../dto/update-events.dto";
import { RewardDto } from "../dto/update-rewards.dto";
import { ServerApi } from "./ServerApi";
import { ServerConnectionContext } from "./ServerConnection";

const defaultData = {
  admins: new Map<string, UpdateAdminDataAdminDto>(),
  events: new Map<string, EventDto>(),
  challenges: new Map<string, ChallengeDto>(),
  rewards: new Map<string, RewardDto>(),
  selectedEvent: "" as string,
  selectEvent(id: string) {},
  setAdminStatus(id: string, granted: boolean) {},
  updateReward(reward: RewardDto) {},
  deleteReward(id: string) {},
  updateChallenge(challenge: ChallengeDto) {},
  deleteChallenge(id: string) {},
  updateEvent(event: EventDto) {},
  deleteEvent(id: string) {},
};

export const ServerDataContext = createContext(defaultData);

export function ServerDataProvider(props: { children: ReactNode }) {
  const connection = useContext(ServerConnectionContext);

  const sock = useMemo(
    () => new ServerApi(connection.connection!),
    [connection]
  );

  const [serverData, setServerData] = useState({ ...defaultData });

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
    }),
    [serverData, setServerData, sock]
  );

  useEffect(() => {
    sock.onUpdateAdminData((data) => {
      data.admins.forEach((adminUpdate) => {
        if (adminUpdate.requesting)
          serverData.admins.set(adminUpdate.id, adminUpdate);
        else serverData.admins.delete(adminUpdate.id);
      });
      setServerData(serverData);
    });
    sock.onUpdateEventData((data) => {
      data.deletedIds.forEach(serverData.events.delete);
      data.events.forEach((ev) => serverData.events.set(ev.id, ev));
      setServerData(serverData);
    });
    sock.onUpdateChallengeData((data) => {
      data.deletedIds.forEach(serverData.challenges.delete);
      data.challenges.forEach((chal) =>
        serverData.challenges.set(chal.id, chal)
      );
      setServerData(serverData);
    });
    sock.onUpdateRewardData((data) => {
      data.deletedIds.forEach((id) => serverData.rewards.delete(id));
      data.rewards.forEach((rw) => serverData.rewards.set(rw.id, rw));
      setServerData(serverData);
    });
    sock.requestAdmins({});
    sock.requestEvents({});
  }, [sock, serverData, setServerData]);

  if (!connection.connection) return <>{props.children}</>;

  return (
    <ServerDataContext.Provider value={{ ...serverData, ...methods }}>
      {props.children}
    </ServerDataContext.Provider>
  );
}
