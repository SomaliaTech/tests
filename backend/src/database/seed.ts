// src/database/seed.ts
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from '../drizzle/schema';
import * as dotenv from 'dotenv';
import { faker } from '@faker-js/faker';

dotenv.config();

// Create pool with better Neon settings
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  max: 5,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 20000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10000,
});

const db = drizzle(pool, { schema });

// Type definitions
type CategoryInsert = typeof schema.categories.$inferInsert;
type ProductInsert = typeof schema.products.$inferInsert;
type VariantInsert = typeof schema.productVariants.$inferInsert;
type MediaInsert = typeof schema.mediaAssets.$inferInsert;

// Sample data
const categoryData: CategoryInsert[] = [
  { name: 'Electronics', slug: 'electronics', description: 'Gadgets and electronic devices', isActive: true },
  { name: 'Clothing', slug: 'clothing', description: 'Fashion and apparel', isActive: true },
  { name: 'Home & Kitchen', slug: 'home-kitchen', description: 'Home appliances and kitchenware', isActive: true },
  { name: 'Books', slug: 'books', description: 'Books and publications', isActive: true },
  { name: 'Toys & Games', slug: 'toys-games', description: 'Toys and board games', isActive: true },
  { name: 'Sports & Outdoors', slug: 'sports-outdoors', description: 'Sports equipment and outdoor gear', isActive: true },
  { name: 'Beauty & Health', slug: 'beauty-health', description: 'Beauty products and health items', isActive: true },
];

const colorData = [
  { name: 'Black', code: '#000000' },
  { name: 'White', code: '#FFFFFF' },
  { name: 'Red', code: '#FF0000' },
  { name: 'Blue', code: '#0000FF' },
  { name: 'Green', code: '#00FF00' },
  { name: 'Yellow', code: '#FFFF00' },
  { name: 'Purple', code: '#800080' },
  { name: 'Orange', code: '#FFA500' },
  { name: 'Pink', code: '#FFC0CB' },
  { name: 'Gray', code: '#808080' },
  { name: 'Navy', code: '#000080' },
  { name: 'Brown', code: '#A52A2A' },
];

const sizeData = [
  { name: 'XS', value: 'XS' },
  { name: 'S', value: 'S' },
  { name: 'M', value: 'M' },
  { name: 'L', value: 'L' },
  { name: 'XL', value: 'XL' },
  { name: 'XXL', value: 'XXL' },
  { name: 'One Size', value: 'OS' },
];

// Retry wrapper
async function withRetry<T>(
  fn: () => Promise<T>,
  maxRetries = 3,
  delayMs = 1000
): Promise<T> {
  let lastError: Error | null = null;
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error: any) {
      lastError = error;
      const isConnectionError = error.message?.includes('ECONNRESET') ||
                               error.message?.includes('Connection terminated') ||
                               error.message?.includes('timeout');
      
      if (isConnectionError && attempt < maxRetries) {
        console.log(`⚠️ Connection error, retrying ${attempt}/${maxRetries}...`);
        await new Promise(resolve => setTimeout(resolve, delayMs * attempt));
        
        // Reconnect if needed
        if (attempt === 2) {
          console.log('🔄 Reconnecting to database...');
          await pool.end().catch(() => {});
          // Pool will re-connect on next query
        }
      } else {
        throw error;
      }
    }
  }
  throw lastError || new Error('Max retries exceeded');
}

