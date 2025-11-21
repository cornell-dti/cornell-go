import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

require('events').EventEmitter.defaultMaxListeners = 128;
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  const port = process.env.PORT ?? 80;
  await app.listen(port, '0.0.0.0');
  console.log(`🚀 Server is running on http://0.0.0.0:${port}`);
}
bootstrap();
