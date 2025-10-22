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
import { ChallengeTimer } from "@prisma/client";
import { TimerStartedDto, TimerExtendedDto, TimerCompletedDto, TimerWarningDto } from "./timer.dto";
import { ChallengeGateway } from "../challenge/challenge.gateway";

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
        const newEndTime = this.calculateEndTime(challenge, pointsUsed);
        const extensionCost = this.calculateExtensionCost(challenge.points);
        const user = await this.prisma.user.getUserById(userId);
        await this.prisma.user.update({
            where: {id: user.id},
            data: {score: {decrement: extensionCost}}
        });

        const timer = await this.prisma.challengeTimer.findFirst({
            where: {challengeId: challengeId}
        });
        if (!timer) {
            throw new Error('Timer not found');
        }
        const currentEndTime = timer.endTime;

        if (!this.canExtendTimer(userId, challengeId)) { 
            //cannot extend timer; TODO: if same endtime as before show error of not being able to extend in frontend
            return {
                challengeId: challengeId,
                newEndTime: currentEndTime.toISOString(),
            }
        }
        else {
            await this.prisma.challengeTimer.update({
                where: {id: challengeId},
                data: {endTime: newEndTime}
            });
            
            return {
                challengeId: challengeId,
                newEndTime: newEndTime.toISOString(),
            };
        }
        

    }
    
    /** Calculate the points deducted for using an extension 
     * //TODO: is it possible for a user to not have enough points? 
    */
    private calculateExtensionCost(basePoints: number): number {
        return Math.floor(basePoints * 0.25);
    }

    async scheduleWarnings(challengeId: string, endTime: Date) : Promise<void> {
        const timer = await this.prisma.challengeTimer.findFirst(){
            where: {challengeId: challengeId}
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
        if (timer.warningMilestoneSent.includes(milestone)) {
            return;
        }
        const timeRemaining = timer.endTime.getTime() - new Date().getTime();
        const warningDto: TimerWarningDto = {
            challengeId: challengeId,
            milestone: milestone,
            timeRemaining: timeRemaining,
        };

        await this.prisma.challengeTimer.update({
            where: {id: timer.id},
            data: {warningMilestoneSent: {push: milestone},
                lastWarningSent: new Date()}
        });
    }

    /** Calculates end time of a challenge based on number of extensions used
     * Formula: Current time + timer length + 5 minutes for each extension used
     */
    private calculateEndTime(challenge: Challenge, extensionsUsed: number): Date {
        return new Date(Date.now() + challenge.timerLength * 1000 + extensionsUsed * 5 * 60 * 1000);
    }

    private canExtendTimer(userId: string, challengeId: string): boolean {
        const user = await this.prisma.user.getUserById(userId);
        const challenge = await this.prisma.challenge.getChallengeById(challengeId);
        const timer = await this.prisma.challengeTimer.findFirst({
            where: {challengeId: challengeId}
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