// Generate products for each category
function generateProductsForCategory(categoryId: string, count: number): ProductInsert[] {
  const products: ProductInsert[] = [];
  
  for (let i = 0; i < count; i++) {
    const name = faker.commerce.productName();
    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-') + '-' + faker.string.alphanumeric(6);
    const price = parseFloat(faker.commerce.price({ min: 10, max: 500 }));
    const compareAtPrice = Math.round((price * (1 + faker.number.float({ min: 0.1, max: 0.5 }))) * 100) / 100;
    const stock = faker.number.int({ min: 0, max: 100 });
    const brand = faker.company.name();
    const tags = faker.helpers.arrayElements(['new', 'sale', 'popular', 'best-seller', 'featured'], 3).join(',');
    
    products.push({
      name,
      slug,
      description: faker.commerce.productDescription(),
      price: price.toFixed(2),
      compareAtPrice: compareAtPrice.toFixed(2),
      costPerItem: (price * 0.6).toFixed(2),
      stock,
      sku: faker.string.alphanumeric(10).toUpperCase(),
      barcode: faker.string.numeric(12),
      weight: (faker.number.float({ min: 0.1, max: 10 })).toFixed(2),
      isActive: true,
      isFeatured: faker.datatype.boolean(0.3),
      categoryId,
      brand,
      tags,
      seoTitle: name,
      seoDescription: faker.commerce.productDescription(),
      createdAt: faker.date.past({ years: 1 }),
      updatedAt: new Date(),
    });
  }
  return products;
}

