import { Injectable } from '@nestjs/common';
import {
  EventBase,
  Organization,
  DifficultyMode,
  TimeLimitationType,
  OrganizationSpecialUsage,
  User,
  LocationType,
  AchievementType,
  EventCategoryType,
} from '@prisma/client';
import { ClientService } from '../client/client.service';
import { v4 } from 'uuid';
import { PrismaService } from '../prisma/prisma.service';
import { OrganizationDto, UpdateOrganizationDataDto } from './organization.dto';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';
import { Action } from '../casl/action.enum';
import { subject } from '@casl/ability';
import { accessibleBy } from '@casl/prisma';

/**
 * Default data used when creating a new event if specific values are not provided.
 */
export const defaultEventData = {
  name: 'Default Event',
  description: 'Default Event',
  longDescription: 'This is a default event created for the organization.',
  requiredMembers: 1,
  difficulty: DifficultyMode.NORMAL,
  category: EventCategoryType.NATURE,
  timeLimitation: TimeLimitationType.PERPETUAL,
  indexable: true,
  endTime: new Date('2060'),
  latitude: 42.44755580740012,
  longitude: -76.48504614830019,
};

/**
 * Default data used when creating a new challenge if specific values are not provided.
 */
export const defaultChallengeData = {
  eventIndex: 0,
  name: 'Default Challenge',
  location: LocationType.ARTS_QUAD,
  description: 'McGraw Tower',
  points: 100,
  imageUrl:
    'https://upload.wikimedia.org/wikipedia/commons/5/5f/CentralAvenueCornell2.jpg',
  latitude: 42.44755580740012,
  longitude: -76.48504614830019,
  awardingRadius: 50,
  closeRadius: 100,
};

/**
 * Default data used when creating a new achievement if specific values are not provided.
 */
export const defaultAchievementData = {
  eventIndex: 0,
  requiredPoints: 50,
  name: 'Default Achievement',
  description: 'Statue',
  imageUrl:
    'https://upload.wikimedia.org/wikipedia/commons/5/5f/CentralAvenueCornell2.jpg',
  locationType: LocationType.ARTS_QUAD,
  achievementType: AchievementType.TOTAL_CHALLENGES,
};

/**
 * Service responsible for managing organizations and their related entities.
 *
 * @remarks
 * Handles creation, retrieval, update, and deletion of organizations.
 * Manages organization membership, access codes, and default entities (events, challenges).
 * Interacts with PrismaService for database operations and uses CASL for authorization.
 */
@Injectable()
export class OrganizationService {
  constructor(
    private prisma: PrismaService,
    private clientService: ClientService,
    private abilityFactory: CaslAbilityFactory,
  ) {}

  // TODO: maybe move this to challenge.service in the future?
  /**
   * Creates a default challenge, optionally linking it to a specific event.
   *
   * @remarks
   * If an event ID (`evId`) is provided, the new challenge's `eventIndex` is set
   * to be one greater than the maximum existing index within that event.
   * Otherwise, the `eventIndex` defaults to 0.
   *
   * @param evId - Optional. The ID of the event to link the new challenge to.
   * @returns A promise that resolves to the newly created Challenge object.
   */
  async makeDefaultChallenge(evId?: string) {
    let index = 0;
    if (evId) {
      const maxIndexChallenge = await this.prisma.challenge.aggregate({
        _max: { eventIndex: true },
        where: { linkedEventId: evId },
      });

      index = (maxIndexChallenge._max.eventIndex ?? -1) + 1;
    }

    return await this.prisma.challenge.create({
      data: {
        ...defaultChallengeData,
        linkedEventId: evId,
        eventIndex: index,
      },
    });
  }

  // TODO: maybe move this to event.service in the future?
  /**
   * Creates a default event, optionally linking it to a specific organization.
   *
   * @remarks
   * Also creates a default challenge linked to this new event.
   * Uses `defaultEventData` and overrides the name if provided.
   *
   * @param orgId - Optional. The ID of the organization to link the new event to.
   * @param name - Optional. A specific name for the event, overriding the default.
   * @returns A promise that resolves to the newly created EventBase object.
   */
  async makeDefaultEvent(orgId?: string, name?: string) {
    const ev = await this.prisma.eventBase.create({
      data: {
        ...defaultEventData,
        ...(name ? { name } : {}),
        usedIn: orgId ? { connect: { id: orgId } } : undefined,
      },
    });

    await this.makeDefaultChallenge(ev.id);

    return ev;
  }

