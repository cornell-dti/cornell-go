import { Test, TestingModule } from '@nestjs/testing';
import { ClientGateway } from './client.gateway';

describe('ClientGateway', () => {
  let gateway: ClientGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ClientGateway],
    }).compile();

    gateway = module.get<ClientGateway>(ClientGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});
