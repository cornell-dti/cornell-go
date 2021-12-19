import { EventBase } from './event-base';
import { GroupMember } from './group-member';

export interface Group {
  id: string;

  /** Current event of the group */
  currentEvent: EventBase;

  /** Friendly id of the group */
  friendlyId: string;

  /** Members of the group, with the host at index 0 */
  members: GroupMember[];
}
