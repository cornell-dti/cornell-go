import {
  createContext,
  ReactNode,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import {
  ChallengeDto,
  UpdateErrorDto,
  EventDto,
  GroupDto,
  UserDto,
  OrganizationDto,
  AchievementDto,
  QuizQuestionDto,
} from '../all.dto';

import { ServerApi } from './ServerApi';
import { ServerConnectionContext } from './ServerConnection';

/**  object to store user data fetched from server */
const defaultData = {
  events: new Map<string, EventDto>(),
  achievements: new Map<string, AchievementDto>(),
  challenges: new Map<string, ChallengeDto>(),
  organizations: new Map<string, OrganizationDto>(),
  users: new Map<string, UserDto>(),
  groups: new Map<string, GroupDto>(),
  quizQuestions: new Map<string, QuizQuestionDto>(),
  selectedEvent: '' as string,
  selectedOrg: '' as string,
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
  async updateQuizQuestion(
    question: QuizQuestionDto,
  ): Promise<string | undefined> {
    return undefined;
  },
  async deleteQuizQuestion(id: string): Promise<string | undefined> {
    return undefined;
  },
  async requestQuizQuestions(challengeId: string): Promise<number | undefined> {
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
        setServerData(prev => {
          sock.requestChallengeData({
            challenges: prev.events.get(id)?.challenges ?? [],
          });
          return { ...prev, selectedEvent: id };
        });
      },
      selectOrg(id: string) {
        setServerData(prev => {
          sock.requestEventData({
            events: prev.organizations.get(id)?.events ?? [],
          });
          return { ...prev, selectedOrg: id, selectedEvent: '' };
        });
      },
      selectOrganization(id: string) {
        setServerData(prev => {
          sock.requestEventData({
            events: prev.organizations.get(id)?.events ?? [],
          });
          return { ...prev, selectedOrg: id, selectedEvent: '' };
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
        setServerData(prev => {
          const newErrors = new Map(prev.errors);
          newErrors.delete(id);
          return { ...prev, errors: newErrors };
        });
      },
      updateUser(user: UserDto) {
        return sock.updateUserData({ user, deleted: false });
      },
      deleteUser(id: string) {
        return sock.updateUserData({ user: { id }, deleted: true });
      },
      banUser(userId: string, isBanned: boolean) {
        return sock.banUser({ userId, isBanned });
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
      updateQuizQuestion(question: QuizQuestionDto) {
        return sock.updateQuizQuestionData({ question, deleted: false });
      },
      deleteQuizQuestion(id: string) {
        return sock.updateQuizQuestionData({ question: { id }, deleted: true });
      },
      requestQuizQuestions(challengeId: string) {
        return sock.requestQuizQuestions({ challengeId });
      },
    }),
    [sock],
  );

  useEffect(() => {
    sock.requestOrganizationData({ admin: true });
    sock.requestAllUserData({});
    sock.requestGroupData({});
  }, [sock]);

  /** Update defaultData object when ServerApi websocket receives a response */
  useEffect(() => {
    sock.onUpdateAchievementData(data => {
      setServerData(prev => {
        const newAchievements = new Map(prev.achievements);
        if (data.deleted) {
          newAchievements.delete(data.achievement.id);
        } else {
          newAchievements.set(
            (data.achievement as AchievementDto).id,
            data.achievement as AchievementDto,
          );
        }
        return { ...prev, achievements: newAchievements };
      });
    });
    sock.onUpdateEventData(data => {
      setServerData(prev => {
        const newEvents = new Map(prev.events);
        let newSelectedEvent = prev.selectedEvent;
        if (data.deleted) {
          newEvents.delete(data.event.id);
          if (data.event.id === prev.selectedEvent) {
            newSelectedEvent = '';
          }
        } else {
          const oldChallenges =
            prev.events.get((data.event as EventDto).id)?.challenges ?? [];

          sock.requestChallengeData({
            challenges:
              (data.event as EventDto).challenges?.filter(
                (chal: string) => !oldChallenges.includes(chal),
              ) ?? [],
          });

          newEvents.set(
            (data.event as EventDto).id,
            data.event as EventDto,
          );
        }
        return { ...prev, events: newEvents, selectedEvent: newSelectedEvent };
      });
    });
    sock.onUpdateChallengeData(data => {
      setServerData(prev => {
        const newChallenges = new Map(prev.challenges);
        if (data.deleted) {
          newChallenges.delete(data.challenge.id);
        } else {
          newChallenges.set(
            (data.challenge as ChallengeDto).id,
            data.challenge as ChallengeDto,
          );
        }
        return { ...prev, challenges: newChallenges };
      });
    });
    sock.onUpdateUserData(data => {
      setServerData(prev => {
        const newUsers = new Map(prev.users);
        if (data.deleted) {
          newUsers.delete((data.user as UserDto).id);
        } else {
          newUsers.set((data.user as UserDto).id, data.user as UserDto);
        }
        return { ...prev, users: newUsers };
      });
    });
    sock.onUpdateGroupData(data => {
      setServerData(prev => {
        const newGroups = new Map(prev.groups);
        if (data.deleted) {
          newGroups.delete((data.group as GroupDto).id);
        } else {
          newGroups.set(
            (data.group as GroupDto).id,
            data.group as GroupDto,
          );
        }
        return { ...prev, groups: newGroups };
      });
    });
    sock.onUpdateOrganizationData(data => {
      setServerData(prev => {
        const newOrganizations = new Map(prev.organizations);
        if (data.deleted) {
          newOrganizations.delete(data.organization.id);
        } else {
          const oldEvents =
            prev.organizations.get(
              (data.organization as OrganizationDto).id,
            )?.events ?? [];

          const oldAchievements =
            prev.organizations.get(
              (data.organization as OrganizationDto).id,
            )?.achivements ?? [];

          sock.requestEventData({
            events: (data.organization as OrganizationDto).events?.filter(
              (ev: string) => !oldEvents.includes(ev),
            ),
          });

          if (data.organization.achivements) {
            sock.requestAchievementData({
              achievements: data.organization.achivements?.filter(
                achId => !oldAchievements.includes(achId),
              ),
            });
          }

          newOrganizations.set(
            (data.organization as OrganizationDto).id,
            data.organization as OrganizationDto,
          );
        }
        return { ...prev, organizations: newOrganizations };
      });
    });
    sock.onUpdateErrorData(data => {
      setServerData(prev => {
        const newErrors = new Map(prev.errors);
        newErrors.set('Error', data);
        return { ...prev, errors: newErrors };
      });
    });
    sock.onUpdateQuizQuestionData(data => {
      setServerData(prev => {
        const newQuizQuestions = new Map(prev.quizQuestions);
        if (data.deleted) {
          newQuizQuestions.delete(data.question.id);
        } else {
          newQuizQuestions.set(
            (data.question as QuizQuestionDto).id,
            data.question as QuizQuestionDto,
          );
        }
        return { ...prev, quizQuestions: newQuizQuestions };
      });
    });
  }, [sock]);

  if (!connection.connection) return <>{props.children}</>;

  return (
    <ServerDataContext.Provider value={{ ...serverData, ...methods }}>
      {props.children}
    </ServerDataContext.Provider>
  );
}
