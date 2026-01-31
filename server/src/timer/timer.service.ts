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

/** Extension duration in milliseconds (5 minutes). Must stay in sync with EXTENSION_TIME_SECONDS in gameplay_map.dart. */
const EXTENSION_LENGTH_MS = 5 * 60 * 1000; // 5 minutes in milliseconds
const EXTENSION_COST = 0.25; // 25% of the challenge points

/** Grace period before actually failing a challenge (allows extension requests to arrive) */
const GRACE_PERIOD_MS = 10 * 1000; // 10 seconds

@Injectable()
export class TimerService {
  /**
   * Map to store active setTimeout IDs for cancellation.
   * Key: `${userId}_${challengeId}`, Value: NodeJS.Timeout
   * This allows us to cancel old timeouts when extending or completing timers.
   */
  private activeTimeouts: Map<string, NodeJS.Timeout> = new Map();

  constructor(
    private readonly prisma: PrismaService,
    private clientService: ClientService,
    @Inject(forwardRef(() => ChallengeService))
    private challengeService: ChallengeService,
  ) {}

  /** Helper to generate a unique key for timeout storage */
  private getTimeoutKey(userId: string, challengeId: string): string {
    return `${userId}_${challengeId}`;
  }

  /** Clear any existing timeout for a user/challenge combination */
  private clearExistingTimeout(userId: string, challengeId: string): void {
    const key = this.getTimeoutKey(userId, challengeId);
    const existingTimeout = this.activeTimeouts.get(key);
    if (existingTimeout) {
      clearTimeout(existingTimeout);
      this.activeTimeouts.delete(key);
    }
  }

  /** Store a timeout reference for later cancellation */
  private storeTimeout(
    userId: string,
    challengeId: string,
    timeout: NodeJS.Timeout,
  ): void {
    const key = this.getTimeoutKey(userId, challengeId);
    this.activeTimeouts.set(key, timeout);
  }

  /** Start a timer for a challenge
   * If an active timer already exists, returns the existing timer without resetting it.
   * This ensures the timer persists across app close/reopen.
   */
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

    // Check if an active timer already exists
    const existingTimer = await this.prisma.challengeTimer.findFirst({
      where: {
        userId: userId,
        challengeId: challengeId,
      },
    });

    // If an ACTIVE timer exists, return it without resetting
    if (
      existingTimer &&
      existingTimer.currentStatus === ChallengeTimerStatus.ACTIVE
    ) {
      const timeRemaining = existingTimer.endTime
        ? existingTimer.endTime.getTime() - Date.now()
        : 0;

      // Re-schedule warnings and auto-completion for existing timer (in case server restarted)
      if (!process.env.TESTING_E2E && existingTimer.endTime) {
        if (timeRemaining > 0) {
          await this.scheduleWarnings(
            challengeId,
            userId,
            existingTimer.endTime,
          );
          // Clear any existing timeout before scheduling new one
          this.clearExistingTimeout(userId, challengeId);
          const timeout = setTimeout(async () => {
            await this.completeTimer(challengeId, userId, false);
          }, timeRemaining);
          this.storeTimeout(userId, challengeId, timeout);
        }
      }

      return {
        timerId: existingTimer.id,
        endTime:
          existingTimer.endTime?.toISOString() ?? new Date().toISOString(),
        challengeId: challengeId,
        extensionsUsed: existingTimer.extensionsUsed,
      };
    }

