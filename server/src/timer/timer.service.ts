/*- Timer Lifecycle
    - `startTimer(challengeId, userId)` - Initialize timer, calculate end time
    - `extendTimer(challengeId, userId)` - Add time for points, update end time
    - `completeTimer(challengeId, userId)` - Handle challenge completion
- Warning System
    - `scheduleWarnings(timerId)` - Set up milestone alerts
    - `sendWarning(timerId, milestone)` - Broadcast warning to participants
- Time Calculations
    - `calcualteEndTime(challenge, extensionsUsed)` - Business logic for timer duration
    - `canExtendTimer(userId, challengeId)` - Validation for extensions
*/

import { CaslAbilityFactory } from "../casl/casl-ability.factory";
import { ClientService } from "../client/client.service";
import { PrismaService } from "../prisma/prisma.service";
import { ChallengeTimer, ChallengeTimerStatus, Challenge } from "@prisma/client";
import { TimerStartedDto, TimerExtendedDto, TimerCompletedDto, TimerWarningDto } from "./timer.dto";
import { ChallengeService } from "../challenge/challenge.service";
import { UserService } from "../user/user.service";

export class TimerService {
    constructor(
        private clientService: ClientService,
        private prisma: PrismaService,
        private abilityFactory: CaslAbilityFactory,
        private challengeService: ChallengeService,
        private userService: UserService,
    ) {}

    /** Start a timer for a challenge */
    async startTimer(challengeId: string, userId: string) : Promise<TimerStartedDto> {
        const challenge = await this.prisma.challenge.findUniqueOrThrow({
            where: { id: challengeId }
        });
        if (!challenge.timerLength) {
            throw new Error('This challenge has no timer (timer length is not set)');
        }
        const endTime = this.calculateEndTime(challenge, 0);
        const timer = await this.prisma.challengeTimer.create({
            data: {
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
        
        //Schedule warnings for the timer
        await this.scheduleWarnings(challengeId, endTime);

        //Schedule autocompletion of challenge after timer expries
        const completion_delay = endTime.getTime() - Date.now(); 
        setTimeout(async () => { //send warning if delay is > 0 
            await this.completeTimer(challengeId);
        }, completion_delay);
    
        
        return {
            endTime: endTime.toISOString(), 
            challengeId: challengeId,
        };
    }

    async completeTimer(challengeId: string) : Promise<TimerCompletedDto> {
        //end timer 
        const timer = await this.prisma.challengeTimer.findUniqueOrThrow({
            where: { id: challengeId },
            include: {user: true}
        });

        if (!timer) {
            throw new Error('Timer not found');
        }

        // Mark timer as completed
        await this.prisma.challengeTimer.update({
            where: {id: timer.id},
            data: {endTime: new Date(), 
                currentStatus: ChallengeTimerStatus.COMPLETED}
        });

        // Complete the challenge
        await this.challengeService.completeChallenge(timer.user);

        return {
            challengeId: challengeId,
            challengeCompleted: true,
        };

    }

    async extendTimer(challengeId: string, userId: string): Promise<TimerExtendedDto> {
        const timer = await this.prisma.challengeTimer.findFirst({
            where: {challengeId: challengeId},
            include: {challenge: true}
        });
        if (!timer) {
            throw new Error('Timer not found');
        }
        const canExtend = await this.canExtendTimer(userId, challengeId);
        if (!canExtend) {
            throw new Error('Cannot extend timer');
        }
        
        const newEndTime = this.calculateEndTime(timer.challenge, 1);
        const extensionCost = this.calculateExtensionCost(timer.challenge.points);
        const user = await this.userService.byId(userId);
        if (!user) {
            throw new Error('User not found');
        }
        await this.prisma.user.update({
            where: {id: user.id},
            data: {score: {decrement: extensionCost}}
        });


        await this.prisma.challengeTimer.update({
            where: {id: timer.id},
            data: {endTime: newEndTime}
        });
        
        return {
            challengeId: challengeId,
            newEndTime: newEndTime.toISOString(),
        };
    }
    
    /** Calculate the points deducted for using an extension 
    */
    private calculateExtensionCost(basePoints: number): number {
        return Math.floor(basePoints * 0.25);
    }

    async scheduleWarnings(challengeId: string, endTime: Date) : Promise<void> {
        const timer = await this.prisma.challengeTimer.findFirst({
            where: {challengeId: challengeId}
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
                setTimeout(async () => { // send warning if delay is > 0 
                    await this.sendWarning(challengeId, milestone);
                }, delay);
            }
        }
    }

    async sendWarning(challengeId: string, milestone: number) : Promise<void> {
        const timer = await this.prisma.challengeTimer.findFirst({
            where: {challengeId: challengeId}
        });
        if (!timer) {
            throw new Error('Timer not found');
        }
        if (timer.currentStatus != ChallengeTimerStatus.ACTIVE) {
            return;
        }
        if (timer.warningMilestonesSent.includes(milestone)) {
            return;
        }

        if (!timer.endTime) {
            throw new Error('Timer end time is not set');
        }

        const timeRemaining = Math.max(0, Math.floor((timer.endTime.getTime() - Date.now()) / 1000));
        
        const warningDto: TimerWarningDto = {
            challengeId: challengeId,
            milestone: milestone,
            timeRemaining: timeRemaining,
        };

        await this.clientService.sendEvent(
            [`user/${timer.userId}`],
            'timerWarning',
            warningDto
        );

        await this.prisma.challengeTimer.update({
            where: {id: timer.id},
            data: {warningMilestonesSent: {push: milestone},
                lastWarningSent: new Date()}
        });
    }

    /** Calculates end time of a challenge based on number of extensions used
     * Formula: Current time + timer length + 5 minutes for each extension used
     */
    private calculateEndTime(challenge: Challenge, extensionsUsed: number): Date {
        if (!challenge.timerLength) {
            throw new Error('Challenge timer length is not set');
        }
        return new Date(Date.now() + challenge.timerLength * 1000 + extensionsUsed * 5 * 60 * 1000);
    }

    async canExtendTimer(userId: string, challengeId: string): Promise<boolean> {
        const user = await this.userService.byId(userId);
        if (!user) {
            return false;
        }
        
        const timer = await this.prisma.challengeTimer.findFirst({
            where: {challengeId: challengeId},
            include: {challenge: true}
        });
        
        if (!timer) {
            return false;
        }
        if (timer.currentStatus != ChallengeTimerStatus.ACTIVE) {
            return false;
        }
        if (user.score < this.calculateExtensionCost(timer.challenge.points)) {
            return false;
        }
        return true;
    }
}