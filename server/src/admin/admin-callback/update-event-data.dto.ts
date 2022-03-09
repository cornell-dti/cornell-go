import { EventDto } from '../update-events.dto';

export interface UpdateEventDataDto {
  events: EventDto[];
  deletedIds: string[];
}