    // If timer is in GRACE_PERIOD, handle reconnection during grace period
    if (
      existingTimer &&
      existingTimer.currentStatus === ChallengeTimerStatus.GRACE_PERIOD
    ) {
      // Calculate how much time has passed since timer expired (endTime)
      const timeSinceExpiration = existingTimer.endTime
        ? Date.now() - existingTimer.endTime.getTime()
        : GRACE_PERIOD_MS + 1; // Force failure if no endTime

      if (timeSinceExpiration >= GRACE_PERIOD_MS) {
        // Grace period has expired - fail the challenge now
        await this.completeTimer(challengeId, userId, false);
        // Return with status indicating failure (will go to upsert to reset)
      } else {
        // Grace period still active - re-schedule the failure timeout
        const remainingGracePeriod = GRACE_PERIOD_MS - timeSinceExpiration;

        if (!process.env.TESTING_E2E) {
          this.clearExistingTimeout(userId, challengeId);
          const timeout = setTimeout(async () => {
            await this.completeTimer(challengeId, userId, false);
          }, remainingGracePeriod);
          this.storeTimeout(userId, challengeId, timeout);
        }

        // Return the timer info - user can still extend during grace period
        return {
          timerId: existingTimer.id,
          endTime:
            existingTimer.endTime?.toISOString() ?? new Date().toISOString(),
          challengeId: challengeId,
          extensionsUsed: existingTimer.extensionsUsed,
        };
      }
    }

    const endTime = this.calculateEndTime(challenge, 0);

    // Use originalBasePoints from existing timer if available (for EXPIRED/COMPLETED timers being restarted)
    const originalBasePoints =
      existingTimer?.originalBasePoints || challenge.points;
    // Preserve extensionsUsed from existing timer (don't reset on timer restart)
    const preservedExtensionsUsed = existingTimer?.extensionsUsed || 0;

