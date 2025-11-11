import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ClientService } from '../client/client.service';
import { Challenge, ChallengeTimerStatus } from '@prisma/client';
import {
  TimerStartedDto,
  TimerExtendedDto,
  TimerCompletedDto,
  TimerWarningDto,
} from '../timer/timer.dto';

const EXTENSION_LENGTH = 5 * 60 * 1000; // 5 minutes
const EXTENSION_COST = 0.25; // 25% of the challenge points

@Injectable()
export class TimerService {
  constructor(
    private readonly prisma: PrismaService,
    private clientService: ClientService,
  ) {}

  /** Start a timer for a challenge */
  async startTimer(
    challengeId: string,
    userId: string,
  ): Promise<TimerStartedDto> {
    const challenge = await this.prisma.challenge.findUniqueOrThrow({
      where: { id: challengeId },
    });
    if (!challenge.timerLength) {
      throw new Error('This challenge has no timer (timer length is not set)');
    }
    const endTime = this.calculateEndTime(challenge, 0);
    
    //uses upsert to handle existing timers (e.g., if user reopens challenge)
    const timer = await this.prisma.challengeTimer.upsert({
      where: {
        userId_challengeId: {
          userId: userId,
          challengeId: challengeId,
        },
      },
      update: {
        //reset timer if it already exists
        timerLength: challenge.timerLength,
        startTime: new Date(),
        endTime: endTime,
        currentStatus: ChallengeTimerStatus.ACTIVE,
        warningMilestones: [300, 60, 30],
        warningMilestonesSent: [],
        lastWarningSent: null,
      },
      create: {
        challengeId: challengeId,
        userId: userId,
        timerLength: challenge.timerLength,
        startTime: new Date(),
        endTime: endTime,
        currentStatus: ChallengeTimerStatus.ACTIVE,
        warningMilestones: [300, 60, 30],
        warningMilestonesSent: [],
        lastWarningSent: null,
      },
    });

    //schedule warnings and auto-completion if not in e2e testing
    if (!process.env.TESTING_E2E) {
      await this.scheduleWarnings(challengeId, userId, endTime);
      const completion_delay = endTime.getTime() - Date.now();
      setTimeout(async () => {
        await this.completeTimer(challengeId, userId);
      }, completion_delay);
    }

    return {
      timerId: timer.id,
      endTime: endTime.toISOString(),
      challengeId: challengeId,
    };
  }

  /** Completes a timer for a challenge, and completes the challenge once the timer is completed */
  async completeTimer(
    challengeId: string,
    userId: string,
  ): Promise<TimerCompletedDto> {
    //end timer
    const timer = await this.prisma.challengeTimer.findFirstOrThrow({
      where: { challengeId: challengeId, userId: userId },
      include: { user: true },
    });

    if (!timer) {
      throw new Error('Timer not found');
    }

    // Mark timer as completed
    await this.prisma.challengeTimer.update({
      where: { id: timer.id },
      data: {
        endTime: new Date(),
        currentStatus: ChallengeTimerStatus.COMPLETED,
      },
    });

    //complete the challenge, send to client service -
    await this.clientService.sendEvent(
      [`user/${userId}`],
      'challengeCompleted',
      { challengeId, userId },
    );

    return {
      timerId: timer.id,
      challengeId: challengeId,
      challengeCompleted: true,
    };
  }

  /** Extends a timer for a challenge
   * - updates the end time of the timer
   * - deducts the extension cost from the user's score (25%)
   * - if the timer cannot be extended (the user's score is not enough), an error is thrown
   */
  async extendTimer(
    challengeId: string,
    userId: string,
  ): Promise<TimerExtendedDto> {
    const timer = await this.prisma.challengeTimer.findFirst({
      where: { challengeId: challengeId, userId: userId },
      include: { user: true },
    });
    if (!timer) {
      throw new Error('Timer not found');
    }
    const canExtend = await this.canExtendTimer(userId, challengeId);
    if (!canExtend) {
      throw new Error('Cannot extend timer');
    }

    const challenge = await this.prisma.challenge.findUniqueOrThrow({
      where: { id: challengeId },
    });
    if (!challenge) {
      throw new Error('Challenge not found');
    }

    const newEndTime = this.calculateEndTime(challenge, 1);
    const extensionCost = this.calculateExtensionCost(challenge.points);

    await this.prisma.user.update({
      where: { id: timer.user.id },
      data: { score: { decrement: extensionCost } },
    });

    await this.prisma.challengeTimer.update({
      where: { id: timer.id },
      data: { endTime: newEndTime },
    });

    return {
      timerId: timer.id,
      challengeId: challengeId,
      newEndTime: newEndTime.toISOString(),
    };
  }

