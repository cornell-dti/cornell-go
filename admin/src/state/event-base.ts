import { Challenge } from './challenge';
import { EventReward } from './event-reward';

/** Enum describing how this event will reward players */
export enum EventRewardType {
  /** Event ends at specific time, top N people are rewarded */
  LIMITED_TIME_EVENT = 'limited_time_event',
  /** N people who complete event first will be rewarded equally, will be advertised as upcoming */
  WIN_ON_COMPLETION = 'win_on_completion',
  /** N people who complete event first will be rewarded based on their time to completion, will be advertised as upcoming */
  RACE_TO_WIN = 'race_to_win',
  /** Perpetual event with no rewards */
  NO_REWARDS = 'no_rewards',
}

export interface EventBase {
  id: string;

  /** Minimum number of members to complete this event */
  minMembers: number;

  /** If the event allows saving uncompleted challenges for later */
  skippingEnabled: boolean;

  /** True if the event is considered the default option */
  isDefault: boolean;

  /** If true, then the challenge with index -1 is considered a star challenge */
  hasStarChallenge: boolean;

  name: string;

  description: string;

  /** Describes how event is rewarded */
  rewardType: EventRewardType;

  /** True if the event is indexable by a search */
  indexable: boolean;

  /** Describes end time for limited time events and begin time for others */
  time: Date;

  /** Describes the top N people to be rewarded */
  topCount: number;

  /** Describes the rewards */
  rewards: EventReward[];

  /** Ordered list of challenges */
  challenges: Challenge[];

  /** Amount of entities in the "challenges" field (update whenever that changes) */
  challengeCount: number;
}
