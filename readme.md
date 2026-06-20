# Ecommerce API

A production-ready Ecommerce Backend built with:

- NestJS
- TypeScript
- PostgreSQL
- Drizzle ORM
- JWT Authentication
- Cloudinary Image Storage
- OTP Authentication
- Docker Ready

---

# Features

## Authentication

- Send OTP
- Verify OTP
- JWT Authentication
- Profile Completion
- Upload Profile Image
- Get Current User
- Update Profile

## Categories

- Create Category
- Get Categories
- Parent Categories
- Subcategories
- Category Tree

## Products

- Create Product
- Search Products
- Featured Products
- Product Filters
- Product Variants
- Upload Product Images
- Category Products
- Update Stock

## Markets

- List Markets

---

# Tech Stack

| Technology      | Usage             |
| --------------- | ----------------- |
| NestJS          | Backend Framework |
| PostgreSQL      | Database          |
| Drizzle ORM     | ORM               |
| JWT             | Authentication    |
| Cloudinary      | Image Storage     |
| UUID            | IDs               |
| Class Validator | Validation        |

---

# Installation

```bash
git clone https://github.com/bashbashofficial9-oss/bashbash.app.git

cd ecommerce-api

npm install
```

---

# Environment Variables

Create:

```bash
.env
```

```env
DATABASE_URL=

JWT_SECRET=

JWT_EXPIRES_IN=364d

CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
```

---

# Run Development

```bash
npm run start:dev
```

---

# Run Production

```bash
npm run build

npm run start:prod
```

---

# Server

Default Port

```http
http://localhost:8080
```

---

# Authentication

Protected endpoints require:

```http
Authorization: Bearer JWT_TOKEN
```

Example:

```http
Authorization: Bearer eyJhb...
```

---

# AUTH API

Base URL

```http
/ auth
```

---

## Send OTP

### Endpoint

```http
POST /auth/send-otp
```

### Request

```json
{
  "phoneNumber": "+252612345678"
}
```

### Response

```json
{
  "message": "OTP sent successfully",
  "debugOtp": "123456"
}
```

---

## Verify OTP

### Endpoint

```http
POST /auth/verify-otp
```

### Request

```json
{
  "phoneNumber": "+252612345678",
  "otpCode": "123456"
}
```

### Response

```json
{
  "message": "OTP verified successfully",
  "token": "JWT_TOKEN",
  "user": {
    "id": "uuid",
    "phoneNumber": "+252612345678",
    "isVerified": true,
    "hasProfile": false
  }
}
```

---

## Complete Profile

### Endpoint

```http
POST /auth/complete-profile
```

### Protected

```http
Authorization: Bearer TOKEN
```

### Request

```json
{
  "name": "farah Jamac",
  "email": "farah@example.com",
  "profileImage": "https://..."
}
```

### Response

```json
{
  "message": "Profile completed successfully",
  "token": "JWT_TOKEN",
  "user": {}
}
```

---

## Upload Profile Image

### Endpoint

```http
POST /auth/upload-profile-image
```

### Multipart Form Data

```bash
image=file
```

Response:

```json
{
  "message": "Profile image uploaded successfully",
  "profileImage": "https://..."
}
```

---

## Upload Base64 Image

### Endpoint

```http
POST /auth/upload-profile-image-url
```

### Request

```json
{
  "imageUrl": "data:image/png;base64,..."
}
```

---

## Current User

### Endpoint

```http
GET /auth/me
```

### Response

```json
{
  "id": "uuid",
  "phoneNumber": "+252...",
  "name": "farah"
}
```

---

## Update Profile

### Endpoint

```http
PATCH /auth/profile
```

### Request

```json
{
  "name": "farah Jamac",
  "email": "farah@example.com",
  "marketId": "uuid"
}
```

---

# CATEGORIES API

Base URL

```http
/categories
```

---

## Create Category

```http
POST /categories
```

### Request

```json
{
  "name": "Electronics",
  "slug": "electronics",
  "description": "Electronic devices"
}
```

---

## Get Categories

```http
GET /categories
```

---

## Parent Categories

```http
GET /categories/parents
```

Returns only root categories.

---

## Get Subcategories

```http
GET /categories/sub/{parentId}
```

Example:

```http
GET /categories/sub/8fbb1f7e...
```