  /** Calculate the points deducted for using an extension
   */
  private calculateExtensionCost(basePoints: number): number {
    return Math.floor(basePoints * EXTENSION_COST);
  }

  /** Schedules warning for a timer at given milestones
   * - schedules warnings for each milestone based on the end time of the timer (ex. if milestone has 30, sends a warning at endtime-30: 30 seconds left)
   */
  async scheduleWarnings(
    challengeId: string,
    userId: string,
    endTime: Date,
  ): Promise<void> {
    const timer = await this.prisma.challengeTimer.findFirst({
      where: { challengeId: challengeId, userId: userId },
    });

    if (!timer) {
      throw new Error('Timer not found');
    }

    const milestones = timer.warningMilestones;

    for (const milestone of milestones) {
      const warningTime = new Date(endTime.getTime() - milestone * 1000); //convert to milliseconds
      const now = new Date();

      if (warningTime > now) {
        const delay = warningTime.getTime() - now.getTime(); //how long until warning should be sent
        setTimeout(async () => {
          // send warning if delay is > 0
          await this.sendWarning(challengeId, userId, milestone);
        }, delay);
      }
    }
  }

  /** Sends a warning for a timer at given milestones
   * - updates timer's warningMilestonesSent and lastWarningSent
   */
  async sendWarning(
    challengeId: string,
    userId: string,
    milestone: number,
  ): Promise<TimerWarningDto> {
    const timer = await this.prisma.challengeTimer.findFirst({
      where: { challengeId: challengeId, userId: userId },
    });
    if (!timer) {
      throw new Error('Timer not found');
    }
    if (timer.currentStatus != ChallengeTimerStatus.ACTIVE) {
      throw new Error('Timer is not active');
    }
    if (timer.warningMilestonesSent.includes(milestone)) {
      throw new Error('Warning milestone already sent');
    }

    if (!timer.endTime) {
      throw new Error('Timer end time is not set');
    }

    const timeRemaining = Math.max(
      0,
      Math.floor((timer.endTime.getTime() - Date.now()) / 1000),
    );

    const warningDto: TimerWarningDto = {
      challengeId: challengeId,
      milestone: milestone,
      timeRemaining: timeRemaining,
    };

    await this.clientService.sendEvent(
      [`user/${timer.userId}`],
      'timerWarning',
      warningDto,
    );

    await this.prisma.challengeTimer.update({
      where: { id: timer.id },
      data: {
        warningMilestonesSent: { push: milestone },
        lastWarningSent: new Date(),
      },
    });

    return warningDto;
  }

  /** Calculates end time of a challenge based on number of extensions used
   * Formula: Current time + timer length + 5 minutes for each extension used
   */
  private calculateEndTime(challenge: Challenge, extensionsUsed: number): Date {
    if (!challenge.timerLength) {
      throw new Error('Challenge timer length is not set');
    }
    return new Date(
      Date.now() +
        challenge.timerLength * 1000 +
        extensionsUsed * EXTENSION_LENGTH,
    );
  }

  /** Checks if a timer can be extended by seeing if the user has a high enoughscore to allow for a deduction of points when an extension is used */
  async canExtendTimer(userId: string, challengeId: string): Promise<boolean> {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });
    if (!user) {
      return false;
    }
    const challenge = await this.prisma.challenge.findUniqueOrThrow({
      where: { id: challengeId },
    });
    if (!challenge) {
      throw new Error('Challenge not found');
    }
    const timer = await this.prisma.challengeTimer.findFirst({
      where: { challengeId: challengeId, userId: userId },
    });

    if (!timer) {
      return false;
    }
    if (timer.currentStatus != ChallengeTimerStatus.ACTIVE) {
      return false;
    }
    if (user.score < this.calculateExtensionCost(challenge.points)) {
      return false;
    }
    return true;
  }
}
