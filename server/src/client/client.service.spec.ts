import { Test, TestingModule } from '@nestjs/testing';
import { ClientService } from '../client/client.service';
import { ClientGateway } from './client.gateway';

describe('ClientService', () => {
  let service: ClientService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ClientService, ClientGateway],
    }).compile();

    service = module.get<ClientService>(ClientService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
