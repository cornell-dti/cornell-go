
import { Injectable, CanActivate, ExecutionContext, InternalServerErrorException, ForbiddenException } from '@nestjs/common';

@Injectable()
export class ClubSubmissionApiGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    
    const request = context.switchToHttp().getRequest();
    const headerKey = request.headers['x-api-key'] as string | undefined;
    const expected = process.env.CLUB_SUBMISSION_API_KEY;

    if (!expected) {
      throw new InternalServerErrorException('CLUB_SUBMISSION_API_KEY not configured');
    }
    if (!headerKey) {
      throw new ForbiddenException('Missing API key');
    }
    if (headerKey != expected) {
      throw new ForbiddenException('Invalid API key');
    }

    return true; 
  }
}
