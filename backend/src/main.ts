import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { json, urlencoded } from 'express';
import { DbExceptionFilter } from './common/filters/db-exception.filter';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
// 🚨 REMOVED: import { RedisIoAdapter } from './chat/chat.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 1. Configure all middlewares and payload limits FIRST
  app.use(json({ limit: '10mb' }));
  app.use(urlencoded({ extended: true, limit: '10mb' }));

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

  // 🚨 COMMENTED OUT: Redis Adapter
  // For local development, Socket.io uses its default in-memory adapter which works perfectly.
  // You only need Redis in production when running multiple backend servers (use Render/Railway Redis, not Upstash).
  /*
  const redisAdapter = new RedisIoAdapter(app);
  await redisAdapter.connectToRedis(); 
  app.useWebSocketAdapter(redisAdapter);
  */

  app.useGlobalFilters(new DbExceptionFilter());

  // 3. Enable CORS
  app.enableCors();

  // 4. Setup Swagger with detailed information from README
  const config = new DocumentBuilder()
    .setTitle('Ecommerce API')
    .setDescription(
      `
# Production Ecommerce Backend API

## Features
... (Keep all your Swagger description text exactly as it was) ...
    `,
    )
    .setVersion('1.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'JWT',
        description: 'Enter JWT token',
        in: 'header',
      },
      'JWT-auth',
    )
    .addTag('auth', 'Authentication endpoints - OTP, JWT, Profile Management')
    .addTag('chat', 'Real-time Chat endpoints') // 🚨 ADDED
    .addTag('categories', 'Category management endpoints')
    .addTag('products', 'Product management endpoints')
    .addTag('markets', 'Market listing endpoints')
    .addServer('http://localhost:8080', 'Development Server')
    .addServer('https://api.example.com', 'Production Server')
    .build();

  const document = SwaggerModule.createDocument(app, config);

  // Custom options for Swagger UI
  SwaggerModule.setup('docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
      tagsSorter: 'alpha',
      operationsSorter: 'alpha',
      docExpansion: 'none',
      filter: true,
      showRequestDuration: true,
    },
    customSiteTitle: 'Ecommerce API Documentation',
    customCss: `
      .swagger-ui .topbar { display: none }
      .swagger-ui .info .title { font-size: 36px }
    `,
    customfavIcon: 'https://your-favicon-url.com/favicon.ico',
  });

  // 5. FINALLY, start listening for incoming traffic
  await app.listen(8080);

  console.log(`Application is running on: ${await app.getUrl()}`);
  console.log(`Swagger documentation available at: ${await app.getUrl()}/docs`);
}

void bootstrap();
