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
  admins: [] as UpdateAdminDataAdminDto[],
  events: [] as EventDto[],
  challenges: new Map<string, ChallengeDto>(),
  rewards: new Map<string, RewardDto>(),
  selectedEvent: null as string | null,
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

  if (!connection.connection) return <>{props.children}</>;

  const sock = useMemo(
    () => new ServerApi(connection.connection!),
    [connection]
  );

  const [serverData, setServerData] = useState({ ...defaultData });

  const methods = useMemo(
    () => ({
      selectEvent(id: string | null) {
        setServerData({ ...serverData, selectedEvent: id });
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
      serverData.admins = serverData.admins.filter(
        (admin) =>
          !data.admins.some(
            (adminUpdate) =>
              !adminUpdate.requesting && admin.id === adminUpdate.id
          )
      );
      data.admins.forEach((adminUpdate) => {
        if (adminUpdate.requesting) serverData.admins.push(adminUpdate);
      });
      setServerData(serverData);
    });
    sock.onUpdateEventData((data) => {
      serverData.events = serverData.events.filter(
        (ev) => !data.deletedIds.includes(ev.id)
      );
      setServerData(serverData);
    });
    sock.onUpdateChallengeData((data) => {
      data.deletedIds.forEach((id) => serverData.challenges.delete(id));
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
  }, [sock, serverData, setServerData]);

  return (
    <ServerDataContext.Provider value={{ ...serverData, ...methods }}>
      {props.children}
    </ServerDataContext.Provider>
  );
}
