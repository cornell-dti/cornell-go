import { Test, TestingModule } from '@nestjs/testing';
import { OrganizationGateway } from './organization.gateway';
import { ClientService } from '../client/client.service';
import { OrganizationService } from './organization.service';
import { AuthService } from '../auth/auth.service';
import { CaslAbilityFactory } from '../casl/casl-ability.factory';
import { Reflector } from '@nestjs/core';

describe('OrganizationGateway', () => {
  let gateway: OrganizationGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrganizationGateway,
        {
          useValue: null,
          provide: ClientService,
        },
        {
          useValue: null,
          provide: OrganizationService,
        },
        {
          useValue: null,
          provide: CaslAbilityFactory,
        },
        {
          useValue: null,
          provide: Reflector,
        },
        {
          useValue: null,
          provide: AuthService,
        },
      ],
    }).compile();

    gateway = module.get<OrganizationGateway>(OrganizationGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});