  /**
   * Retrieves the default event for a given organization.
   *
   * @remarks
   * This function specifically looks for an event within the organization that has at least one challenge associated with it.
   * Throws an error if no such event is found.
   *
   * @param org - The organization for which to find the default event.
   * @returns A promise that resolves to the default EventBase object.
   * @throws If no event with challenges is found within the organization.
   */
  async getDefaultEvent(org: Organization): Promise<EventBase> {
    // First try to find an event that has at least one challenge

    return await this.prisma.eventBase.findFirstOrThrow({
      where: {
        usedIn: { some: { id: org.id } },
        challenges: { some: {} }, // This ensures at least one challenge exists
      },
    });
  }

  /**
   * Returns (and creates if it does not exist) the default organization for a specific usage type.
   *
   * @remarks
   * Ensures that default organizations (e.g., for Cornell login, general device login) exist.
   * If a default organization for the given usage doesn't exist, it creates one, along with a corresponding default event and challenge.
   * Generates a unique access code for newly created organizations.
   *
   * @param usage - The specific usage type (e.g., `CORNELL_LOGIN`, `DEVICE_LOGIN`) for the default organization.
   *                Cannot be `NONE`.
   * @returns A promise that resolves to the default Organization object for the specified usage.
   * @throws If `usage` is `OrganizationSpecialUsage.NONE`.
   */
  async getDefaultOrganization(
    usage: OrganizationSpecialUsage,
  ): Promise<Organization> {
    if (usage === OrganizationSpecialUsage.NONE) {
      throw 'Default impossible for NONE';
    }

    let defaultOrg = await this.prisma.organization.findFirst({
      where: { specialUsage: usage },
    });

    if (defaultOrg === null) {
      const ev = await this.makeDefaultEvent(
        undefined,
        usage === OrganizationSpecialUsage.CORNELL_LOGIN
          ? 'Cornell Event'
          : 'Everyone Event',
      );

      defaultOrg = await this.prisma.organization.create({
        data: {
          name:
            usage === OrganizationSpecialUsage.CORNELL_LOGIN
              ? 'Cornell Organization'
              : 'Everyone Organization',
          specialUsage: usage,
          accessCode: this.genAccessCode(),
          events: { connect: { id: ev.id } },
        },
      });
    }

    return defaultOrg;
  }

  /**
   * Retrieves organizations associated with a user.
   *
   * @param user - The user whose organizations are to be fetched.
   * @param admin - If true, fetches organizations where the user is a manager; otherwise, fetches organizations where the user is a member.
   * @returns A promise that resolves to an array of Organization objects.
   */
  async getOrganizationsForUser(user: User, admin: boolean) {
    return await this.prisma.organization.findMany({
      where: admin
        ? { managers: { some: { id: user.id } } }
        : { members: { some: { id: user.id } } },
    });
  }

  /**
   * Fetches a single organization by its unique identifier.
   *
   * @param id - The unique identifier of the organization to fetch.
   * @returns A promise that resolves to the Organization object or null if not found.
   */
  async getOrganizationById(id: string) {
    return await this.prisma.organization.findFirst({ where: { id } });
  }

  /**
   * Fetches a single organization by its access code.
   *
   * @param accessCode - The access code of the organization to fetch.
   * @returns A promise that resolves to the Organization object.
   * @throws If no organization with the given access code is found.
   */
  async getOrganizationByCode(accessCode: string) {
    return await this.prisma.organization.findFirstOrThrow({
      where: { accessCode },
    });
  }

  /**
   * Converts an Organization database entity into an OrganizationDto.
   *
   * @remarks
   * Fetches related entities (members, events, managers, achievements) and includes their IDs in the DTO.
   *
   * @param organization - The Organization object to convert.
   * @returns A promise that resolves to the corresponding OrganizationDto.
   */
  async dtoForOrganization(
    organization: Organization,
  ): Promise<OrganizationDto> {
    const org = this.prisma.organization.findUniqueOrThrow({
      where: { id: organization.id },
    });

    return {
      id: organization.id,
      name: organization.name,
      members: (await org.members({ select: { id: true } })).map(e => e.id),
      events: (await org.events({ select: { id: true } })).map(e => e.id),
      managers: (await org.managers({ select: { id: true } })).map(e => e.id),
      achivements: (await org.achievements({ select: { id: true } })).map(
        e => e.id,
      ),
      accessCode: organization.accessCode,
    };
  }

