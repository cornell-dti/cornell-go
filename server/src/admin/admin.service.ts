import { InjectRepository } from '@mikro-orm/nestjs';
import { EntityRepository } from '@mikro-orm/postgresql';
import { Injectable } from '@nestjs/common';
import { Challenge } from 'src/model/challenge.entity';
import { EventBase } from 'src/model/event-base.entity';
import { EventReward } from 'src/model/event-reward.entity';
import { User } from 'src/model/user.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User) private userRepository: EntityRepository<User>,
    @InjectRepository(EventReward)
    private rewardRepository: EntityRepository<EventReward>,
    @InjectRepository(EventBase)
    private eventRepository: EntityRepository<EventBase>,
    @InjectRepository(Challenge)
    private challengeRepository: EntityRepository<Challenge>,
  ) {}

  async setAdminStatus(adminId: string, granted: boolean) {
    const admin = await this.userRepository.findOne({ id: adminId });
    if (admin) {
      admin.adminGranted = granted;
      admin.adminRequested = false;
      await this.userRepository.persistAndFlush(admin);
    }
    return admin;
  }

  async getAllRequestingAdmins() {
    return await this.userRepository.find({
      adminRequested: true,
    });
  }
}
