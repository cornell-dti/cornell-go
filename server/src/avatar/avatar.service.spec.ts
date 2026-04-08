import { Test, TestingModule } from '@nestjs/testing';
import { AvatarService } from './avatar.service';
import { PrismaService } from '../prisma/prisma.service';
import { ClientService } from '../client/client.service';
import { BearSlotDto } from './avatar.dto';

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

const mockPrisma = {
  bearItem: {
    findMany: jest.fn(),
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  },
  userBearInventory: {
    findMany: jest.fn(),
    count: jest.fn(),
    create: jest.fn(),
  },
  userBearEquipped: {
    findMany: jest.fn(),
    upsert: jest.fn(),
    deleteMany: jest.fn(),
  },
  user: {
    findUnique: jest.fn(),
    update: jest.fn(),
  },
  $transaction: jest.fn(),
  $queryRaw: jest.fn(),
};

const mockClientService = {
  sendProtected: jest.fn(),
  emitErrorData: jest.fn(),
};

describe('AvatarService', () => {
  let service: AvatarService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AvatarService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: ClientService, useValue: mockClientService },
      ],
    }).compile();

    service = module.get<AvatarService>(AvatarService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('getBearItemById', () => {
    it('should return an item when found', async () => {
      mockPrisma.bearItem.findUnique.mockResolvedValue(mockBearItem);

      const result = await service.getBearItemById('item-1');

      expect(result).toEqual(mockBearItem);
      expect(mockPrisma.bearItem.findUnique).toHaveBeenCalledWith({
        where: { id: 'item-1' },
      });
    });

    it('should return null when not found', async () => {
      mockPrisma.bearItem.findUnique.mockResolvedValue(null);

      const result = await service.getBearItemById('nonexistent');

      expect(result).toBeNull();
    });
  });

  describe('createBearItem', () => {
    it('should create a bear item with provided fields', async () => {
      const dto = {
        id: '',
        name: 'Blue Eyes',
        slot: BearSlotDto.EYES,
        cost: 50,
        assetKey: 'eyes_blue',
        mimeType: 'image/png',
        zIndex: 2,
        isDefault: false,
      };

      mockPrisma.bearItem.create.mockResolvedValue({
        ...mockBearItem,
        ...dto,
        id: 'new-id',
        slot: 'EYES',
      });

      const result = await service.createBearItem(dto);

      expect(mockPrisma.bearItem.create).toHaveBeenCalledWith({
        data: {
          name: 'Blue Eyes',
          slot: 'EYES',
          cost: 50,
          assetKey: 'eyes_blue',
          mimeType: 'image/png',
          zIndex: 2,
          isDefault: false,
        },
      });
      expect(result.id).toBe('new-id');
    });

    it('should use defaults when fields are omitted', async () => {
      const dto = { id: '' };

      mockPrisma.bearItem.create.mockResolvedValue({
        ...mockBearItem,
        id: 'new-id',
        name: 'New Item',
        slot: 'ACCESSORY',
        cost: 0,
        assetKey: '',
        mimeType: null,
        zIndex: null,
        isDefault: false,
      });

      await service.createBearItem(dto);

      expect(mockPrisma.bearItem.create).toHaveBeenCalledWith({
        data: {
          name: 'New Item',
          slot: 'ACCESSORY',
          cost: 0,
          assetKey: '',
          mimeType: null,
          zIndex: null,
          isDefault: false,
        },
      });
    });

    it('should truncate name to 256 characters', async () => {
      const longName = 'A'.repeat(300);
      const dto = { id: '', name: longName };

      mockPrisma.bearItem.create.mockResolvedValue(mockBearItem);

      await service.createBearItem(dto);

      const createCall = mockPrisma.bearItem.create.mock.calls[0][0];
      expect(createCall.data.name.length).toBe(256);
    });
  });

  describe('updateBearItem', () => {
    it('should update an existing bear item', async () => {
      mockPrisma.bearItem.findUnique.mockResolvedValue(mockBearItem);
      const updatedItem = { ...mockBearItem, name: 'Updated Name', cost: 200 };
      mockPrisma.bearItem.update.mockResolvedValue(updatedItem);

      const result = await service.updateBearItem('item-1', {
        id: 'item-1',
        name: 'Updated Name',
        cost: 200,
      });

      expect(result).toEqual(updatedItem);
      expect(mockPrisma.bearItem.update).toHaveBeenCalledWith({
        where: { id: 'item-1' },
        data: {
          name: 'Updated Name',
          slot: undefined,
          cost: 200,
          assetKey: undefined,
          mimeType: undefined,
          zIndex: undefined,
          isDefault: undefined,
        },
      });
    });

    it('should return null when item does not exist', async () => {
      mockPrisma.bearItem.findUnique.mockResolvedValue(null);

      const result = await service.updateBearItem('nonexistent', {
        id: 'nonexistent',
        name: 'Test',
      });

      expect(result).toBeNull();
      expect(mockPrisma.bearItem.update).not.toHaveBeenCalled();
    });
  });

  describe('deleteBearItem', () => {
    it('should delete an existing bear item and return true', async () => {
      mockPrisma.bearItem.findUnique.mockResolvedValue(mockBearItem);
      mockPrisma.bearItem.delete.mockResolvedValue(mockBearItem);

      const result = await service.deleteBearItem('item-1');

      expect(result).toBe(true);
      expect(mockPrisma.bearItem.delete).toHaveBeenCalledWith({
        where: { id: 'item-1' },
      });
    });

    it('should return false when item does not exist', async () => {
      mockPrisma.bearItem.findUnique.mockResolvedValue(null);

      const result = await service.deleteBearItem('nonexistent');

      expect(result).toBe(false);
      expect(mockPrisma.bearItem.delete).not.toHaveBeenCalled();
    });
  });

  describe('toAdminBearItemDto', () => {
    it('should convert a BearItem to AdminBearItemDto', () => {
      const dto = service.toAdminBearItemDto(mockBearItem as any);

      expect(dto).toEqual({
        id: 'item-1',
        name: 'Red Eyes',
        slot: BearSlotDto.EYES,
        cost: 100,
        assetKey: 'eyes_red',
        mimeType: 'image/png',
        zIndex: 1,
        isDefault: false,
      });
    });

    it('should handle null mimeType and zIndex', () => {
      const item = { ...mockBearItem, mimeType: null, zIndex: null };
      const dto = service.toAdminBearItemDto(item as any);

      expect(dto.mimeType).toBeUndefined();
      expect(dto.zIndex).toBeUndefined();
    });
  });

  describe('emitUpdateBearItemData', () => {
    it('should emit full item data when not deleted', async () => {
      await service.emitUpdateBearItemData(mockBearItem as any, false);

      expect(mockClientService.sendProtected).toHaveBeenCalledWith(
        'updateBearItemData',
        null,
        {
          bearItem: {
            id: 'item-1',
            name: 'Red Eyes',
            slot: BearSlotDto.EYES,
            cost: 100,
            assetKey: 'eyes_red',
            mimeType: 'image/png',
            zIndex: 1,
            isDefault: false,
          },
          deleted: false,
        },
      );
    });

    it('should emit only id when deleted', async () => {
      await service.emitUpdateBearItemData(mockBearItem as any, true);

      expect(mockClientService.sendProtected).toHaveBeenCalledWith(
        'updateBearItemData',
        null,
        {
          bearItem: { id: 'item-1' },
          deleted: true,
        },
      );
    });

    it('should send to a specific target when provided', async () => {
      await service.emitUpdateBearItemData(
        mockBearItem as any,
        false,
        'user/admin-1',
      );

      expect(mockClientService.sendProtected).toHaveBeenCalledWith(
        'updateBearItemData',
        'user/admin-1',
        expect.any(Object),
      );
    });
  });

  describe('listItems', () => {
    it('should return all items when no slot filter', async () => {
      mockPrisma.bearItem.findMany.mockResolvedValue([mockBearItem]);

      const result = await service.listItems();

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('item-1');
      expect(mockPrisma.bearItem.findMany).toHaveBeenCalledWith({
        where: undefined,
        orderBy: [{ slot: 'asc' }, { zIndex: 'asc' }, { name: 'asc' }],
      });
    });

    it('should filter by slot when provided', async () => {
      mockPrisma.bearItem.findMany.mockResolvedValue([]);

      await service.listItems(BearSlotDto.MOUTH);

      expect(mockPrisma.bearItem.findMany).toHaveBeenCalledWith({
        where: { slot: 'MOUTH' },
        orderBy: [{ slot: 'asc' }, { zIndex: 'asc' }, { name: 'asc' }],
      });
    });
  });
});
