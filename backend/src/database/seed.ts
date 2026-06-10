import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as dotenv from 'dotenv';
import { v4 as uuidv4 } from 'uuid';
import { sql } from 'drizzle-orm';

dotenv.config();

async function seed() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });

  const db = drizzle(pool);

  console.log('🌱 Starting database seed...');

  try {
    // Clear existing data
    console.log('Clearing existing data...');
    await db.execute(sql`TRUNCATE TABLE order_items CASCADE`);
    await db.execute(sql`TRUNCATE TABLE orders CASCADE`);
    await db.execute(sql`TRUNCATE TABLE product_variants CASCADE`);
    await db.execute(sql`TRUNCATE TABLE media_assets CASCADE`);
    await db.execute(sql`TRUNCATE TABLE products CASCADE`);
    await db.execute(sql`TRUNCATE TABLE categories CASCADE`);
    await db.execute(sql`TRUNCATE TABLE colors CASCADE`);
    await db.execute(sql`TRUNCATE TABLE sizes CASCADE`);
    console.log('✓ Existing data cleared');

    // ==========================================
    // Multi-Level Categories Structure
    // ==========================================
    const categoryHierarchy = [
      {
        name: 'Electronics',
        slug: 'electronics',
        description: 'Electronic devices, gadgets, and accessories',
        children: [
          {
            name: 'Computers',
            slug: 'computers',
            description: 'Computers and accessories',
            children: [
              {
                name: 'Laptops',
                slug: 'laptops',
                description: 'Notebook computers',
              },
              {
                name: 'Desktop PCs',
                slug: 'desktop-pcs',
                description: 'Desktop computers',
              },
              {
                name: 'Monitors',
                slug: 'monitors',
                description: 'Computer monitors',
              },
              {
                name: 'Computer Components',
                slug: 'computer-components',
                description: 'PC parts and components',
              },
            ],
          },
          {
            name: 'Smartphones',
            slug: 'smartphones',
            description: 'Mobile phones and accessories',
            children: [
              {
                name: 'Android Phones',
                slug: 'android-phones',
                description: 'Android smartphones',
              },
              {
                name: 'iPhones',
                slug: 'iphones',
                description: 'Apple iPhones',
              },
              {
                name: 'Phone Accessories',
                slug: 'phone-accessories',
                description: 'Cases, chargers, etc.',
              },
            ],
          },
          {
            name: 'Gaming',
            slug: 'gaming',
            description: 'Gaming consoles and accessories',
            children: [
              {
                name: 'Consoles',
                slug: 'consoles',
                description: 'PlayStation, Xbox, Nintendo',
              },
              {
                name: 'Gaming PCs',
                slug: 'gaming-pcs',
                description: 'Pre-built gaming computers',
              },
              {
                name: 'Video Games',
                slug: 'video-games',
                description: 'Video games',
              },
              {
                name: 'Gaming Accessories',
                slug: 'gaming-accessories',
                description: 'Controllers, headsets, etc.',
              },
            ],
          },
          {
            name: 'Audio',
            slug: 'audio',
            description: 'Audio equipment',
            children: [
              {
                name: 'Headphones',
                slug: 'headphones',
                description: 'Over-ear headphones',
              },
              {
                name: 'Earbuds',
                slug: 'earbuds',
                description: 'Wireless earbuds',
              },
              {
                name: 'Speakers',
                slug: 'speakers',
                description: 'Bluetooth and home speakers',
              },
            ],
          },
          {
            name: 'Wearable Technology',
            slug: 'wearable-tech',
            description: 'Smartwatches and fitness trackers',
            children: [],
          },
          {
            name: 'Cameras & Photography',
            slug: 'cameras-photography',
            description: 'Digital cameras and lenses',
            children: [],
          },
          {
            name: 'TV & Home Theater',
            slug: 'tv-home-theater',
            description: 'Televisions and sound systems',
            children: [],
          },
        ],
      },
      {
        name: 'Fashion',
        slug: 'fashion',
        description: 'Clothing, shoes, and accessories',
        children: [
          {
            name: 'Men',
            slug: 'men',
            description: "Men's clothing",
            children: [
              {
                name: "Men's Shirts",
                slug: 'mens-shirts',
                description: "Men's shirts",
              },
              {
                name: "Men's Pants",
                slug: 'mens-pants',
                description: "Men's pants",
              },
              {
                name: "Men's Shoes",
                slug: 'mens-shoes',
                description: "Men's footwear",
              },
            ],
          },
          {
            name: 'Women',
            slug: 'women',
            description: "Women's clothing",
            children: [
              {
                name: "Women's Dresses",
                slug: 'womens-dresses',
                description: "Women's dresses",
              },
              {
                name: "Women's Shoes",
                slug: 'womens-shoes',
                description: "Women's footwear",
              },
              {
                name: "Women's Bags",
                slug: 'womens-bags',
                description: 'Handbags and purses',
              },
            ],
          },
          {
            name: 'Kids',
            slug: 'kids',
            description: "Children's clothing",
            children: [
              {
                name: "Boys' Clothing",
                slug: 'boys-clothing',
                description: "Boys' clothing",
              },
              {
                name: "Girls' Clothing",
                slug: 'girls-clothing',
                description: "Girls' clothing",
              },
            ],
          },
          {
            name: 'Accessories',
            slug: 'accessories',
            description: 'Fashion accessories',
            children: [
              {
                name: 'Watches',
                slug: 'watches',
                description: 'Wrist watches',
              },
              {
                name: 'Jewelry',
                slug: 'jewelry',
                description: 'Necklaces, rings, etc.',
              },
              { name: 'Belts', slug: 'belts', description: 'Leather belts' },
            ],
          },
          {
            name: 'Sportswear',
            slug: 'sportswear',
            description: 'Activewear and athletic clothing',
            children: [],
          },
        ],
      },
      {
        name: 'Home & Living',
        slug: 'home-living',
        description: 'Home appliances, kitchenware, and furniture',
        children: [
          {
            name: 'Furniture',
            slug: 'furniture',
            description: 'Home furniture',
            children: [
              {
                name: 'Sofas',
                slug: 'sofas',
                description: 'Living room sofas',
              },
              { name: 'Beds', slug: 'beds', description: 'Bedroom beds' },
              {
                name: 'Dining Tables',
                slug: 'dining-tables',
                description: 'Dining room tables',
              },
            ],
          },
          {
            name: 'Kitchen',
            slug: 'kitchen',
            description: 'Kitchen appliances and tools',
            children: [
              {
                name: 'Cookware',
                slug: 'cookware',
                description: 'Pots and pans',
              },
              {
                name: 'Kitchen Appliances',
                slug: 'kitchen-appliances',
                description: 'Microwaves, blenders, etc.',
              },
            ],
          },
          {
            name: 'Home Decor',
            slug: 'home-decor',
            description: 'Decoration items',
            children: [],
          },
          {
            name: 'Bedding & Bath',
            slug: 'bedding-bath',
            description: 'Bed sheets and bathroom accessories',
            children: [],
          },
          {
            name: 'Garden & Outdoor',
            slug: 'garden-outdoor',
            description: 'Outdoor furniture and gardening',
            children: [],
          },
          {
            name: 'Tools & Improvement',
            slug: 'tools-improvement',
            description: 'Power tools and hardware',
            children: [],
          },
        ],
      },
      {
        name: 'Beauty & Personal Care',
        slug: 'beauty-personal-care',
        description: 'Cosmetics, skincare, and personal care products',
        children: [
          {
            name: 'Skincare',
            slug: 'skincare',
            description: 'Facial care products',
            children: [],
          },
          {
            name: 'Hair Care',
            slug: 'hair-care',
            description: 'Shampoos and conditioners',
            children: [],
          },
          {
            name: 'Makeup',
            slug: 'makeup',
            description: 'Cosmetics',
            children: [],
          },
          {
            name: 'Fragrances',
            slug: 'fragrances',
            description: 'Perfumes and colognes',
            children: [],
          },
        ],
      },
      {
        name: 'Sports & Outdoors',
        slug: 'sports-outdoors',
        description: 'Sports equipment, outdoor gear, and fitness',
        children: [
          {
            name: 'Fitness',
            slug: 'fitness',
            description: 'Exercise equipment',
            children: [
              {
                name: 'Cardio Equipment',
                slug: 'cardio-equipment',
                description: 'Treadmills, bikes, etc.',
              },
              {
                name: 'Strength Training',
                slug: 'strength-training',
                description: 'Weights and resistance',
              },
            ],
          },
          {
            name: 'Cycling',
            slug: 'cycling',
            description: 'Bikes and accessories',
            children: [],
          },
          {
            name: 'Football',
            slug: 'football',
            description: 'Soccer equipment',
            children: [],
          },
          {
            name: 'Basketball',
            slug: 'basketball',
            description: 'Basketball equipment',
            children: [],
          },
          {
            name: 'Camping & Hiking',
            slug: 'camping-hiking',
            description: 'Outdoor gear',
            children: [],
          },
        ],
      },
      {
        name: 'Health & Wellness',
        slug: 'health-wellness',
        description: 'Vitamins, supplements, and health products',
        children: [
          {
            name: 'Vitamins & Supplements',
            slug: 'vitamins-supplements',
            description: 'Dietary supplements',
            children: [],
          },
          {
            name: 'Wellness',
            slug: 'wellness',
            description: 'Wellness products',
            children: [],
          },
          {
            name: 'Medical Supplies',
            slug: 'medical-supplies',
            description: 'First aid and medical equipment',
            children: [],
          },
        ],
      },
      {
        name: 'Books & Media',
        slug: 'books-media',
        description: 'Books, magazines, and media',
        children: [
          {
            name: 'Fiction Books',
            slug: 'fiction-books',
            description: 'Novels and fiction',
            children: [],
          },
          {
            name: 'Non-Fiction Books',
            slug: 'nonfiction-books',
            description: 'Educational books',
            children: [],
          },
          {
            name: 'E-Books',
            slug: 'ebooks',
            description: 'Digital books',
            children: [],
          },
          {
            name: 'Audiobooks',
            slug: 'audiobooks',
            description: 'Audio books',
            children: [],
          },
        ],
      },
      {
        name: 'Toys & Games',
        slug: 'toys-games',
        description: 'Toys, games, and hobbies',
        children: [
          {
            name: 'Action Figures',
            slug: 'action-figures',
            description: 'Collectible figures',
            children: [],
          },
          {
            name: 'Board Games',
            slug: 'board-games',
            description: 'Strategy games',
            children: [],
          },
          {
            name: 'Educational Toys',
            slug: 'educational-toys',
            description: 'Learning toys',
            children: [],
          },
          {
            name: 'RC Toys',
            slug: 'rc-toys',
            description: 'RC cars and drones',
            children: [],
          },
        ],
      },
    ];

    const categoriesMap = new Map();

    // Recursive function to insert categories
    async function insertCategory(
      category: any,
      parentId: string | null,
      level: number = 0,
    ) {
      const categoryId = uuidv4();
      await db.execute(sql`
        INSERT INTO categories (id, name, slug, description, parent_id)
        VALUES (${categoryId}, ${category.name}, ${category.slug}, ${category.description}, ${parentId})
      `);
      categoriesMap.set(category.slug, categoryId);

      const indent = '  '.repeat(level);
      console.log(`${indent}✓ Created: ${category.name}`);

      // Insert children
      if (category.children && category.children.length > 0) {
        for (const child of category.children) {
          await insertCategory(child, categoryId, level + 1);
        }
      }
    }

    // Insert all top-level categories
    for (const category of categoryHierarchy) {
      await insertCategory(category, null, 0);
    }

    // Colors
    const colors = [
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
    ];

    for (const color of colors) {
      const colorId = uuidv4();
      await db.execute(sql`
        INSERT INTO colors (id, name, code) VALUES (${colorId}, ${color.name}, ${color.code})
      `);
    }
    console.log(`\n✓ Created ${colors.length} colors`);

    // Sizes
    const sizes = [
      { name: 'Extra Small', value: 'XS' },
      { name: 'Small', value: 'S' },
      { name: 'Medium', value: 'M' },
      { name: 'Large', value: 'L' },
      { name: 'Extra Large', value: 'XL' },
      { name: 'XXL', value: 'XXL' },
    ];

    for (const size of sizes) {
      const sizeId = uuidv4();
      await db.execute(sql`
        INSERT INTO sizes (id, name, value) VALUES (${sizeId}, ${size.name}, ${size.value})
      `);
    }
    console.log(`✓ Created ${sizes.length} sizes`);

    // Products data
    const categorySlugToId = (slug: string) => categoriesMap.get(slug);

    const productsData = [
      // Laptops
      {
        name: 'MacBook Pro 14"',
        slug: 'macbook-pro-14',
        categorySlug: 'laptops',
        price: 1999.99,
        stock: 25,
        brand: 'Apple',
        description: 'M3 chip, 16GB RAM, 512GB SSD',
        tags: 'apple,macbook,laptop',
      },
      {
        name: 'Dell XPS 15',
        slug: 'dell-xps-15',
        categorySlug: 'laptops',
        price: 1799.99,
        stock: 20,
        brand: 'Dell',
        description: 'Intel i7, 32GB RAM, 1TB SSD',
        tags: 'dell,xps,laptop',
      },
      {
        name: 'LG Gram 17',
        slug: 'lg-gram-17',
        categorySlug: 'laptops',
        price: 1499.99,
        stock: 15,
        brand: 'LG',
        description: 'Ultra-lightweight, 17" display',
        tags: 'lg,gram,laptop',
      },

      // Desktop PCs
      {
        name: 'Gaming Desktop RTX 4080',
        slug: 'gaming-desktop-4080',
        categorySlug: 'desktop-pcs',
        price: 2499.99,
        stock: 10,
        brand: 'Alienware',
        description: 'RTX 4080, i9, 32GB RAM',
        tags: 'gaming,desktop',
      },
      {
        name: 'HP All-in-One',
        slug: 'hp-all-in-one',
        categorySlug: 'desktop-pcs',
        price: 899.99,
        stock: 15,
        brand: 'HP',
        description: '23.8" display, AMD Ryzen 5',
        tags: 'hp,aio,desktop',
      },

      // Monitors
      {
        name: 'Samsung 32" 4K Monitor',
        slug: 'samsung-32-4k',
        categorySlug: 'monitors',
        price: 499.99,
        stock: 20,
        brand: 'Samsung',
        description: '4K UHD, 60Hz, HDR10',
        tags: 'samsung,monitor,4k',
      },
      {
        name: 'LG UltraWide 34"',
        slug: 'lg-ultrawide-34',
        categorySlug: 'monitors',
        price: 699.99,
        stock: 12,
        brand: 'LG',
        description: 'Curved gaming monitor',
        tags: 'lg,ultrawide,monitor',
      },

      // Android Phones
      {
        name: 'Samsung Galaxy S24 Ultra',
        slug: 'galaxy-s24-ultra',
        categorySlug: 'android-phones',
        price: 1199.99,
        stock: 40,
        brand: 'Samsung',
        description: '256GB, 200MP camera',
        tags: 'samsung,android',
      },
      {
        name: 'Google Pixel 8 Pro',
        slug: 'pixel-8-pro',
        categorySlug: 'android-phones',
        price: 999.99,
        stock: 28,
        brand: 'Google',
        description: 'AI-powered camera',
        tags: 'google,pixel',
      },
      {
        name: 'OnePlus 12',
        slug: 'oneplus-12',
        categorySlug: 'android-phones',
        price: 799.99,
        stock: 35,
        brand: 'OnePlus',
        description: 'Snapdragon 8 Gen 3',
        tags: 'oneplus,android',
      },

      // iPhones
      {
        name: 'iPhone 15 Pro Max',
        slug: 'iphone-15-pro-max',
        categorySlug: 'iphones',
        price: 1199.99,
        stock: 50,
        brand: 'Apple',
        description: 'A17 Pro chip, 256GB',
        tags: 'apple,iphone',
      },
      {
        name: 'iPhone 15 Pro',
        slug: 'iphone-15-pro',
        categorySlug: 'iphones',
        price: 999.99,
        stock: 45,
        brand: 'Apple',
        description: 'A17 Pro chip, 128GB',
        tags: 'apple,iphone',
      },

      // Headphones
      {
        name: 'Sony WH-1000XM5',
        slug: 'sony-wh1000xm5',
        categorySlug: 'headphones',
        price: 399.99,
        stock: 45,
        brand: 'Sony',
        description: 'Noise-cancelling headphones',
        tags: 'sony,headphones',
      },
      {
        name: 'Apple AirPods Max',
        slug: 'airpods-max',
        categorySlug: 'headphones',
        price: 549.99,
        stock: 25,
        brand: 'Apple',
        description: 'Premium over-ear headphones',
        tags: 'apple,airpods',
      },
      {
        name: 'Bose QC45',
        slug: 'bose-qc45',
        categorySlug: 'headphones',
        price: 329.99,
        stock: 30,
        brand: 'Bose',
        description: 'QuietComfort 45',
        tags: 'bose,headphones',
      },

      // Gaming Consoles
      {
        name: 'PlayStation 5',
        slug: 'ps5',
        categorySlug: 'consoles',
        price: 499.99,
        stock: 50,
        brand: 'Sony',
        description: 'Next-gen gaming console',
        tags: 'sony,playstation',
      },
      {
        name: 'Xbox Series X',
        slug: 'xbox-series-x',
        categorySlug: 'consoles',
        price: 499.99,
        stock: 45,
        brand: 'Microsoft',
        description: '4K gaming console',
        tags: 'microsoft,xbox',
      },
      {
        name: 'Nintendo Switch OLED',
        slug: 'nintendo-switch-oled',
        categorySlug: 'consoles',
        price: 349.99,
        stock: 60,
        brand: 'Nintendo',
        description: 'Handheld gaming console',
        tags: 'nintendo,switch',
      },

      // Men's Clothing
      {
        name: 'Classic Denim Jeans',
        slug: 'classic-denim-jeans',
        categorySlug: 'mens-pants',
        price: 59.99,
        stock: 120,
        brand: "Levi's",
        description: 'Regular fit jeans',
        tags: 'jeans,denim',
      },
      {
        name: 'Cotton Oxford Shirt',
        slug: 'cotton-oxford-shirt',
        categorySlug: 'mens-shirts',
        price: 49.99,
        stock: 100,
        brand: 'Ralph Lauren',
        description: 'Classic fit oxford',
        tags: 'shirt,oxford',
      },
      {
        name: 'Leather Jacket',
        slug: 'leather-jacket',
        categorySlug: 'mens-shoes',
        price: 199.99,
        stock: 40,
        brand: 'Schott',
        description: 'Genuine leather',
        tags: 'jacket,leather',
      },

      // Women's Clothing
      {
        name: 'Floral Summer Dress',
        slug: 'floral-summer-dress',
        categorySlug: 'womens-dresses',
        price: 49.99,
        stock: 80,
        brand: 'Zara',
        description: 'Floral print dress',
        tags: 'dress,summer',
      },
      {
        name: 'Designer Handbag',
        slug: 'designer-handbag',
        categorySlug: 'womens-bags',
        price: 299.99,
        stock: 25,
        brand: 'Coach',
        description: 'Leather handbag',
        tags: 'bag,designer',
      },
      {
        name: 'Running Shoes',
        slug: 'womens-running-shoes',
        categorySlug: 'womens-shoes',
        price: 89.99,
        stock: 60,
        brand: 'Nike',
        description: 'Lightweight running shoes',
        tags: 'shoes,nike',
      },

      // Furniture
      {
        name: 'Sectional Sofa',
        slug: 'sectional-sofa',
        categorySlug: 'sofas',
        price: 899.99,
        stock: 10,
        brand: 'IKEA',
        description: 'L-shaped sectional',
        tags: 'sofa,furniture',
      },
      {
        name: 'Queen Memory Foam Bed',
        slug: 'queen-memory-foam-bed',
        categorySlug: 'beds',
        price: 599.99,
        stock: 15,
        brand: 'Zinus',
        description: 'Memory foam mattress',
        tags: 'bed,mattress',
      },

      // Fitness
      {
        name: 'Yoga Mat',
        slug: 'yoga-mat',
        categorySlug: 'fitness',
        price: 29.99,
        stock: 200,
        brand: 'Lululemon',
        description: 'Non-slip yoga mat',
        tags: 'yoga,fitness',
      },
      {
        name: 'Adjustable Dumbbells',
        slug: 'adjustable-dumbbells',
        categorySlug: 'strength-training',
        price: 299.99,
        stock: 30,
        brand: 'Bowflex',
        description: '552 lbs set',
        tags: 'weights,dumbbells',
      },

      // Supplements
      {
        name: 'Whey Protein',
        slug: 'whey-protein',
        categorySlug: 'vitamins-supplements',
        price: 59.99,
        stock: 120,
        brand: 'Optimum Nutrition',
        description: 'Chocolate flavor, 2lb',
        tags: 'protein,health',
      },
      {
        name: 'Multivitamin',
        slug: 'multivitamin',
        categorySlug: 'vitamins-supplements',
        price: 24.99,
        stock: 200,
        brand: 'Centrum',
        description: 'Complete daily nutrition',
        tags: 'vitamins,health',
      },
    ];

    // Insert products
    let productCount = 0;
    for (const product of productsData) {
      const categoryId = categorySlugToId(product.categorySlug);
      if (categoryId) {
        const productId = uuidv4();
        await db.execute(sql`
          INSERT INTO products (id, name, slug, description, price, stock, is_active, category_id, brand, tags, created_at, updated_at)
          VALUES (${productId}, ${product.name}, ${product.slug}, ${product.description}, ${product.price.toString()}, ${product.stock}, true, ${categoryId}, ${product.brand}, ${product.tags}, NOW(), NOW())
        `);

        // Add product images
        for (let i = 0; i < 2; i++) {
          const imageId = uuidv4();
          await db.execute(sql`
            INSERT INTO media_assets (id, url, public_id, product_id)
            VALUES (${imageId}, ${`https://picsum.photos/id/${100 + productCount + i}/800/800`}, ${`product_${productId}_${i}`}, ${productId})
          `);
        }

        productCount++;
        console.log(`  ✓ Created product: ${product.name}`);
      }
    }

    console.log(`\n✅ Seed completed successfully!`);
    console.log(`📊 Statistics:`);
    console.log(`   - ${categoriesMap.size} categories created (multi-level)`);
    console.log(`   - ${colors.length} colors created`);
    console.log(`   - ${sizes.length} sizes created`);
    console.log(`   - ${productCount} products created`);
  } catch (error) {
    console.error('❌ Seed failed:', error);
  } finally {
    await pool.end();
  }
}

seed().catch((error) => {
  console.error('❌ Seed failed:', error);
  process.exit(1);
});
// Add to your seed.ts
// import { drizzle } from 'drizzle-orm/node-postgres';
// import { Pool } from 'pg';
// import * as dotenv from 'dotenv';
// import { v4 as uuidv4 } from 'uuid';

// dotenv.config();

// async function seed() {
//   const pool = new Pool({
//     connectionString: process.env.DATABASE_URL,
//     ssl: { rejectUnauthorized: false },
//   });

//   const db = drizzle(pool);

//   console.log('🌱 Starting database seed...');

//   try {
//     // Clear existing data
//     console.log('Clearing existing data...');
//     await db.execute(sql`TRUNCATE TABLE order_items CASCADE`);
//     await db.execute(sql`TRUNCATE TABLE orders CASCADE`);
//     await db.execute(sql`TRUNCATE TABLE product_variants CASCADE`);
//     await db.execute(sql`TRUNCATE TABLE media_assets CASCADE`);
//     await db.execute(sql`TRUNCATE TABLE products CASCADE`);
//     await db.execute(sql`TRUNCATE TABLE categories CASCADE`);
//     await db.execute(sql`TRUNCATE TABLE colors CASCADE`);
//     await db.execute(sql`TRUNCATE TABLE sizes CASCADE`);
//     await db.execute(sql`TRUNCATE TABLE markets CASCADE`);
//     await db.execute(sql`TRUNCATE TABLE users CASCADE`);
//     console.log('✓ Existing data cleared');

//     // ==========================================
//     // Insert Markets
//     // ==========================================
//     console.log('🌍 Inserting markets...');
//     const marketsData = [
//       { name: 'Mogadishu', slug: 'mogadishu', city: 'Mogadishu' },
//       { name: 'Hargeisa', slug: 'hargeisa', city: 'Hargeisa' },
//       { name: 'Jowhar', slug: 'jowhar', city: 'Jowhar' },
//       { name: 'Kismayo', slug: 'kismayo', city: 'Kismayo' },
//       { name: 'Baidoa', slug: 'baidoa', city: 'Baidoa' },
//       { name: 'Garowe', slug: 'garowe', city: 'Garowe' },
//     ];

//     for (const market of marketsData) {
//       const marketId = uuidv4();
//       await db.execute(sql`
//         INSERT INTO markets (id, name, slug, city, is_active)
//         VALUES (${marketId}, ${market.name}, ${market.slug}, ${market.city}, true)
//       `);
//       console.log(`  ✓ Created market: ${market.name}`);
//     }

//     // ==========================================
//     // Multi-Level Categories Structure
//     // ==========================================
//     // ... rest of your categories code ...

//     // ==========================================
//     // Colors
//     // ==========================================
//     // ... rest of your colors code ...

//     // ==========================================
//     // Sizes
//     // ==========================================
//     // ... rest of your sizes code ...

//     // ==========================================
//     // Products
//     // ==========================================
//     // ... rest of your products code ...

//     console.log(`\n✅ Seed completed successfully!`);
//     console.log(`📊 Statistics:`);
//     console.log(`   - ${marketsData.length} markets created`);
//   } catch (error) {
//     console.error('❌ Seed failed:', error);
//   } finally {
//     await pool.end();
//   }
// }

// seed().catch((error) => {
//   console.error('❌ Seed failed:', error);
//   process.exit(1);
// });
