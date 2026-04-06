import { Test, TestingModule } from '@nestjs/testing';
import { AvatarGateway } from './avatar.gateway';
import { AvatarService } from './avatar.service';
import { ClientService } from '../client/client.service';
import { AuthService } from '../auth/auth.service';
import { CaslAbilityFactory } from '../casl/casl-ability.factory';
import { Reflector } from '@nestjs/core';
import { BearSlotDto } from './avatar.dto';

const adminUser = {
  id: 'admin-1',
  administrator: true,
  isBanned: false,
} as any;

const regularUser = {
  id: 'user-1',
  administrator: false,
  isBanned: false,
} as any;

const mockBearItem = {
  id: 'item-1',
  createdAt: new Date(),
  updatedAt: new Date(),
  name: 'Red Eyes',
  slot: 'EYES' as const,
  cost: 100,
  assetKey: 'eyes_red',
  mimeType: 'image/png',
  zIndex: 1,
  isDefault: false,
};

const mockAvatarService = {
  listItems: jest.fn(),
  getBearItemById: jest.fn(),
  createBearItem: jest.fn(),
  updateBearItem: jest.fn(),
  deleteBearItem: jest.fn(),
  emitUpdateBearItemData: jest.fn(),
  getInventory: jest.fn(),
  getLoadout: jest.fn(),
  purchaseItem: jest.fn(),
  equipItem: jest.fn(),
  toAdminBearItemDto: jest.fn(),
};

const mockClientService = {
  sendProtected: jest.fn(),
  emitErrorData: jest.fn(),
};

describe('AvatarGateway', () => {
  let gateway: AvatarGateway;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AvatarGateway,
        { provide: AvatarService, useValue: mockAvatarService },
        { provide: ClientService, useValue: mockClientService },
        { provide: AuthService, useValue: null },
        { provide: CaslAbilityFactory, useValue: null },
        { provide: Reflector, useValue: null },
      ],
    }).compile();

    gateway = module.get<AvatarGateway>(AvatarGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });

  describe('requestAllBearItems', () => {
    it('should return items for admin users', async () => {
      const bearItemDto = {
        id: 'item-1',
        name: 'Red Eyes',
        slot: BearSlotDto.EYES,
        cost: 100,
        assetKey: 'eyes_red',
        mimeType: 'image/png',
        zIndex: 1,
      };
      mockAvatarService.listItems.mockResolvedValue([bearItemDto]);
      mockAvatarService.getBearItemById.mockResolvedValue(mockBearItem);

      const result = await gateway.requestAllBearItems(adminUser, {});

      expect(result).toBe(1);
      expect(mockAvatarService.listItems).toHaveBeenCalledWith();
      expect(mockAvatarService.emitUpdateBearItemData).toHaveBeenCalledWith(
        mockBearItem,
        false,
        'user/admin-1',
      );
    });

    it('should reject non-admin users', async () => {
      const result = await gateway.requestAllBearItems(regularUser, {});

      expect(result).toBeUndefined();
      expect(mockClientService.emitErrorData).toHaveBeenCalledWith(
        regularUser,
        'Unauthorized',
      );
      expect(mockAvatarService.listItems).not.toHaveBeenCalled();
    });
  });

  describe('updateBearItemData - create', () => {
    it('should create a new bear item when id is empty', async () => {
      const newItem = { ...mockBearItem, id: 'new-id' };
      mockAvatarService.createBearItem.mockResolvedValue(newItem);

      const result = await gateway.updateBearItemData(adminUser, {
        bearItem: {
          id: '',
          name: 'New Item',
          slot: BearSlotDto.MOUTH,
          cost: 50,
          assetKey: 'mouth_smile',
        },
        deleted: false,
      });

      expect(result).toBe('new-id');
      expect(mockAvatarService.createBearItem).toHaveBeenCalled();
      expect(mockAvatarService.emitUpdateBearItemData).toHaveBeenCalledWith(
        newItem,
        false,
      );
    });

    it('should reject non-admin create requests', async () => {
      const result = await gateway.updateBearItemData(regularUser, {
        bearItem: { id: '', name: 'Hack' },
        deleted: false,
      });

      expect(result).toBeUndefined();
      expect(mockClientService.emitErrorData).toHaveBeenCalledWith(
        regularUser,
        'Unauthorized',
      );
      expect(mockAvatarService.createBearItem).not.toHaveBeenCalled();
    });
  });

  describe('updateBearItemData - update', () => {
    it('should update an existing bear item', async () => {
      const updatedItem = { ...mockBearItem, name: 'Updated' };
      mockAvatarService.updateBearItem.mockResolvedValue(updatedItem);

      const result = await gateway.updateBearItemData(adminUser, {
        bearItem: { id: 'item-1', name: 'Updated' },
        deleted: false,
      });

      expect(result).toBe('item-1');
      expect(mockAvatarService.updateBearItem).toHaveBeenCalledWith('item-1', {
        id: 'item-1',
        name: 'Updated',
      });
      expect(mockAvatarService.emitUpdateBearItemData).toHaveBeenCalledWith(
        updatedItem,
        false,
      );
    });

    it('should emit error when update target not found', async () => {
      mockAvatarService.updateBearItem.mockResolvedValue(null);

      const result = await gateway.updateBearItemData(adminUser, {
        bearItem: { id: 'nonexistent', name: 'Test' },
        deleted: false,
      });

      expect(result).toBeUndefined();
      expect(mockClientService.emitErrorData).toHaveBeenCalledWith(
        adminUser,
        'Failed to update bear item!',
      );
    });
  });

  describe('updateBearItemData - delete', () => {
    it('should delete an existing bear item', async () => {
      mockAvatarService.getBearItemById.mockResolvedValue(mockBearItem);
      mockAvatarService.deleteBearItem.mockResolvedValue(true);

      const result = await gateway.updateBearItemData(adminUser, {
        bearItem: { id: 'item-1' },
        deleted: true,
      });

      expect(result).toBe('item-1');
      expect(mockAvatarService.deleteBearItem).toHaveBeenCalledWith('item-1');
      expect(mockAvatarService.emitUpdateBearItemData).toHaveBeenCalledWith(
        mockBearItem,
        true,
      );
    });

    it('should emit error when delete target not found', async () => {
      mockAvatarService.getBearItemById.mockResolvedValue(null);

      const result = await gateway.updateBearItemData(adminUser, {
        bearItem: { id: 'nonexistent' },
        deleted: true,
      });

      expect(result).toBeUndefined();
      expect(mockClientService.emitErrorData).toHaveBeenCalledWith(
        adminUser,
        'Bear item not found!',
      );
      expect(mockAvatarService.deleteBearItem).not.toHaveBeenCalled();
    });

    it('should emit error when delete fails', async () => {
      mockAvatarService.getBearItemById.mockResolvedValue(mockBearItem);
      mockAvatarService.deleteBearItem.mockResolvedValue(false);

      const result = await gateway.updateBearItemData(adminUser, {
        bearItem: { id: 'item-1' },
        deleted: true,
      });

      expect(result).toBeUndefined();
      expect(mockClientService.emitErrorData).toHaveBeenCalledWith(
        adminUser,
        'Failed to delete bear item!',
      );
    });

    it('should reject non-admin delete requests', async () => {
      const result = await gateway.updateBearItemData(regularUser, {
        bearItem: { id: 'item-1' },
        deleted: true,
      });

      expect(result).toBeUndefined();
      expect(mockClientService.emitErrorData).toHaveBeenCalledWith(
        regularUser,
        'Unauthorized',
      );
      expect(mockAvatarService.deleteBearItem).not.toHaveBeenCalled();
    });
  });
});
