import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { json, urlencoded } from 'express';
import { DbExceptionFilter } from './common/filters/db-exception.filter';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
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

### Authentication
- Send OTP
- Verify OTP
- JWT Authentication
- Profile Completion
- Upload Profile Image
- Get Current User
- Update Profile

### Categories
- Create Category
- Get Categories
- Parent Categories
- Subcategories
- Category Tree

### Products
- Create Product
- Search Products
- Featured Products
- Product Filters
- Product Variants
- Upload Product Images
- Category Products
- Update Stock

### Markets
- List Markets

## Tech Stack
- **NestJS** - Backend Framework
- **PostgreSQL** - Database
- **Drizzle ORM** - ORM
- **JWT** - Authentication
- **Cloudinary** - Image Storage
- **UUID** - IDs
- **Class Validator** - Validation

## Authentication
Protected endpoints require:
\`\`\`
Authorization: Bearer JWT_TOKEN
\`\`\`

Example:
\`\`\`
Authorization: Bearer eyJhb...
\`\`\`

## Base URLs
- **API**: \`http://localhost:8080\`
- **Documentation**: \`http://localhost:8080/docs\`

## Error Responses

### 400 Bad Request
\`\`\`json
{
  "statusCode": 400,
  "message": "Bad Request"
}
\`\`\`

### 401 Unauthorized
\`\`\`json
{
  "statusCode": 401,
  "message": "Unauthorized"
}
\`\`\`

### 404 Not Found
\`\`\`json
{
  "statusCode": 404,
  "message": "Not Found"
}
\`\`\`

### 500 Internal Server Error
\`\`\`json
{
  "statusCode": 500,
  "message": "Internal Server Error"
}
\`\`\`

## Validation
Global ValidationPipe enabled with:
- DTO Validation
- Type Transformation
- Whitelisting
- Reject Unknown Fields
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
      'JWT-auth', // This name here is important for matching up with @ApiBearerAuth() in your controllers!
    )
    .addTag('auth', 'Authentication endpoints - OTP, JWT, Profile Management')
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
