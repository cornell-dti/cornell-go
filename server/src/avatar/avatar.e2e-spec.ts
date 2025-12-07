import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../app.module';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { AuthType, User } from '@prisma/client';
import { AvatarService } from './avatar.service';
import { BearSlotDto } from './avatar.dto';

describe('AvatarModule E2E', () => {
    let app: INestApplication;
    let moduleRef: TestingModule;
    let prisma: PrismaService;
    let userService: UserService;
    let avatarService: AvatarService;

    let user: User;

    let eyesDefaultId: string;
    let mouthPaidId: string;
    let colorPaidId: string;
    let accessoryPaidId: string;

    beforeAll(async () => {
        moduleRef = await Test.createTestingModule({
            imports: [AppModule],
        }).compile();

        app = moduleRef.createNestApplication();
        await app.init();

        prisma = moduleRef.get<PrismaService>(PrismaService);
        userService = moduleRef.get<UserService>(UserService);
        avatarService = moduleRef.get<AvatarService>(AvatarService);

        // Create a test user
        user = await userService.register(
            'test-avatar@example.com',
            'test-avatar-user',
            '2025',
            'Engineering',
            'Computer Science',
            ['Nature'],
            0,
            0,
            AuthType.DEVICE,
            'avatar-auth',
            'UNDERGRADUATE',
        );
        // Ensure deterministic score for purchases
        user = await prisma.user.update({
            where: { id: user.id },
            data: { score: 200 },
        });

        // Seed a small catalog of bear items used by tests
        const eyesDefault = await prisma.bearItem.create({
            data: {
                name: 'Test Eyes Default',
                slot: 'EYES',
                cost: 0,
                assetKey: 'test_eyes_default',
                mimeType: 'image/png',
                zIndex: 10,
                isDefault: true,
            },
        });
        eyesDefaultId = eyesDefault.id;

        const mouthPaid = await prisma.bearItem.create({
            data: {
                name: 'Test Mouth Paid',
                slot: 'MOUTH',
                cost: 40,
                assetKey: 'test_mouth_paid',
                mimeType: 'image/png',
                zIndex: 20,
                isDefault: false,
            },
        });
        mouthPaidId = mouthPaid.id;

        const colorPaid = await prisma.bearItem.create({
            data: {
                name: 'Test Color Paid',
                slot: 'COLOR',
                cost: 60,
                assetKey: 'test_color_paid',
                mimeType: 'image/png',
                zIndex: 0,
                isDefault: false,
            },
        });
        colorPaidId = colorPaid.id;

        const accessoryPaid = await prisma.bearItem.create({
            data: {
                name: 'Test Accessory Paid',
                slot: 'ACCESSORY',
                cost: 50,
                assetKey: 'test_accessory_paid',
                mimeType: 'image/png',
                zIndex: 30,
                isDefault: false,
            },
        });
        accessoryPaidId = accessoryPaid.id;
    });

    it('should successfully find AvatarService', async () => {
        const svc = moduleRef.get<AvatarService>(AvatarService);
        expect(svc).toBeDefined();
    });

    describe('Read/list operations', () => {
        it('should list all items and filter by slot', async () => {
            const all = await avatarService.listItems();
            expect(all.length).toBeGreaterThanOrEqual(4);

            const eyesOnly = await avatarService.listItems(BearSlotDto.EYES);
            expect(eyesOnly.length).toBeGreaterThanOrEqual(1);
            expect(eyesOnly.every(i => i.slot === BearSlotDto.EYES)).toBe(true);
        });

        it('should return initial empty inventory with correct balance', async () => {
            const inv = await avatarService.getInventory(user.id);
            expect(inv.userId).toEqual(user.id);
            expect(inv.items.length).toBe(0);
            expect(inv.balance).toBe(200);
        });

        it('should have empty loadout initially', async () => {
            const load = await avatarService.getLoadout(user.id);
            expect(load.userId).toEqual(user.id);
            expect(load.equipped.length).toBe(0);
        });
    });

    describe('Purchase operations', () => {
        it('should purchase an item and update inventory and balance', async () => {
            const before = await avatarService.getInventory(user.id);
            const res = await avatarService.purchaseItem(user.id, { itemId: accessoryPaidId });
            expect(res.success).toBe(true);
            expect(res.itemId).toEqual(accessoryPaidId);
            expect(res.newBalance).toBeLessThan(before.balance);

            const after = await avatarService.getInventory(user.id);
            expect(after.items.find(i => i.id === accessoryPaidId)).toBeDefined();
            expect(after.balance).toEqual(res.newBalance);
        });

        it('should be idempotent when purchasing an already owned item', async () => {
            const before = await avatarService.getInventory(user.id);
            const res = await avatarService.purchaseItem(user.id, { itemId: accessoryPaidId });
            expect(res.success).toBe(true);
            // Balance should remain the same if already owned (no double charge)
            const after = await avatarService.getInventory(user.id);
            expect(after.balance).toEqual(before.balance);
        });

        it('should fail to purchase when balance is insufficient', async () => {
            // Lower user balance to below the colorPaid cost (60)
            await prisma.user.update({
                where: { id: user.id },
                data: { score: 10 },
            });
            const before = await avatarService.getInventory(user.id);
            const res = await avatarService.purchaseItem(user.id, { itemId: colorPaidId });
            expect(res.success).toBe(false);
            expect(res.itemId).toEqual(colorPaidId);
            // Balance unchanged
            const after = await avatarService.getInventory(user.id);
            expect(after.balance).toEqual(before.balance);

            // Restore balance for subsequent tests
            await prisma.user.update({
                where: { id: user.id },
                data: { score: 200 },
            });
        });

        it('should report failure for non-existent item id', async () => {
            const before = await avatarService.getInventory(user.id);
            const res = await avatarService.purchaseItem(user.id, { itemId: 'non-existent-id' });
            expect(res.success).toBe(false);
            expect(res.itemId).toEqual('non-existent-id');
            const after = await avatarService.getInventory(user.id);
            expect(after.balance).toEqual(before.balance);
        });
    });

    describe('Equip operations', () => {
        it('should equip a default item without ownership', async () => {
            const load1 = await avatarService.equipItem(user.id, {
                slot: BearSlotDto.EYES,
                itemId: eyesDefaultId,
            });
            const eyesEntry = load1.equipped.find(e => e.slot === BearSlotDto.EYES);
            expect(eyesEntry?.itemId).toEqual(eyesDefaultId);
        });

        it('should not equip a not-owned, non-default item', async () => {
            // Ensure user does not own mouthPaidId
            await prisma.userBearInventory.deleteMany({
                where: { userId: user.id, bearItemId: mouthPaidId },
            });
            const load2 = await avatarService.equipItem(user.id, {
                slot: BearSlotDto.MOUTH,
                itemId: mouthPaidId,
            });
            const mouthEntry = load2.equipped.find(e => e.slot === BearSlotDto.MOUTH);
            // Entry should be undefined or not equal to mouthPaidId since user doesn't own it and it's not default
            expect(!mouthEntry || mouthEntry.itemId !== mouthPaidId).toBe(true);
        });

        it('should equip an owned item and then unequip it', async () => {
            // Purchase the mouth item
            await avatarService.purchaseItem(user.id, { itemId: mouthPaidId });
            const load3 = await avatarService.equipItem(user.id, {
                slot: BearSlotDto.MOUTH,
                itemId: mouthPaidId,
            });
            const mouthEntry = load3.equipped.find(e => e.slot === BearSlotDto.MOUTH);
            expect(mouthEntry?.itemId).toEqual(mouthPaidId);

            // Unequip
            const load4 = await avatarService.equipItem(user.id, {
                slot: BearSlotDto.MOUTH,
            });
            const mouthEntryAfter = load4.equipped.find(e => e.slot === BearSlotDto.MOUTH);
            expect(mouthEntryAfter).toBeUndefined();
        });
    });

    afterAll(async () => {
        // Clean up created data
        if (user) {
            await prisma.user.delete({
                where: { id: user.id },
            });
        }
        // Remove any equipped/inventory created for this user (in case cascading didn't)
        await prisma.userBearEquipped.deleteMany({
            where: { userId: user?.id },
        });
        await prisma.userBearInventory.deleteMany({
            where: { userId: user?.id },
        });
        // Remove test bear items
        await prisma.bearItem.deleteMany({
            where: {
                assetKey: { startsWith: 'test_' },
            },
        });
        await app.close();
    });
});