// Generate variants
function generateVariants(
  productId: string, 
  colorIds: string[], 
  sizeIds: string[], 
  basePrice: number
): VariantInsert[] {
  const variants: VariantInsert[] = [];
  const numColors = faker.number.int({ min: 1, max: Math.min(3, colorIds.length) });
  const numSizes = faker.number.int({ min: 1, max: Math.min(3, sizeIds.length) });
  
  const selectedColors = faker.helpers.arrayElements(colorIds, numColors);
  const selectedSizes = faker.helpers.arrayElements(sizeIds, numSizes);
  
  for (const colorId of selectedColors) {
    for (const sizeId of selectedSizes) {
      const priceAdjustment = faker.number.float({ min: -0.2, max: 0.3 });
      const variantPrice = Math.round((basePrice * (1 + priceAdjustment)) * 100) / 100;
      
      variants.push({
        productId,
        colorId,
        sizeId,
        sku: faker.string.alphanumeric(12).toUpperCase(),
        stock: faker.number.int({ min: 0, max: 50 }),
        price: variantPrice.toFixed(2),
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    }
  }
  return variants;
}

// Generate media
function generateMedia(productId: string, index: number): MediaInsert {
  const imageUrls = [
    'https://images.unsplash.com/photo-1523275335684-37898b6baf30',
    'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
    'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f',
    'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
    'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77',
    'https://images.unsplash.com/photo-1549298916-b41d501d3772',
    'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6',
    'https://images.unsplash.com/photo-1560769629-975ec94e6a86',
  ];
  
  const url = imageUrls[index % imageUrls.length];
  return {
    url: `${url}/600x600`,
    publicId: `product_${productId}_image_${index}`,
    productId,
    isMain: index === 0,
    altText: `Product image ${index + 1}`,
    order: index,
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}

async function seed() {
  let insertedCategories: any[] = [];
  let insertedProducts: any[] = [];
  let allVariants: VariantInsert[] = [];
  let allMedia: MediaInsert[] = [];

  try {
    console.log('🚀 Starting database seeding...');

    // 1. Clear existing data with retry
    console.log('🧹 Clearing existing data...');
    
    await withRetry(async () => {
      await db.delete(schema.mediaAssets);
    }, 2);
    
    await withRetry(async () => {
      await db.delete(schema.productVariants);
    }, 2);
    
    await withRetry(async () => {
      await db.delete(schema.products);
    }, 2);
    
    await withRetry(async () => {
      await db.delete(schema.categories);
    }, 2);
    
    await withRetry(async () => {
      await db.delete(schema.colors);
    }, 2);
    
    await withRetry(async () => {
      await db.delete(schema.sizes);
    }, 2);

    console.log('✅ Data cleared successfully');

    // 2. Insert colors
    console.log('🎨 Inserting colors...');
    const insertedColors = await withRetry(async () => {
      return await db.insert(schema.colors).values(colorData).returning();
    });
    const colorIds = insertedColors.map(c => c.id);
    console.log(`✅ Inserted ${insertedColors.length} colors`);

    // 3. Insert sizes
    console.log('📏 Inserting sizes...');
    const insertedSizes = await withRetry(async () => {
      return await db.insert(schema.sizes).values(sizeData).returning();
    });
    const sizeIds = insertedSizes.map(s => s.id);
    console.log(`✅ Inserted ${insertedSizes.length} sizes`);

    // 4. Insert categories
    console.log('📁 Inserting categories...');
    insertedCategories = await withRetry(async () => {
      return await db.insert(schema.categories).values(categoryData).returning();
    });
    console.log(`✅ Inserted ${insertedCategories.length} categories`);

    // 5. Generate and insert products
    console.log('📦 Generating products...');
    let allProducts: ProductInsert[] = [];
    const productsPerCategory = Math.floor(30 / insertedCategories.length);
    const extraProducts = 30 % insertedCategories.length;

    for (let i = 0; i < insertedCategories.length; i++) {
      const category = insertedCategories[i];
      const count = i < extraProducts ? productsPerCategory + 1 : productsPerCategory;
      const products = generateProductsForCategory(category.id, count);
      allProducts = [...allProducts, ...products];
    }

    // Insert products in batches
    insertedProducts = await withRetry(async () => {
      return await db.insert(schema.products).values(allProducts).returning();
    });
    console.log(`✅ Inserted ${insertedProducts.length} products`);

    // 6. Generate and insert variants
    console.log('🔀 Generating variants...');
    for (const product of insertedProducts) {
      const basePrice = parseFloat(product.price);
      const variants = generateVariants(product.id, colorIds, sizeIds, basePrice);
      allVariants = [...allVariants, ...variants];
    }

    if (allVariants.length > 0) {
      // Insert variants in smaller batches
      const batchSize = 100;
      let insertedVariantCount = 0;
      
      for (let i = 0; i < allVariants.length; i += batchSize) {
        const batch = allVariants.slice(i, i + batchSize);
        const inserted = await withRetry(async () => {
          return await db.insert(schema.productVariants).values(batch).returning();
        }, 3, 1500);
        insertedVariantCount += inserted.length;
        console.log(`   Inserted ${insertedVariantCount}/${allVariants.length} variants`);
      }
      console.log(`✅ Inserted ${insertedVariantCount} variants`);
    }

    // 7. Generate and insert media
    console.log('🖼️ Generating images...');
    for (let i = 0; i < insertedProducts.length; i++) {
      const product = insertedProducts[i];
      const numImages = faker.number.int({ min: 1, max: 3 });
      for (let j = 0; j < numImages; j++) {
        const media = generateMedia(product.id, i * 3 + j);
        allMedia.push(media);
      }
    }

    if (allMedia.length > 0) {
      // Insert media in smaller batches
      const batchSize = 50;
      let insertedMediaCount = 0;
      
      for (let i = 0; i < allMedia.length; i += batchSize) {
        const batch = allMedia.slice(i, i + batchSize);
        await withRetry(async () => {
          await db.insert(schema.mediaAssets).values(batch);
        }, 3, 1500);
        insertedMediaCount += batch.length;
        console.log(`   Inserted ${insertedMediaCount}/${allMedia.length} images`);
      }
      console.log(`✅ Inserted ${insertedMediaCount} media assets`);
    }

    console.log('\n🎉 Seeding completed successfully!');
    console.log(`📊 Summary:`);
    console.log(`   - ${insertedCategories.length} categories`);
    console.log(`   - ${insertedProducts.length} products`);
    console.log(`   - ${allVariants.length} variants`);
    console.log(`   - ${insertedColors.length} colors`);
    console.log(`   - ${insertedSizes.length} sizes`);
    console.log(`   - ${allMedia.length} media assets`);

  } catch (error) {
    console.error('❌ Seeding failed:', error);
    throw error;
  } finally {
    await pool.end().catch(() => {});
  }
}

// Run the seed with error handling
seed().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});