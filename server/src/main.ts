import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

require('events').EventEmitter.defaultMaxListeners = 128;
async function bootstrap() {
  const app = await NestFactory.create(AppModule, { snapshot: true });
  app.enableCors();
  await app.listen(process.env.PORT ?? 80, '0.0.0.0');
}
bootstrap();
