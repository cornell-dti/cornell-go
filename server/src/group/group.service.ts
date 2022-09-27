import { EventService } from 'src/event/event.service';
import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { EventBase } from '../model/event-base.entity';
import { Group } from '../model/group.entity';
import { User } from '../model/user.entity';
import { EventTracker } from '../model/event-tracker.entity';
import { UserService } from '../user/user.service';
import { InjectRepository } from '@mikro-orm/nestjs';
import { EntityRepository } from '@mikro-orm/postgresql';
import { v4 } from 'uuid';
import { elementAt, NotFoundError } from 'rxjs';
import { Reference, Unique } from '@mikro-orm/core';

@Injectable()
export class GroupService {
  constructor(
    @Inject(forwardRef(() => UserService))
    private userService: UserService,
    @Inject(forwardRef(() => EventService))
    private eventService: EventService,
    @InjectRepository(Group)
    private groupsRepository: EntityRepository<Group>,
  ) {}

  /** Creates a group from an event and removes from an old group (does delete empty groups) */
  async createFromEvent(
    event: EventBase,
    host: User,
    isNew = false,
  ): Promise<[Group | undefined, Group]> {
    const oldGroup = isNew ? null : await host.group.load();

    const group: Group = this.groupsRepository.create({
      id: v4(),
      currentEvent: event,
      members: [host],
      friendlyId: '',
      host: null!,
    });

    group.friendlyId = group.id.substring(9, 13);

    // If there is an oldGroup then create a new oldGroup that is processed based on whether the user is the host.
    const oldGroupNew = oldGroup
      ? await this.checkGroupSizeForRemoval(
          oldGroup,
          oldGroup.host.id === host.id,
        )
      : undefined;

    await this.groupsRepository.persistAndFlush(group);
    if (oldGroupNew) {
      oldGroupNew.members.remove(host);
      await this.groupsRepository.persistAndFlush(oldGroupNew);
    }
    group.host = Reference.create(host);
    await this.groupsRepository.persistAndFlush(group);
    host.group = Reference.create(group);
    await this.groupsRepository.persistAndFlush(group);

    return [oldGroupNew, group];
  }

  async saveGroup(group: Group) {
    await this.groupsRepository.persistAndFlush(group);
  }

  /** Get group of the user */
  async getGroupForUser(user: User): Promise<Group> {
    return await user.group.load();
  }

  /** Get group from by the friendlyId.
   * Throws an error if the id does not correspond to a group. */
  async getGroupFromFriendlyId(id: string): Promise<Group> {
    return await this.groupsRepository.findOneOrFail({ friendlyId: id });
  }

  /** Invalidates a user's group data forever */
  async orphanUser(user: User) {
    await this.eventService.deleteAllEventTrackers(user);
    await this.leaveGroup(user);
    if (user.group)
      await this.groupsRepository.removeAndFlush(await user.group.load());
  }

  /* If the user is the only member, deletes the group. */
  async checkGroupSizeForRemoval(
    group: Group,
    didHostLeave: boolean,
  ): Promise<Group | undefined> {
    // If the user is the only member then delete the group and return undefined.
    if ((await group.members.loadCount()) === 1) {
      await this.groupsRepository.removeAndFlush(group);
      return undefined;
    } else if (didHostLeave) {
      // If the user is the host and they left the group then a new host is chosen from the remaining users in the group.
      group.host = Reference.create(
        (await group.members.loadItems()).filter(
          u => group.host.id !== u.id,
        )[0],
      );
      await this.groupsRepository.persistAndFlush(group);
    }
    return group;
  }

  /** Adds user to an existing group, given by the group's id.
   * Returns the old group if it still exists, or null. */
  async joinGroup(user: User, joinId: string): Promise<Group | undefined> {
    const group = await this.getGroupFromFriendlyId(joinId);
    const oldGroup = await user.group.load();

    if (oldGroup.friendlyId === joinId) return;

    const host = await group.host.load();

    if (host.restrictedBy?.id !== user.restrictedBy?.id) return;

    const ret = await this.checkGroupSizeForRemoval(
      oldGroup,
      oldGroup.host.id === user.id,
    );

    group.members.add(user);
    user.group = Reference.create(group);

    await this.groupsRepository.persistAndFlush(group);
    return ret;
  }

  /** Moves the user out of their current group into a new group.
   * Returns the old group if it still exists, or null. */
  async leaveGroup(user: User): Promise<Group | undefined> {
    if (!user.group) return;
    const userOldGroup = await this.getGroupForUser(user);
    const [oldGroup] = await this.createFromEvent(
      await userOldGroup.currentEvent.load(),
      user,
    );
    return oldGroup;
  }
}