  /**
   * Emits an update notification for an Organization via WebSocket.
   *
   * @remarks
   * Can signify either an update to an existing organization or its deletion.
   * Converts the organization to a DTO (or just includes the ID if deleted) and sends it
   * to the specified target user or defaults to broadcasting within the organization's context.
   * Uses `clientService.sendProtected` for secure, permission-checked emission.
   *
   * @param organization - The Organization that was updated or deleted.
   * @param deleted - Boolean flag indicating if the organization was deleted.
   * @param target - Optional. The specific user to send the update to. Defaults to broadcasting to the organization ID.
   */
  async emitUpdateOrganizationData(
    organization: Organization,
    deleted: boolean,
    target?: User,
  ) {
    const dto: UpdateOrganizationDataDto = {
      organization: deleted
        ? { id: organization.id }
        : await this.dtoForOrganization(organization),
      deleted,
    };

    await this.clientService.sendProtected(
      'updateOrganizationData',
      target ?? organization.id,
      dto,
      {
        id: organization.id,
        subject: 'Organization',
        dtoField: 'organization',
        prismaStore: this.prisma.organization,
      },
    );
  }

  /**
   * Generates a random hexadecimal string to be used as an organization access code.
   *
   * @privateRemarks
   * This is a simple implementation; consider using a more robust unique code generation strategy
   * for production environments to avoid potential collisions.
   *
   * @returns A 6-character hexadecimal string.
   */
  private genAccessCode() {
    return Math.floor(Math.random() * 0xffffff).toString(16);
  }

  /**
   * Creates or updates an organization based on the provided DTO and user permissions.
   *
   * @remarks
   * Checks if the user has permission to update the organization (if it exists)
   * or create a new one. Filters inaccessible fields based on CASL abilities during updates.
   * Sets the `specialUsage` to `NONE` and generates an access code for new organizations.
   *
   * @param ability - The CASL ability object defining the user's permissions.
   * @param organization - The DTO containing the organization data for creation or update.
   * @returns A promise that resolves to the created or updated Organization object, or null if permissions are insufficient.
   */
  async upsertOrganizationFromDto(
    ability: AppAbility,
    organization: OrganizationDto,
  ) {
    let org = await this.prisma.organization.findFirst({
      where: { id: organization.id },
    });

    const assignData = {
      name: organization.name,
      members: {
        connect: organization.members?.map(id => ({ id })),
      },
      events: {
        connect: organization.events?.map(id => ({ id })),
      },
      achievements: {
        connect: organization.achivements?.map(id => ({ id })),
      },
      specialUsage: OrganizationSpecialUsage.NONE,
    };

    const canUpdateOrg =
      (await this.prisma.organization.count({
        where: {
          AND: [
            accessibleBy(ability, Action.Update).Organization,
            { id: org?.id ?? '' },
          ],
        },
      })) > 0;

    if (org && canUpdateOrg) {
      const updateData = await this.abilityFactory.filterInaccessible(
        org.id,
        assignData,
        'Organization',
        ability,
        Action.Update,
        this.prisma.organization,
      );

      org = await this.prisma.organization.update({
        where: { id: org.id },
        data: updateData,
      });
    } else if (!org && ability.can(Action.Create, 'Organization')) {
      const data = {
        ...assignData,
        name: assignData.name ?? 'New organization',
        accessCode: Math.floor(Math.random() * 0xffffff).toString(16),
      };

      org = await this.prisma.organization.create({
        data,
      });

      console.log(`Created organization ${org.id}`);
    }

    return org;
  }

  /**
   * Subscribes all administrative users to WebSocket updates for a given organization.
   *
   * @remarks
   * Ensures that users with the `administrator` flag set receive real-time updates
   * related to this organization via the `ClientService`.
   *
   * @param org - The organization to which admins should be subscribed.
   */
  async addAllAdmins(org: Organization) {
    const users = await this.prisma.user.findMany({
      where: { administrator: true },
    });

    for (const user of users) {
      this.clientService.subscribe(user, org.id);
    }
  }

