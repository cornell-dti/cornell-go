import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { User } from '@prisma/client';
import { UserGuard } from '../auth/jwt-auth.guard';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import {
  EquipBearItemDto,
  PurchaseBearItemDto,
  RequestAllBearItemsDto,
  RequestBearItemsDto,
  RequestUserBearLoadoutDto,
  RequestUserInventoryDto,
  UpdateBearItemDataDto,
} from './avatar.dto';
import { AvatarService } from './avatar.service';
import { PoliciesGuard } from '../casl/policy.guard';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard, PoliciesGuard)
export class AvatarGateway {
  constructor(
    private clientService: ClientService,
    private avatarService: AvatarService,
  ) {}

  @SubscribeMessage('requestBearItems')
  async requestBearItems(
    @CallingUser() user: User,
    @MessageBody() data: RequestBearItemsDto,
  ) {
    const items = await this.avatarService.listItems(data?.slot);
    await this.clientService.sendProtected('updateBearItemsData', user, {
      items,
    });
    return items.length;
  }

  @SubscribeMessage('requestUserInventory')
  async requestUserInventory(
    @CallingUser() user: User,
    @MessageBody() _data: RequestUserInventoryDto,
  ) {
    const inv = await this.avatarService.getInventory(user.id);
    await this.clientService.sendProtected(
      'updateUserInventoryData',
      user,
      inv,
    );
    return inv.items.length;
  }

  @SubscribeMessage('requestUserBearLoadout')
  async requestUserBearLoadout(
    @CallingUser() user: User,
    @MessageBody() _data: RequestUserBearLoadoutDto,
  ) {
    const loadout = await this.avatarService.getLoadout(user.id);
    await this.clientService.sendProtected(
      'updateUserBearLoadoutData',
      user,
      loadout,
    );
    return loadout.equipped.length;
  }

  @SubscribeMessage('purchaseBearItem')
  async purchaseBearItem(
    @CallingUser() user: User,
    @MessageBody() data: PurchaseBearItemDto,
  ) {
    const result = await this.avatarService.purchaseItem(user.id, data);
    await this.clientService.sendProtected(
      'updatePurchaseResult',
      user,
      result,
    );

    // Emit updated inventory after purchase attempt (success or fail balance unchanged)
    const inv = await this.avatarService.getInventory(user.id);
    await this.clientService.sendProtected(
      'updateUserInventoryData',
      user,
      inv,
    );

    return result.success;
  }

  @SubscribeMessage('equipBearItem')
  async equipBearItem(
    @CallingUser() user: User,
    @MessageBody() data: EquipBearItemDto,
  ) {
    const loadout = await this.avatarService.equipItem(user.id, data);
    await this.clientService.sendProtected(
      'updateUserBearLoadoutData',
      user,
      loadout,
    );
    return true;
  }

  // ── Admin endpoints ──

  @SubscribeMessage('requestAllBearItems')
  async requestAllBearItems(
    @CallingUser() user: User,
    @MessageBody() _data: RequestAllBearItemsDto,
  ) {
    if (!user.administrator) {
      await this.clientService.emitErrorData(user, 'Unauthorized');
      return;
    }

    const items = await this.avatarService.listItems();
    for (const item of items) {
      const fullItem = await this.avatarService.getBearItemById(item.id);
      if (fullItem) {
        await this.avatarService.emitUpdateBearItemData(
          fullItem,
          false,
          'user/' + user.id,
        );
      }
    }
    return items.length;
  }

  @SubscribeMessage('updateBearItemData')
  async updateBearItemData(
    @CallingUser() user: User,
    @MessageBody() data: UpdateBearItemDataDto,
  ) {
    if (!user.administrator) {
      await this.clientService.emitErrorData(user, 'Unauthorized');
      return;
    }

    if (data.deleted) {
      const existing = await this.avatarService.getBearItemById(
        data.bearItem.id,
      );
      if (!existing) {
        await this.clientService.emitErrorData(user, 'Bear item not found!');
        return;
      }

      const [affectedUserIds, equippedEntries] = await Promise.all([
        this.avatarService.getAffectedUserIds(data.bearItem.id),
        this.avatarService.getEquippedEntries(data.bearItem.id),
      ]);

      const deleted = await this.avatarService.deleteBearItem(data.bearItem.id);
      if (!deleted) {
        await this.clientService.emitErrorData(
          user,
          'Failed to delete bear item!',
        );
        return;
      }

      await this.avatarService.reEquipDefaults(equippedEntries);
      await this.avatarService.emitUpdateBearItemData(existing, true);

      for (const userId of affectedUserIds) {
        const [inv, loadout] = await Promise.all([
          this.avatarService.getInventory(userId),
          this.avatarService.getLoadout(userId),
        ]);
        await Promise.all([
          this.clientService.sendProtected(
            'updateUserInventoryData',
            'user/' + userId,
            inv,
          ),
          this.clientService.sendProtected(
            'updateUserBearLoadoutData',
            'user/' + userId,
            loadout,
          ),
        ]);
      }

      return existing.id;
    }

    if (data.bearItem.id) {
      const updated = await this.avatarService.updateBearItem(
        data.bearItem.id,
        data.bearItem,
      );

      if (!updated) {
        await this.clientService.emitErrorData(
          user,
          'Failed to update bear item!',
        );
        return;
      }

      await this.avatarService.emitUpdateBearItemData(updated, false);
      return updated.id;
    }

    const created = await this.avatarService.createBearItem(data.bearItem);
    await this.avatarService.emitUpdateBearItemData(created, false);
    return created.id;
  }
}
