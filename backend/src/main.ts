import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { json, urlencoded } from 'express';
import { DbExceptionFilter } from './common/filters/db-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 1. Configure all middlewares and payload limits FIRST
  app.use(json({ limit: '100mb' }));
  app.use(urlencoded({ extended: true, limit: '100mb' }));

  // 2. Set up global pipes & filters
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  app.useGlobalFilters(new DbExceptionFilter());

  // 3. Enable CORS
  app.enableCors();

  // 4. FINALLY, start listening for incoming traffic
  await app.listen(8080);

  console.log(`Application is running on: ${await app.getUrl()}`);
}
void bootstrap();
