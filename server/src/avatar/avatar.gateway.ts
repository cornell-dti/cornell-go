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
    RequestBearItemsDto,
    RequestUserBearLoadoutDto,
    RequestUserInventoryDto,
} from './avatar.dto';
import { AvatarService } from './avatar.service';
import { PoliciesGuard } from '../casl/policy.guard';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard, PoliciesGuard)
export class AvatarGateway {
    constructor(
        private clientService: ClientService,
        private avatarService: AvatarService,
    ) { }

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
        await this.clientService.sendProtected('updateUserInventoryData', user, inv);
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
        await this.clientService.sendProtected('updatePurchaseResult', user, result);

        // Emit updated inventory after purchase attempt (success or fail balance unchanged)
        const inv = await this.avatarService.getInventory(user.id);
        await this.clientService.sendProtected('updateUserInventoryData', user, inv);

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
}