---

## Get Category

```http
GET /categories/{id}
```

---

## Delete Category

```http
DELETE /categories/{id}
```

---

# PRODUCTS API

Base URL

```http
/products
```

---

## Create Product

```http
POST /products
```

### Request

```json
{
  "name": "iPhone 15",
  "description": "Apple smartphone",
  "price": 1200,
  "stock": 50,
  "categoryId": "uuid",
  "imageUrls": ["https://..."]
}
```

---

## Get Products

```http
GET /products
```

---

## Search Products

```http
GET /products/search
```

Example:

```http
GET /products/search?search=iphone
```

Filters:

```http
search
categoryId
minPrice
maxPrice
sortBy
page
limit
```

Sort Values:

```text
price_asc
price_desc
newest
popular
```

---

## Product Filters

```http
GET /products/filters
```

Returns:

```json
{
  "priceRange": {
    "min": 10,
    "max": 2000
  },
  "categories": []
}
```

---

## Featured Products

```http
GET /products/featured
```

Optional:

```http
GET /products/featured?limit=20
```

---

## Product By Slug

```http
GET /products/slug/{slug}
```

Example:

```http
GET /products/slug/iphone-15
```

---

## Products By Category

```http
GET /products/category/{categoryId}
```

Supports:

```http
page
limit
sortBy
minPrice
maxPrice
```

---

## Product Details

```http
GET /products/{id}
```

---

## Upload Product Images (URLs)

```http
POST /products/{id}/images/urls
```

### Request

```json
{
  "imageUrls": ["https://..."]
}
```

---

## Upload Product Image (Base64)

```http
POST /products/{id}/images/base64
```

### Request

```json
{
  "base64Image": "data:image/png;base64,..."
}
```

---

## Add Product Variant

```http
POST /products/{id}/variants
```

### Request

```json
{
  "colorId": "uuid",
  "sizeId": "uuid",
  "sku": "IPHONE-BLACK-128",
  "stock": 20,
  "price": 1300
}
```

---

## Update Product

```http
PATCH /products/{id}
```

---

## Delete Product Image

```http
DELETE /products/{id}/images/{imageId}
```

---

## Delete Product

```http
DELETE /products/{id}
```

---

## Update Variant Stock

```http
PATCH /products/variants/{variantId}/stock
```

### Request

```json
{
  "quantity": 2
}
```

---

## Debug Category

```http
GET /products/debug/category/{categoryId}
```

Returns:

```json
{
  "directSubcategoriesCount": 2,
  "totalProducts": 100
}
```

---

# MARKETS API

Base URL

```http
/markets
```

---

## Get Markets

```http
GET /markets
```

### Response

```json
[
  {
    "id": "uuid",
    "name": "Bakara Market"
  }
]
```

---

# Validation

Global ValidationPipe enabled.

Features:

- DTO Validation
- Type Transformation
- Whitelisting
- Reject Unknown Fields

---

# Error Responses

## 400

```json
{
  "statusCode": 400,
  "message": "Bad Request"
}
```

## 401

```json
{
  "statusCode": 401,
  "message": "Unauthorized"
}
```

## 404

```json
{
  "statusCode": 404,
  "message": "Not Found"
}
```

## 500

```json
{
  "statusCode": 500,
  "message": "Internal Server Error"
}
```

---

# Folder Structure

```text
src
│
├── auth
│   ├── dto
│   ├── guards
│   ├── auth.controller.ts
│   ├── auth.service.ts
│
├── products
│   ├── dto
│   ├── products.controller.ts
│   ├── products.service.ts
│
├── categories
│   ├── dto
│   ├── categories.controller.ts
│   ├── categories.service.ts
│
├── markets
│   ├── markets.controller.ts
│
├── drizzle
│   ├── schema.ts
│   ├── drizzle.service.ts
│
├── cloudinary
│
├── common
│   └── filters
│
├── app.module.ts
└── main.ts
```

---

# Production Notes

- PostgreSQL recommended
- Enable HTTPS
- Use real SMS provider
- Store JWT secret securely
- Disable debug OTP in production
- Configure Cloudinary folders
- Enable rate limiting
- Add Swagger Documentation
- Add Redis Caching
- Add Monitoring & Logging
- Add Docker Deployment

---

# License

MIT
