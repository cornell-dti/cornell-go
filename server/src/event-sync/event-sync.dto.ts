/** DTO for triggering a manual event sync */
export interface TriggerEventSyncDto {
  days?: number;
}

/** DTO for event sync result stats */
export interface EventSyncResultDto {
  created: number;
  updated: number;
  archived: number;
  totalFetched: number;
  syncedAt: string;
}

/** DTO for requesting event sync status */
export interface RequestEventSyncStatusDto {}

/** DTO emitted to clients with sync status */
export interface UpdateEventSyncStatusDto {
  running: boolean;
  lastResult: EventSyncResultDto | null;
}
