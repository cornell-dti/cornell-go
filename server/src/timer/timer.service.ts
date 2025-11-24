import { Injectable, Inject, forwardRef } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ClientService } from '../client/client.service';
import { Challenge, ChallengeTimerStatus } from '@prisma/client';
import {
  TimerStartedDto,
  TimerExtendedDto,
  TimerCompletedDto,
  TimerWarningDto,
} from '../timer/timer.dto';
import { ChallengeService } from '../challenge/challenge.service';

const EXTENSION_LENGTH = 5 * 60 * 1000; // 5 minutes
const EXTENSION_COST = 0.25; // 25% of the challenge points

@Injectable()
export class TimerService {
  constructor(
    private readonly prisma: PrismaService,
    private clientService: ClientService,
    @Inject(forwardRef(() => ChallengeService))
    private challengeService: ChallengeService,
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
    
    // check if timer already exists to get originalBasePoints 
    const existingTimer = await this.prisma.challengeTimer.findFirst({
      where: {
        userId: userId,
        challengeId: challengeId,
      },
    });
    
    // use originalBasePoints from existing timer if available
    const originalBasePoints = existingTimer?.originalBasePoints || challenge.points;
    // preserve extensionsUsed from existing timer (don't reset on timer restart)
    const preservedExtensionsUsed = existingTimer?.extensionsUsed || 0;
    
    // uses upsert to handle existing timers (e.g., if user reopens challenge)
    const timer = await this.prisma.challengeTimer.upsert({
      where: {
        userId_challengeId: {
          userId: userId,
          challengeId: challengeId,
        },
      },
      update: {
        // reset timer if it already exists, but preserve extensionsUsed
        timerLength: challenge.timerLength,
        startTime: new Date(),
        endTime: endTime,
        currentStatus: ChallengeTimerStatus.ACTIVE,
        extensionsUsed: preservedExtensionsUsed, 
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
        extensionsUsed: 0,
        originalBasePoints: challenge.points, //store original base points
        warningMilestones: [300, 60, 30],
        warningMilestonesSent: [],
        lastWarningSent: null,
      },
    });

    console.log('timer original base points', timer.originalBasePoints);
    
    // restore challenge points to original value when restarting timer
    if (challenge.points !== originalBasePoints) {
      await this.prisma.challenge.update({
        where: { id: challengeId },
        data: {
          points: originalBasePoints,
        },
      });
      
      // emit challenge update to frontend so ChallengeModel gets updated points
      const updatedChallenge = await this.prisma.challenge.findUniqueOrThrow({
        where: { id: challengeId },
      });
      if (updatedChallenge) {
        await this.challengeService.emitUpdateChallengeData(updatedChallenge, false);
      }
    }

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
      extensionsUsed: timer.extensionsUsed,
    };
  }

  /** Completes a timer for a challenge, and completes the challenge once the timer is completed */
  async completeTimer(
    challengeId: string,
    userId: string,
  ): Promise<TimerCompletedDto> {
    const timer = await this.prisma.challengeTimer.findFirst({
      where: { challengeId: challengeId, userId: userId },
      include: { user: true },
    });

    if (!timer) {
      // timer already deleted/completed
      console.log(`Warning: Timer not found for challenge ${challengeId}, userId ${userId}. Scheduled completion may be stale.`);
      return {
        timerId: '',
        challengeId: challengeId,
        challengeCompleted: false,
      };
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
   * - deducts the extension cost from the challenge's points (25%)
   * - if the timer cannot be extended (the challenge's points are not enough), an error is thrown
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
      throw new Error('Cannot extend timer: Insufficient points');
    }

    const challenge = await this.prisma.challenge.findUniqueOrThrow({
      where: { id: challengeId },
    });
    if (!challenge) {
      throw new Error('Challenge not found');
    }

    // calculate extension cost from challenge's original base points: 25% of original base points
    const extensionCost = this.calculateExtensionCost(timer.originalBasePoints);

    const newExtensionsUsed = timer.extensionsUsed + 1;
    // Add 5 minutes to the current end time (or current time if timer already expired)
    const currentEndTime = timer.endTime || new Date();
    const newEndTime = new Date(currentEndTime.getTime() + EXTENSION_LENGTH);

    // update timer with new end time, increment extensions used, set status back to ACTIVE, and reset warnings
    await this.prisma.challengeTimer.update({
      where: { id: timer.id },
      data: { 
        endTime: newEndTime,
        extensionsUsed: newExtensionsUsed,
        currentStatus: ChallengeTimerStatus.ACTIVE, 
        warningMilestonesSent: [],
      },
    });

    // reschedule warnings and auto-completion for the extended timer
    if (!process.env.TESTING_E2E) {
      await this.scheduleWarnings(challengeId, userId, newEndTime);
      const completion_delay = newEndTime.getTime() - Date.now();
      if (completion_delay > 0) {
        setTimeout(async () => {
          await this.completeTimer(challengeId, userId);
        }, completion_delay);
      }
    }

    return {
      timerId: timer.id,
      challengeId: challengeId,
      newEndTime: newEndTime.toISOString(),
      extensionsUsed: newExtensionsUsed,
    };
  }

  /** Calculate the points deducted for using an extension
   */
  private calculateExtensionCost(basePoints: number): number {
    return Math.floor(basePoints * EXTENSION_COST);
  }

  /** Schedules warning for a timer at given milestones
   * - schedules warnings for each milestone based on the end time of the timer (ex. if milestone has 30, sends a warning at endtime-30: 30 seconds left)
   * - schedules warnings 2 seconds early to account for setTimeout inaccuracy, processing time, and network delay
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
    const EARLY_BUFFER_MS = 1500; // 2 seconds early to compensate for delays

    for (const milestone of milestones) {
      const warningTime = new Date(endTime.getTime() - milestone * 1000 - EARLY_BUFFER_MS);
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
   * - Updates timer's warningMilestonesSent and lastWarningSent
   * - Returns null if timer not found or not active (e.g., timer was restarted/completed)
   * - Also validates that the warning is still relevant in case of timer restarting (time remaining is close to milestone)
   */
  async sendWarning(
    challengeId: string,
    userId: string,
    milestone: number,
  ): Promise<TimerWarningDto | null> {
    const timer = await this.prisma.challengeTimer.findFirst({
      where: { challengeId: challengeId, userId: userId },
    });
    if (!timer) {
      // Timer was deleted/completed - scheduled warning is stale, ignore it
      console.log(`Warning: Timer not found for challenge ${challengeId}, userId ${userId}. Scheduled warning may be stale.`);
      return null;
    }
    if (timer.currentStatus != ChallengeTimerStatus.ACTIVE) {
      // Timer is no longer active - scheduled warning is stale, ignore it
      console.log(`Warning: Timer is not active for challenge ${challengeId}, userId ${userId}. Scheduled warning may be stale.`);
      return null;
    }
    if (timer.warningMilestonesSent.includes(milestone)) {
      // Warning already sent (possibly by a restarted timer) - ignore
      console.log(`Warning: Milestone ${milestone} already sent for challenge ${challengeId}, userId ${userId}.`);
      return null;
    }

    if (!timer.endTime) {
      throw new Error('Timer end time is not set');
    }

    const timeRemaining = Math.max(
      0,
      Math.floor((timer.endTime.getTime() - Date.now()) / 1000),
    );

    // Check if timer was recently restarted - if startTime is very recent, old warnings are stale
    const timeSinceStart = Math.floor((Date.now() - timer.startTime.getTime()) / 1000);
    const expectedTimeSinceStart = timer.timerLength - milestone;
    
    if (timeSinceStart < expectedTimeSinceStart - 5) {
      console.log(`Warning: Milestone ${milestone} warning is stale - timer was likely restarted. Time since start: ${timeSinceStart}s, expected: ~${expectedTimeSinceStart}s for challenge ${challengeId}, userId ${userId}.`);
      return null;
    }

    // Ensure time remaining is within 5 seconds of milestone
    const timeDifference = Math.abs(timeRemaining - milestone);
    if (timeDifference > 5) {
      console.log(`Warning: Milestone ${milestone} warning is stale for challenge ${challengeId}, userId ${userId}. Time remaining: ${timeRemaining}, expected: ~${milestone}.`);
      return null;
    }

    // Ensure time remaining is within 3 seconds of milestone
    if (timeRemaining < milestone - 3) {
      console.log(`Warning: Milestone ${milestone} warning is too late for challenge ${challengeId}, userId ${userId}. Time remaining: ${timeRemaining}, milestone: ${milestone}.`);
      return null;
    }

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

  /** Checks if a timer can be extended by seeing if the challenge has enough points remaining
   * Each extension costs 25% of the challenge's base points - deduct from challenge points, 
   * After the user completes the challenge, they get the challenge's base points - extensions used * extension cost
   */
  async canExtendTimer(userId: string, challengeId: string): Promise<boolean> {
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
      console.log('canExtendTimer: Timer not found');
      return false;
    }
    if (timer.currentStatus != ChallengeTimerStatus.ACTIVE && 
        timer.currentStatus != ChallengeTimerStatus.COMPLETED) {
      console.log(`canExtendTimer: Timer status is ${timer.currentStatus}, must be ACTIVE or COMPLETED`);
      return false;
    }
    
    // Use original base points stored in timer (not current challenge.points which may be decremented)
    const extensionCost = this.calculateExtensionCost(timer.originalBasePoints);
    console.log('extensionCost', extensionCost);
    
    // Calculate remaining points: original base points - (extensions used * cost per extension)
    const remainingPoints = timer.originalBasePoints - (timer.extensionsUsed * extensionCost);
    console.log('remainingPoints', remainingPoints);
    
    console.log('canExtendTimer debug:', {
      timerId: timer.id,
      originalBasePoints: timer.originalBasePoints,
      extensionsUsed: timer.extensionsUsed,
      extensionCost,
      remainingPoints,
      challengePoints: challenge.points,
      canExtend: remainingPoints >= extensionCost,
    });
    
    if (remainingPoints < extensionCost) {
      console.log(`canExtendTimer: Insufficient points. Remaining: ${remainingPoints}, Required: ${extensionCost}`);
      return false;
    }
    return true;
  }
}
