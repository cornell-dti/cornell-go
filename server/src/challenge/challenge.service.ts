import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { InjectEntityManager, InjectRepository } from '@nestjs/typeorm';
import { EventService } from 'src/event/event.service';
import { UserService } from 'src/user/user.service';
import { EntityManager, Repository } from 'typeorm';
import { Challenge } from '../model/challenge.entity';
import { EventBase } from '../model/event-base.entity';
import { EventTracker } from '../model/event-tracker.entity';
import { PrevChallenge } from '../model/prev-challenge.entity';
import { User } from '../model/user.entity';

@Injectable()
export class ChallengeService {
  constructor(
    private userService: UserService,
    @Inject(forwardRef(() => EventService))
    private eventService: EventService,
    @InjectRepository(Challenge)
    private challengeRepository: Repository<Challenge>,
    @InjectRepository(PrevChallenge)
    private prevChallengeRepository: Repository<PrevChallenge>,
    @InjectEntityManager()
    private entityManager: EntityManager,
  ) {}

  async createNew(event: EventBase) {
    const chal = this.challengeRepository.create({
      eventIndex: 0,
      name: 'New challenge',
      description: 'New challenge',
      imageUrl: '',
      location: { type: 'Point', coordinates: [0, 0] },
      awardingRadius: 0,
      closeRadius: 0,
      completions: [],
      linkedEvent: event,
    });

    await this.challengeRepository.save(chal);

    return chal;
  }

  /** Get challenges with prev challenges for a given user */
  async getChallengesByIdsWithPrevChallenge(
    user: User,
    ids: string[],
  ): Promise<Challenge[]> {
    return await this.challengeRepository
      .createQueryBuilder()
      .whereInIds(ids)
      .leftJoinAndSelect(
        'completions',
        'prevChallenge',
        'prevChallenge.ownerId = :userId',
        { userId: user.id },
      )
      .getMany();
  }

  /** Get a challenge by its id */
  async getChallengeById(id: string) {
    return await this.challengeRepository.findOneOrFail({ id });
  }

  /** Is challenge completed by user */
  async isChallengeCompletedByUser(user: User, challenge: Challenge) {
    return (
      (await this.prevChallengeRepository.count({
        where: {
          owner: user,
          challenge,
        },
      })) > 0
    );
  }

  /** Save a challenge entity */
  async saveChallenge(chal: Challenge) {
    await this.challengeRepository.save(chal);
  }

  /** Save a prev challenge entity */
  async savePrevChallenge(prevChal: PrevChallenge) {
    await this.prevChallengeRepository.save(prevChal);
  }

  /** Find first challenge */
  async getFirstChallengeForEvent(event: EventBase) {
    return await this.challengeRepository.findOneOrFail({
      eventIndex: 0,
      linkedEvent: event,
    });
  }

  /** Get next challenge in a sequence of challenges */
  async nextChallenge(chal: Challenge) {
    try {
      return await this.challengeRepository.findOneOrFail({
        eventIndex: chal.eventIndex + 1,
        linkedEvent: chal.linkedEvent,
      });
    } catch {
      return await this.challengeRepository.findOneOrFail({
        eventIndex: -1,
        linkedEvent: chal.linkedEvent,
      });
    }
  }

  /** Progress user through challenges, ensuring challengeId is current */
  async completeChallenge(user: User, challengeId: string) {
    const group = await this.userService.loadGroup(user, true);

    const eventTracker = await this.eventService.getCurrentEventTrackerForUser(
      user,
    );

    // Ensure that the correct challenge is marked complete
    if (challengeId !== eventTracker.currentChallenge.id) return eventTracker;

    const prevChal = this.prevChallengeRepository.create({
      owner: user,
      challenge: eventTracker.currentChallenge,
      completionPlayers: group.members.map(mem => mem.user),
    });

    await this.prevChallengeRepository.save(prevChal);

    eventTracker.currentChallenge = await this.nextChallenge(
      eventTracker.currentChallenge,
    );

    await this.eventService.saveTracker(eventTracker);

    return eventTracker;
  }
}
