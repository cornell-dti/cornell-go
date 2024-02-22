import { Module } from '@nestjs/common';
import { ClaimService } from './claim.service';

@Module({
  providers: [ClaimService],
})
export class ClaimModule {}
