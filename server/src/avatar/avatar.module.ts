import { forwardRef, Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ClientModule } from '../client/client.module';
import { PrismaModule } from '../prisma/prisma.module';
import { CaslModule } from '../casl/casl.module';
import { AvatarGateway } from './avatar.gateway';
import { AvatarService } from './avatar.service';

@Module({
    imports: [
        forwardRef(() => AuthModule),
        ClientModule,
        PrismaModule,
        CaslModule,
    ],
    providers: [AvatarService, AvatarGateway],
    exports: [AvatarService, AvatarGateway],
})
export class AvatarModule { }


