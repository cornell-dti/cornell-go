import { Injectable } from '@nestjs/common';
import { BearItem } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ClientService } from '../client/client.service';
import {
  AdminBearItemDto,
  BearItemDto,
  BearSlotDto,
  EquipBearItemDto,
  PurchaseBearItemDto,
  PurchaseResultDto,
  UpdateBearItemDataDto,
  UserBearLoadoutDto,
  UserInventoryDto,
} from './avatar.dto';

type PrismaBearSlot = BearItem['slot'];

@Injectable()
export class AvatarService {
  private static readonly SPIN_COOLDOWN_HOURS = 24;
  private static readonly WHEEL_ITEM_COUNT = 8;

  constructor(
    private readonly prisma: PrismaService,
    private readonly clientService: ClientService,
  ) { }

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
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    return user?.coins ?? 0;
  }

  private toSpinAvailabilityDto(
    canSpin: boolean,
    remainingCooldownSeconds: number,
  ): { canSpin: boolean; remainingCooldownSeconds: number } {
    return {
      canSpin,
      remainingCooldownSeconds: Math.max(0, Math.floor(remainingCooldownSeconds)),
    };
  }

  private shuffle<T>(items: T[]): T[] {
    const cloned = [...items];
    for (let i = cloned.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [cloned[i], cloned[j]] = [cloned[j], cloned[i]];
    }
    return cloned;
  }

  private getCooldownSeconds(): number {
    return AvatarService.SPIN_COOLDOWN_HOURS * 60 * 60;
  }

  async requestSpinAvailability(userId: string): Promise<{
    canSpin: boolean;
    remainingCooldownSeconds: number;
  }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user?.lastSpinAt) {
      return this.toSpinAvailabilityDto(true, 0);
    }

    const nowMs = Date.now();
    const lastSpinMs = user.lastSpinAt.getTime();
    const elapsedSeconds = Math.floor((nowMs - lastSpinMs) / 1000);
    const remainingCooldownSeconds = this.getCooldownSeconds() - elapsedSeconds;
    if (remainingCooldownSeconds <= 0) {
      return this.toSpinAvailabilityDto(true, 0);
    }

    return this.toSpinAvailabilityDto(false, remainingCooldownSeconds);
  }

  async requestSpinWheelItems(): Promise<BearItemDto[]> {
    let items = await this.prisma.bearItem.findMany({
      where: { isDefault: false },
      orderBy: [{ slot: 'asc' }, { zIndex: 'asc' }, { name: 'asc' }],
    });
    // Fallback for environments where only default items are seeded.
    if (items.length === 0) {
      items = await this.prisma.bearItem.findMany({
        orderBy: [{ slot: 'asc' }, { zIndex: 'asc' }, { name: 'asc' }],
      });
    }
    if (items.length === 0) {
      return [];
    }

    const shuffled = this.shuffle(items);
    const selected: BearItem[] = [];
    for (let i = 0; i < AvatarService.WHEEL_ITEM_COUNT; i++) {
      selected.push(shuffled[i % shuffled.length]);
    }

    return selected.map(item => this.toBearItemDto(item));
  }

  async spinWheel(userId: string): Promise<{
    wonItem: BearItemDto;
    cooldownSeconds: number;
  } | null> {
    const availability = await this.requestSpinAvailability(userId);
    if (!availability.canSpin) {
      return null;
    }

    const result = await this.prisma.$transaction(async tx => {
      const availableItems = await tx.bearItem.findMany({
        where: {
          isDefault: false,
          inventories: {
            none: { userId },
          },
        },
      });

      if (availableItems.length === 0) {
        return null;
      }

      const wonItem =
        availableItems[Math.floor(Math.random() * availableItems.length)];

      await tx.userBearInventory.create({
        data: {
          userId,
          bearItemId: wonItem.id,
        },
      });

      await tx.user.update({
        where: { id: userId },
        data: { lastSpinAt: new Date() },
      });

      return wonItem;
    });

    if (!result) {
      return null;
    }

    return {
      wonItem: this.toBearItemDto(result),
      cooldownSeconds: this.getCooldownSeconds(),
    };
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
        zIndex: e.bearItem?.zIndex ?? undefined,
      })),
    };
  }

  async purchaseItem(
    userId: string,
    dto: PurchaseBearItemDto,
  ): Promise<PurchaseResultDto> {
    return await this.prisma.$transaction(async tx => {
      const item = await tx.bearItem.findUnique({
        where: { id: dto.itemId },
      });

      // Lock the user row to prevent concurrent purchases from racing
      const [user] = await tx.$queryRaw<{ coins: number }[]>`
                SELECT coins FROM "User" WHERE id = ${userId} FOR UPDATE
            `;
      const balance = user?.coins ?? 0;

      if (!item) {
        return { success: false, newBalance: balance, itemId: dto.itemId };
      }

      // Already owned?
      const alreadyOwned =
        (await tx.userBearInventory.count({
          where: { userId, bearItemId: item.id },
        })) > 0;

      if (alreadyOwned) {
        return { success: true, newBalance: balance, itemId: item.id };
      }

      if (balance < item.cost) {
        return { success: false, newBalance: balance, itemId: item.id };
      }

      // Deduct cost from user's coins and add to inventory
      await tx.user.update({
        where: { id: userId },
        data: { coins: { decrement: item.cost } },
      });

      await tx.userBearInventory.create({
        data: { userId, bearItemId: item.id },
      });

      const newBalance = balance - item.cost;
      return { success: true, newBalance, itemId: item.id };
    });
  }

  async equipItem(
    userId: string,
    dto: EquipBearItemDto,
  ): Promise<UserBearLoadoutDto> {
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

  // ── Admin CRUD ──

  async getBearItemById(id: string): Promise<BearItem | null> {
    return this.prisma.bearItem.findUnique({ where: { id } });
  }

  async createBearItem(dto: AdminBearItemDto): Promise<BearItem> {
    return this.prisma.bearItem.create({
      data: {
        name: dto.name?.substring(0, 256) ?? 'New Item',
        slot: this.toPrismaSlot(dto.slot ?? BearSlotDto.ACCESSORY),
        cost: dto.cost ?? 0,
        assetKey: dto.assetKey ?? '',
        mimeType: dto.mimeType ?? null,
        zIndex: dto.zIndex ?? null,
        isDefault: dto.isDefault ?? false,
      },
    });
  }

  async updateBearItem(
    id: string,
    dto: AdminBearItemDto,
  ): Promise<BearItem | null> {
    const existing = await this.prisma.bearItem.findUnique({ where: { id } });
    if (!existing) return null;

    return this.prisma.bearItem.update({
      where: { id },
      data: {
        name: dto.name?.substring(0, 256),
        cost: dto.cost,
        assetKey: dto.assetKey,
        mimeType: dto.mimeType,
        zIndex: dto.zIndex,
        isDefault: dto.isDefault,
      },
    });
  }

  async getAffectedUserIds(bearItemId: string): Promise<string[]> {
    const [invUsers, equipUsers] = await Promise.all([
      this.prisma.userBearInventory.findMany({
        where: { bearItemId },
        select: { userId: true },
      }),
      this.prisma.userBearEquipped.findMany({
        where: { bearItemId },
        select: { userId: true },
      }),
    ]);

    return [
      ...new Set([
        ...invUsers.map(r => r.userId),
        ...equipUsers.map(r => r.userId),
      ]),
    ];
  }

  async getEquippedEntries(
    bearItemId: string,
  ): Promise<{ userId: string; slot: PrismaBearSlot }[]> {
    return this.prisma.userBearEquipped.findMany({
      where: { bearItemId },
      select: { userId: true, slot: true },
    });
  }

  /**
   * For each (userId, slot) pair, equip the default item for that slot.
   * If no default exists for a slot, the slot stays empty.
   */
  async reEquipDefaults(
    entries: { userId: string; slot: PrismaBearSlot }[],
  ): Promise<void> {
    if (entries.length === 0) return;

    const slots = [...new Set(entries.map(e => e.slot))];
    const defaultItems = await this.prisma.bearItem.findMany({
      where: { isDefault: true, slot: { in: slots } },
    });
    const defaultBySlot = new Map(defaultItems.map(i => [i.slot, i]));

    for (const { userId, slot } of entries) {
      const defaultItem = defaultBySlot.get(slot);
      if (!defaultItem) continue;

      await this.prisma.userBearEquipped.upsert({
        where: { userId_slot: { userId, slot } },
        create: { userId, slot, bearItemId: defaultItem.id },
        update: { bearItemId: defaultItem.id },
      });
    }
  }

  async deleteBearItem(id: string): Promise<boolean> {
    const existing = await this.prisma.bearItem.findUnique({ where: { id } });
    if (!existing) return false;

    await this.prisma.bearItem.delete({ where: { id } });
    return true;
  }

  toAdminBearItemDto(item: BearItem): AdminBearItemDto {
    return {
      id: item.id,
      name: item.name,
      slot: this.toDtoSlot(item.slot),
      cost: item.cost,
      assetKey: item.assetKey,
      mimeType: item.mimeType ?? undefined,
      zIndex: item.zIndex ?? undefined,
      isDefault: item.isDefault,
    };
  }

  async emitUpdateBearItemData(
    item: BearItem,
    deleted: boolean,
    target?: string,
  ) {
    const dto: UpdateBearItemDataDto = {
      bearItem: deleted ? { id: item.id } : this.toAdminBearItemDto(item),
      deleted,
    };

    await this.clientService.sendProtected(
      'updateBearItemData',
      target ?? null,
      dto,
    );
  }
}