    // Uses upsert to handle existing timers (e.g., if user reopens challenge after timer expired)
    const timer = await this.prisma.challengeTimer.upsert({
      where: {
        userId_challengeId: {
          userId: userId,
          challengeId: challengeId,
        },
      },
      update: {
        // Reset timer if it already exists (but was not ACTIVE), preserve extensionsUsed
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

    // Restore challenge points to original value when restarting timer
    if (challenge.points !== originalBasePoints) {
      await this.prisma.challenge.update({
        where: { id: challengeId },
        data: {
          points: originalBasePoints,
        },
      });

      // Emit challenge update to frontend so ChallengeModel gets updated points
      const updatedChallenge = await this.prisma.challenge.findUniqueOrThrow({
        where: { id: challengeId },
      });
      if (updatedChallenge) {
        await this.challengeService.emitUpdateChallengeData(
          updatedChallenge,
          false,
        );
      }
    }

    // Schedule warnings and auto-completion if not in e2e testing
    if (!process.env.TESTING_E2E) {
      await this.scheduleWarnings(challengeId, userId, endTime);
      const completion_delay = endTime.getTime() - Date.now();
      // Clear any existing timeout before scheduling new one
      this.clearExistingTimeout(userId, challengeId);
      const timeout = setTimeout(async () => {
        await this.completeTimer(challengeId, userId, false); // challenge failed so challengeCompleted = false
      }, completion_delay);
      this.storeTimeout(userId, challengeId, timeout);
    }

    return {
      timerId: timer.id,
      endTime: endTime.toISOString(),
      challengeId: challengeId,
      extensionsUsed: timer.extensionsUsed,
    };
  }

  /** Completes a timer for a challenge
   * If challengeCompleted is true, the challenge was successfully completed
   * If challengeCompleted is false, the timer expired - enters GRACE_PERIOD before actually failing
   *
   * The grace period approach prevents race conditions where an extension request arrives
   * slightly after the timer expires. Instead of immediately failing, we:
   * 1. Set timer to GRACE_PERIOD and show "Time's Up" modal
   * 2. Wait 10 seconds for potential extension requests
   * 3. Only then actually fail the challenge
   */
  async completeTimer(
    challengeId: string,
    userId: string,
    challengeCompleted: boolean,
  ): Promise<TimerCompletedDto> {
    const timer = await this.prisma.challengeTimer.findFirst({
      where: { challengeId: challengeId, userId: userId },
      include: { user: true },
    });

    if (!timer) {
      this.clearExistingTimeout(userId, challengeId);
      return {
        timerId: '',
        challengeId: challengeId,
        challengeCompleted: false,
      };
    }

    // If timer is already completed or expired, don't process again
    if (
      timer.currentStatus === ChallengeTimerStatus.COMPLETED ||
      timer.currentStatus === ChallengeTimerStatus.EXPIRED
    ) {
      this.clearExistingTimeout(userId, challengeId);
      return {
        timerId: timer.id,
        challengeId: challengeId,
        challengeCompleted:
          timer.currentStatus === ChallengeTimerStatus.COMPLETED,
      };
    }

    // Handle successful completion
    if (challengeCompleted) {
      this.clearExistingTimeout(userId, challengeId);
      await this.prisma.challengeTimer.update({
        where: { id: timer.id },
        data: {
          endTime: new Date(),
          currentStatus: ChallengeTimerStatus.COMPLETED,
        },
      });
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

    // Timer expiration flow - check for stale timeouts first
    if (timer.endTime) {
      const timeRemaining = timer.endTime.getTime() - Date.now();
      if (timeRemaining > 1000) {
        return {
          timerId: timer.id,
          challengeId: challengeId,
          challengeCompleted: false,
        };
      }
    }

    // Timer is ACTIVE - enter GRACE_PERIOD (don't fail yet, wait for potential extension)
    if (timer.currentStatus === ChallengeTimerStatus.ACTIVE) {
      // Set timer to GRACE_PERIOD
      await this.prisma.challengeTimer.update({
        where: { id: timer.id },
        data: {
          currentStatus: ChallengeTimerStatus.GRACE_PERIOD,
        },
      });

      // Send timerExpired event to frontend to show "Time's Up" modal
      // Note: Challenge is NOT failed yet - user can still extend
      const timerCompletedDto: TimerCompletedDto = {
        timerId: timer.id,
        challengeId: challengeId,
        challengeCompleted: false,
      };
      await this.clientService.sendEvent(
        [`user/${userId}`],
        'timerCompleted',
        timerCompletedDto,
      );

      // Schedule the actual failure after grace period
      if (!process.env.TESTING_E2E) {
        this.clearExistingTimeout(userId, challengeId);
        const gracePeriodTimeout = setTimeout(async () => {
          await this.completeTimer(challengeId, userId, false);
        }, GRACE_PERIOD_MS);
        this.storeTimeout(userId, challengeId, gracePeriodTimeout);
      }

      return {
        timerId: timer.id,
        challengeId: challengeId,
        challengeCompleted: false,
      };
    }

    // Timer is in GRACE_PERIOD and grace period has expired - actually fail the challenge now
    if (timer.currentStatus === ChallengeTimerStatus.GRACE_PERIOD) {
      this.clearExistingTimeout(userId, challengeId);

      // Update timer to EXPIRED
      await this.prisma.challengeTimer.update({
        where: { id: timer.id },
        data: {
          endTime: new Date(),
          currentStatus: ChallengeTimerStatus.EXPIRED,
        },
      });

      // NOW actually fail the challenge
      await this.challengeService.failChallenge(timer.user, challengeId);

      // Send challengeFailed event
      await this.clientService.sendEvent(
        [`user/${userId}`],
        'challengeFailed',
        { challengeId, userId },
      );

      return {
        timerId: timer.id,
        challengeId: challengeId,
        challengeCompleted: false,
      };
    }

    // Shouldn't reach here, but handle gracefully
    return {
      timerId: timer.id,
      challengeId: challengeId,
      challengeCompleted: false,
    };
  }

  /** Extends a timer for a challenge
   * - updates the end time of the timer
   * - deducts the extension cost from the challenge's points (25%)
   * - if the timer cannot be extended (the challenge's points are not enough), an error is thrown
   * - handles GRACE_PERIOD status by cancelling the pending failure and continuing the timer
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

    // If timer is in GRACE_PERIOD, extension arrived in time - cancel the pending failure
    if (timer.currentStatus === ChallengeTimerStatus.GRACE_PERIOD) {
      // Clear the grace period timeout that would have failed the challenge
      this.clearExistingTimeout(userId, challengeId);
    }

    // If timer is already EXPIRED, the challenge was already failed - can't extend
    if (timer.currentStatus === ChallengeTimerStatus.EXPIRED) {
      throw new Error('Timer has expired - challenge already failed');
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

    // Calculate extension cost from challenge's original base points: 25% of original base points
    const extensionCost = this.calculateExtensionCost(timer.originalBasePoints);

    const newExtensionsUsed = timer.extensionsUsed + 1;
    // Add 5 minutes: from current time if in GRACE_PERIOD, otherwise from current endTime
    // This ensures user gets full 5 minutes when extending during grace period
    const baseTime =
      timer.currentStatus === ChallengeTimerStatus.GRACE_PERIOD
        ? new Date()
        : timer.endTime || new Date();
    const newEndTime = new Date(baseTime.getTime() + EXTENSION_LENGTH_MS);

    // Update timer with new end time, increment extensions used, set status back to ACTIVE, and reset warnings
    await this.prisma.challengeTimer.update({
      where: { id: timer.id },
      data: {
        endTime: newEndTime,
        extensionsUsed: newExtensionsUsed,
        currentStatus: ChallengeTimerStatus.ACTIVE,
        warningMilestonesSent: [],
      },
    });

    // Reschedule warnings and auto-completion for the extended timer
    if (!process.env.TESTING_E2E) {
      await this.scheduleWarnings(challengeId, userId, newEndTime);
      // Clear existing timeout BEFORE scheduling new one - this is critical!
      // Without this, the old timeout would still fire at the original end time
      this.clearExistingTimeout(userId, challengeId);
      const completion_delay = newEndTime.getTime() - Date.now();
      if (completion_delay > 0) {
        const timeout = setTimeout(async () => {
          await this.completeTimer(challengeId, userId, false);
        }, completion_delay);
        this.storeTimeout(userId, challengeId, timeout);
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
    const EARLY_BUFFER_MS = 2000; // 2 seconds early to compensate for delays

    // Calculate actual time remaining (in seconds) from endTime, accounting for extensions
    const now = new Date();
    const actualTimeRemaining = Math.max(
      0,
      Math.floor((endTime.getTime() - now.getTime()) / 1000),
    );

    for (const milestone of milestones) {
      // Don't schedule warnings if the actual time remaining is shorter than the milestone
      if (milestone > actualTimeRemaining) {
        continue;
      }

      const warningTime = new Date(
        endTime.getTime() - milestone * 1000 - EARLY_BUFFER_MS,
      );

      if (warningTime > now) {
        const delay = warningTime.getTime() - now.getTime(); // How long until warning should be sent
        setTimeout(async () => {
          // Send warning if delay is > 0
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
      return null;
    }
    if (timer.currentStatus !== ChallengeTimerStatus.ACTIVE) {
      // Timer is no longer active - scheduled warning is stale, ignore it
      return null;
    }
    if (timer.warningMilestonesSent.includes(milestone)) {
      // Warning already sent (possibly by a restarted timer) - ignore
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
    const timeSinceStart = Math.floor(
      (Date.now() - timer.startTime.getTime()) / 1000,
    );
    const expectedTimeSinceStart = timer.timerLength - milestone;

    if (timeSinceStart < expectedTimeSinceStart - 5) {
      return null;
    }

    // Ensure time remaining is within 5 seconds of milestone
    const timeDifference = Math.abs(timeRemaining - milestone);
    if (timeDifference > 5) {
      return null;
    }

    // Ensure time remaining is within 3 seconds of milestone
    if (timeRemaining < milestone - 3) {
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
        extensionsUsed * EXTENSION_LENGTH_MS,
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
      return false;
    }
    if (
      timer.currentStatus !== ChallengeTimerStatus.ACTIVE &&
      timer.currentStatus !== ChallengeTimerStatus.GRACE_PERIOD &&
      timer.currentStatus !== ChallengeTimerStatus.COMPLETED &&
      timer.currentStatus !== ChallengeTimerStatus.EXPIRED
    ) {
      return false;
    }

    // Use original base points stored in timer (not current challenge.points which may be decremented)
    const extensionCost = this.calculateExtensionCost(timer.originalBasePoints);

    // Calculate remaining points: original base points - (extensions used * cost per extension)
    const remainingPoints =
      timer.originalBasePoints - timer.extensionsUsed * extensionCost;

    if (remainingPoints < extensionCost) {
      return false;
    }
    return true;
  }
}
