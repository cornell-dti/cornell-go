export enum BearSlotDto {
    EYES = 'EYES',
    MOUTH = 'MOUTH',
    COLOR = 'COLOR',
    ACCESSORY = 'ACCESSORY',
}

export interface BearItemDto {
    id: string;
    name: string;
    slot: BearSlotDto;
    cost: number;
    assetKey: string;
    mimeType: string;
    zIndex?: number | null;
}

export interface PurchaseBearItemDto {
    itemId: string;
}

export interface EquipBearItemDto {
    slot: BearSlotDto;
    itemId?: string;
}

export interface PurchaseResultDto {
    success: boolean;
    newBalance: number;
    itemId: string;
}

export interface UserBearLoadoutDto {
    userId: string;
    equipped: Array<{
        slot: BearSlotDto;
        itemId?: string;
        zIndex?: number | null;
    }>;
}

export interface UserInventoryDto {
    userId: string;
    items: BearItemDto[];
    balance: number;
}

/** Requests */
export interface RequestBearItemsDto {
    slot?: BearSlotDto;
}

// Empty DTOS for documentation and frontend api generation
export interface RequestUserInventoryDto { }

export interface RequestUserBearLoadoutDto { }

export interface UpdateBearItemsDataDto {
    items: BearItemDto[];
}

export interface UpdateUserInventoryDataDto extends UserInventoryDto { }

export interface UpdateUserBearLoadoutDataDto extends UserBearLoadoutDto { }

export interface UpdatePurchaseResultDto extends PurchaseResultDto { }


