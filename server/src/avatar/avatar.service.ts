import { Injectable } from '@nestjs/common';
import { BearSlot as PrismaBearSlot, BearItem, UserBearEquipped } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
    BearItemDto,
    BearSlotDto,
    EquipBearItemDto,
    PurchaseBearItemDto,
    PurchaseResultDto,
    UserBearLoadoutDto,
    UserInventoryDto,
} from './avatar.dto';

@Injectable()
export class AvatarService {
    constructor(private readonly prisma: PrismaService) { }

    /** Map Prisma enum to DTO enum */
    private toDtoSlot(slot: PrismaBearSlot): BearSlotDto {
        return slot as unknown as BearSlotDto;
    }

    /** Map DTO enum to Prisma enum */
    private toPrismaSlot(slot: BearSlotDto): PrismaBearSlot {
        return slot as unknown as PrismaBearSlot;
    }

    private toBearItemDto(item: BearItem): BearItemDto {
        return {
            id: item.id,
            name: item.name,
            slot: this.toDtoSlot(item.slot),
            cost: item.cost,
            assetKey: item.assetKey,
            mimeType: item.mimeType ?? '',
            zIndex: item.zIndex ?? null,
        };
    }

    private async getUserBalance(userId: string): Promise<number> {
        // NOTE: Using User.score as currency until a dedicated "coins" field exists
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
            select: { score: true },
        });
        return user?.score ?? 0;
    }

    async getInventory(userId: string): Promise<UserInventoryDto> {
        const [inv, balance] = await Promise.all([
            this.prisma.userBearInventory.findMany({
                where: { userId },
                include: { bearItem: true },
            }),
            this.getUserBalance(userId),
        ]);

        return {
            userId,
            items: inv.map(v => this.toBearItemDto(v.bearItem)),
            balance,
        };
    }

    async listItems(slot?: BearSlotDto): Promise<BearItemDto[]> {
        const items = await this.prisma.bearItem.findMany({
            where: slot ? { slot: this.toPrismaSlot(slot) } : undefined,
            orderBy: [{ slot: 'asc' }, { zIndex: 'asc' }, { name: 'asc' }],
        });
        return items.map(i => this.toBearItemDto(i));
    }

    async getLoadout(userId: string): Promise<UserBearLoadoutDto> {
        const equipped = await this.prisma.userBearEquipped.findMany({
            where: { userId },
            include: { bearItem: true },
        });
        return {
            userId,
            equipped: equipped.map(e => ({
                slot: this.toDtoSlot(e.slot),
                itemId: e.bearItemId ?? undefined,
                zIndex: e.bearItem?.zIndex ?? null,
            })),
        };
    }

    async purchaseItem(
        userId: string,
        dto: PurchaseBearItemDto,
    ): Promise<PurchaseResultDto> {
        const item = await this.prisma.bearItem.findUnique({
            where: { id: dto.itemId },
        });
        if (!item) {
            return { success: false, newBalance: await this.getUserBalance(userId), itemId: dto.itemId };
        }

        // Already owned?
        const alreadyOwned =
            (await this.prisma.userBearInventory.count({
                where: { userId, bearItemId: item.id },
            })) > 0;
        if (alreadyOwned) {
            return { success: true, newBalance: await this.getUserBalance(userId), itemId: item.id };
        }

        const balance = await this.getUserBalance(userId);
        if (balance < item.cost) {
            return { success: false, newBalance: balance, itemId: item.id };
        }

        // Deduct cost from user's score (temporary currency) and add to inventory
        await this.prisma.$transaction([
            this.prisma.user.update({
                where: { id: userId },
                data: { score: { decrement: item.cost } },
            }),
            this.prisma.userBearInventory.create({
                data: { userId, bearItemId: item.id },
            }),
        ]);

        const newBalance = balance - item.cost;
        return { success: true, newBalance, itemId: item.id };
    }

    async equipItem(userId: string, dto: EquipBearItemDto): Promise<UserBearLoadoutDto> {
        const slot = this.toPrismaSlot(dto.slot);

        if (!dto.itemId) {
            // Unequip slot
            await this.prisma.userBearEquipped.deleteMany({
                where: { userId, slot },
            });
            return this.getLoadout(userId);
        }

        // Validate item exists and is for this slot
        const item = await this.prisma.bearItem.findUnique({
            where: { id: dto.itemId },
            include: { inventories: { where: { userId }, select: { id: true } } },
        });
        if (!item || item.slot !== slot) {
            return this.getLoadout(userId);
        }

        // Ensure user owns the item or it's a default item
        const ownsItem = (item.inventories?.length ?? 0) > 0 || item.isDefault;
        if (!ownsItem) {
            return this.getLoadout(userId);
        }

        // Upsert equip for the slot
        await this.prisma.userBearEquipped.upsert({
            where: {
                userId_slot: { userId, slot },
            },
            create: {
                userId,
                slot,
                bearItemId: item.id,
            },
            update: {
                bearItemId: item.id,
            },
        });

        return this.getLoadout(userId);
    }
}


