import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { UpdateGroupDataDto } from 'src/client/update-group-data.dto';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { EventService } from '../event/event.service';
import { User } from '../model/user.entity';
import { UserService } from '../user/user.service';
import { ChallengeService } from './challenge.service';
import { CompletedChallengeDto } from './completed-challenge.dto';
import { RequestChallengeDataDto } from './request-challenge-data.dto';
import { SetCurrentChallengeDto } from './set-current-challenge.dto';

@WebSocketGateway()
export class ChallengeGateway {
  constructor(
    private clientService: ClientService,
    private challengeService: ChallengeService,
    private userService: UserService,
    private eventService: EventService,
  ) {}

  @SubscribeMessage('requestChallengeData')
  async requestChallengeData(
    @CallingUser() user: User,
    @MessageBody() data: RequestChallengeDataDto,
  ) {
    const challengeEntities =
      await this.challengeService.getChallengesByIdsWithPrevChallenge(
        user,
        data.challengeIds,
      );

    this.clientService.emitUpdateChallengeData(user, {
      challenges: challengeEntities.map(ch => ({
        id: ch.id,
        name: ch.name,
        description: ch.description,
        imageUrl: ch.imageUrl,
        lat: ch.location.coordinates[1],
        long: ch.location.coordinates[0],
        awardingRadius: ch.awardingRadius,
        closeRadius: ch.closeRadius,
        completionDate: ch.completions[0]?.foundTimestamp?.toUTCString() ?? '',
      })),
    });

    return true;
  }

  @SubscribeMessage('setCurrentChallenge')
  async setCurrentChallenge(
    @CallingUser() user: User,
    @MessageBody() data: SetCurrentChallengeDto,
  ) {
    const basicUser = await this.userService.loadBasic(user);

    const isChallengeValid = await this.eventService.isChallengeInEvent(
      data.challengeId,
      basicUser.groupMember?.group.currentEvent.id ?? '',
    );

    if (!isChallengeValid) return false;

    const eventTracker = await this.eventService.getCurrentEventTrackerForUser(
      basicUser,
    );

    const challenge = await this.challengeService.getChallengeById(
      data.challengeId,
    );

    // Is user switching to or from the star challenge
    const isStarChallengeAffected =
      challenge.eventIndex === -1 ||
      eventTracker.currentChallenge.eventIndex === -1;

    // Is user skipping while it's allowed
    const isSkippingWhileAllowed =
      eventTracker.currentChallenge.eventIndex < challenge.eventIndex &&
      (eventTracker.event.skippingEnabled ||
        this.challengeService.isChallengeCompletedByUser(user, challenge));

    if (isStarChallengeAffected || isSkippingWhileAllowed) return false;

    eventTracker.currentChallenge = challenge;
    await this.eventService.saveTracker(eventTracker);

    const group = await this.userService.loadGroup(user, true);

    const updateData: UpdateGroupDataDto = {
      curEventId: group.currentEvent.id,
      members: [
        {
          id: basicUser.id,
          name: basicUser.username,
          points: basicUser.score,
          host: basicUser.groupMember?.isHost ?? false,
          curChallengeId: data.challengeId,
        },
      ],
      update: true,
    };

    group.members.forEach(mem =>
      this.clientService.emitUpdateGroupData(mem.user, updateData),
    );

    return true;
  }

  @SubscribeMessage('completedChallenge')
  async completedChallenge(
    @CallingUser() user: User,
    @MessageBody() data: CompletedChallengeDto,
  ) {
    /**
     * TODO:
     * Create PrevChallenge and associate with user
     * Progress the user to the next challenge (if possible)
     * Reward player upon completion of last challenge (if conditions met)
     * If conditions involve other players, check for reward for all players
     *
     */
  }
}
