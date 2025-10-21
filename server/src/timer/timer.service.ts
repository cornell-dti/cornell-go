/*- Timer Lifecycle
    - `startTimer(challengeId, userId)` - Initialize timer, calculate end time
    - `extendTimer(challengeId, userId)` - Add time for points, update end time
    - `completeTimer(challengeId, userId)` - Handle challenge completion
- Warning System
    - `scheduleWarnings(challengeId, endTime)` - Set up milestone alerts
    - `sendWarning(challengeId, warningType)` -  - Broadcast warning to participants
- Time Calculations
    - `calcualteEndTime(challenge, extensionsUsed)` - Business logic for timer duration
    - `canExtendTimer(userId, challengeId)` - Validation for extensions
*/

import { CaslAbilityFactory } from "../casl/casl-ability.factory";
import { ClientService } from "../client/client.service";
import { PrismaService } from "../prisma/prisma.service";
import { ChallengeTimerStatus } from "@prisma/client";
import { TimerStartedDto, TimerExtendedDto, TimerCompletedDto } from "./timer.dto";

export class TimerService {
    constructor(
        private clientService: ClientService,
        private prisma: PrismaService,
        private abilityFactory: CaslAbilityFactory,
    ) {}

    /** Start a timer for a challenge */
    async startTimer(challengeId: string, userId: string) : Promise<TimerStartedDto> {
        const challenge = await this.prisma.challenge.findUniqueOrThrow({
            where: { id: challengeId }
        });
        if (!challenge.timerLength) {
            throw new Error('This challenge has no timer (timer length is not set)');
        }
        const endTime = new Date(Date.now() + challenge.timerLength * 1000);
        const timer = await this.prisma.challengeTimer.create({
            data: {
                challengeId: challengeId, 
                userId: userId, 
                timerLength: challenge.timerLength,
                startTime: new Date(),
                endTime: endTime,
                currentStatus: ChallengeTimerStatus.ACTIVE,
                warningMilestones: [300, 60, 30],
                warningMilestoneSent: [],
                lastWarningSent: null,
            },
        });
        return {
            endTime: endTime.toISOString(),
            challengeId: challengeId,};
    }

    async completeTimer(challengeId: string, userId: string) : Promise<TimerCompletedDto> {
        //end timer 
        const timer = await this.prisma.challengeTimer.findUniqueOrThrow({
            where: { id: challengeId }
        });
        await this.prisma.challengeTimer.update({
            where: {id: timer.id},
            data: {endTime: new Date(), 
                currentStatus: ChallengeTimerStatus.COMPLETED}
        });

        //complete the challenege
        const challenge = await this.prisma.challenge.getChallengeById(challengeId);
        const user = await.this.prisma.user.getUserById(userId);
        await this.challengeService.completeChallenge(user); 


        return {
            challengeId: challengeId,
            challengeCompleted: true,
        };

    }

    async extendTimer(challengeId: string, userId: string, pointsUsed: number) : Promise<TimerExtendedDto> {
        const challenge = await this.prisma.challenge.getChallengeById(challengeId);
        const newEndTime = new Date(Date.now() + 5 * 60); // add 5 minutes to timer 
        const timer = await this.prisma.challengeTimer.update({
            where: {id: challengeId},
            data: {endTime: newEndTime,
                pointsExtending: pointsUsed}
        });
        return {
            challengeId: challengeId,
            newEndTime: newEndTime.toISOString(),
        };

    }
}