  /**
   * Removes an organization based on ID and user permissions.
   *
   * @remarks
   * Checks if the user has `Delete` permission on the organization using CASL.
   * Catches potential errors during deletion (e.g., foreign key constraints) silently.
   *
   * @param ability - The CASL ability object defining the user's permissions.
   * @param id - The ID of the organization to remove.
   * @returns A promise that resolves to true if the organization was successfully deleted (or deletion was permitted), false otherwise (e.g., due to permissions or errors).
   */
  async removeOrganization(ability: AppAbility, id: string) {
    try {
      if (
        await this.prisma.organization.findFirst({
          where: {
            AND: [{ id }, accessibleBy(ability, Action.Delete).Organization],
          },
        })
      ) {
        await this.prisma.organization.delete({
          where: { id },
        });

        console.log(`Deleted organization ${id}`);
        return true;
      }
    } catch {}

    return false;
  }

  /**
   * Ensures that an administrative user has manager and member roles in all organizations.
   *
   * @remarks
   * If the provided user has the `administrator` flag set, this function checks all existing
   * organizations and adds the user as both a manager and a member if they are not already.
   * This is useful for ensuring system administrators have full access.
   *
   * @param potentialAdmin - The user to check and potentially grant full access to.
   */
  async ensureFullAccessIfNeeded(potentialAdmin: User) {
    if (potentialAdmin.administrator) {
      const orgs = await this.prisma.organization.findMany({
        where: { managers: { none: { id: potentialAdmin.id } } },
        select: { id: true },
      });

      for (const { id } of orgs) {
        await this.prisma.user.update({
          where: { id: potentialAdmin.id },
          data: {
            managerOf: { connect: { id } },
            memberOf: { connect: { id } },
          },
        });
      }
    }
  }

  /**
   * Adds a user as a manager (and member) to a specific organization.
   *
   * @remarks
   * Checks if the calling user has `Update` permission on the target organization.
   * Finds the user to be added by email.
   * Updates both the organization (adding the user to managers and members) and the user (adding the organization to `managerOf`).
   *
   * @param ability - The CASL ability object of the user performing the action.
   * @param potentialManagerEmail - The email address of the user to add as a manager.
   * @param organizationId - The ID of the organization to add the manager to.
   * @returns A promise that resolves to true if the manager was successfully added, false otherwise (e.g., permissions denied, user not found, org not found).
   */
  async addManager(
    ability: AppAbility,
    potentialManagerEmail: string,
    organizationId: string,
  ) {
    const org = await this.prisma.organization.findFirst({
      where: {
        AND: [
          accessibleBy(ability, Action.Update).Organization,
          { id: organizationId },
        ],
      },
    });

    const potentialManager = await this.prisma.user.findFirst({
      where: { email: potentialManagerEmail },
    });

    if (!potentialManager || !org) {
      return false;
    }

    await this.prisma.organization.update({
      where: { id: org.id },
      data: {
        managers: { connect: { id: potentialManager.id } },
        members: { connect: { id: potentialManager.id } },
      },
    });

    await this.prisma.user.update({
      where: { id: potentialManager.id },
      data: { managerOf: { connect: { id: org.id } } },
    });

    console.log(`Manager ${potentialManagerEmail} Added`);

    return true;
  }

  /**
   * Allows a user to join an organization using an access code.
   *
   * @remarks
   * Finds the organization by the provided code. If found, adds the user to the organization's members list.
   * Emits an organization update notification to the joining user.
   *
   * @param user - The user attempting to join.
   * @param code - The access code for the organization.
   * @returns A promise that resolves to void. Returns false internally if the organization code is invalid, but the return value isn't explicitly used.
   */
  async joinOrganization(user: User, code: string) {
    const org = await this.prisma.organization.findFirst({
      where: { accessCode: code },
    });

    if (!org) return false;

    await this.prisma.organization.update({
      where: { id: org.id },
      data: { members: { connect: { id: user.id } } },
    });

    await this.emitUpdateOrganizationData(org, false, user);
  }
}
