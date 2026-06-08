// const { Pool } = require('pg');
// require('dotenv').config();
// const { v4: uuidv4 } = require('uuid');

// async function seed() {
//   const pool = new Pool({
//     connectionString: process.env.DATABASE_URL,
//     ssl: { rejectUnauthorized: false },
//   });

//   console.log('🌱 Starting database seed...');

//   try {
//     // Clear existing data
//     console.log('Clearing existing data...');
//     await pool.query(`TRUNCATE TABLE order_items CASCADE`);
//     await pool.query(`TRUNCATE TABLE orders CASCADE`);
//     await pool.query(`TRUNCATE TABLE product_variants CASCADE`);
//     await pool.query(`TRUNCATE TABLE media_assets CASCADE`);
//     await pool.query(`TRUNCATE TABLE products CASCADE`);
//     await pool.query(`TRUNCATE TABLE categories CASCADE`);
//     console.log('✓ Existing data cleared');

//     // Categories data
//     const categoriesData = [
//       {
//         name: 'Internet',
//         slug: 'internet',
//         description: 'Internet services, plans, and equipment',
//       },
//       {
//         name: 'Electronics',
//         slug: 'electronics',
//         description: 'Electronic devices, gadgets, and accessories',
//       },
//       {
//         name: 'Home & Kitchen',
//         slug: 'home-kitchen',
//         description: 'Home appliances, kitchenware, and furniture',
//       },
//       {
//         name: 'Cosmetics',
//         slug: 'cosmetics',
//         description: 'Beauty products, makeup, and skincare',
//       },
//       {
//         name: 'Fashion',
//         slug: 'fashion',
//         description: 'Clothing, shoes, and accessories',
//       },
//       {
//         name: 'Jewelry',
//         slug: 'jewelry',
//         description: 'Necklaces, rings, bracelets, and earrings',
//       },
//       {
//         name: 'Children',
//         slug: 'children',
//         description: 'Kids clothing, toys, and baby products',
//       },
//       {
//         name: 'Supplements',
//         slug: 'supplements',
//         description: 'Vitamins, minerals, and health supplements',
//       },
//     ];

//     const categories = {};

//     // Insert categories
//     for (const cat of categoriesData) {
//       const id = uuidv4();
//       await pool.query(
//         `INSERT INTO categories (id, name, slug, description) VALUES ($1, $2, $3, $4)`,
//         [id, cat.name, cat.slug, cat.description],
//       );
//       categories[cat.name] = id;
//       console.log(`✓ Created category: ${cat.name}`);
//     }

//     // Products data
//     const productsData = [
//       // Internet Products
//       {
//         name: 'Fiber Optic Internet - 100 Mbps',
//         slug: 'fiber-100mbps',
//         price: 49.99,
//         stock: 999,
//         description:
//           'High-speed fiber optic internet with 100 Mbps download/upload',
//         category: 'Internet',
//       },
//       {
//         name: 'Fiber Optic Internet - 500 Mbps',
//         slug: 'fiber-500mbps',
//         price: 79.99,
//         stock: 999,
//         description: 'Ultra-fast fiber optic internet with 500 Mbps speed',
//         category: 'Internet',
//       },
//       {
//         name: 'Fiber Optic Internet - 1 Gbps',
//         slug: 'fiber-1gbps',
//         price: 99.99,
//         stock: 999,
//         description: 'Blazing fast 1 Gbps fiber optic internet',
//         category: 'Internet',
//       },
//       {
//         name: 'Wi-Fi 6 Router',
//         slug: 'wifi-6-router',
//         price: 199.99,
//         stock: 50,
//         description: 'Next-gen Wi-Fi 6 router with mesh support',
//         category: 'Internet',
//       },
//       {
//         name: 'Mesh Wi-Fi System (3-pack)',
//         slug: 'mesh-wifi-3pack',
//         price: 299.99,
//         stock: 30,
//         description: 'Whole home mesh Wi-Fi coverage',
//         category: 'Internet',
//       },

//       // Electronics Products (15 products)
//       {
//         name: 'MacBook Pro 14"',
//         slug: 'macbook-pro-14',
//         price: 1999.99,
//         stock: 25,
//         description: 'Apple M3 chip, 16GB RAM, 512GB SSD',
//         category: 'Electronics',
//       },
//       {
//         name: 'Dell XPS 15',
//         slug: 'dell-xps-15',
//         price: 1799.99,
//         stock: 20,
//         description: 'Intel i7, 32GB RAM, 1TB SSD',
//         category: 'Electronics',
//       },
//       {
//         name: 'Sony WH-1000XM5 Headphones',
//         slug: 'sony-wh1000xm5',
//         price: 399.99,
//         stock: 45,
//         description: 'Noise-cancelling wireless headphones',
//         category: 'Electronics',
//       },
//       {
//         name: 'Apple AirPods Pro 2',
//         slug: 'airpods-pro-2',
//         price: 249.99,
//         stock: 60,
//         description: 'Active noise cancellation, spatial audio',
//         category: 'Electronics',
//       },
//       {
//         name: 'Samsung 65" 4K TV',
//         slug: 'samsung-65-4k-tv',
//         price: 899.99,
//         stock: 15,
//         description: 'QLED 4K Smart TV with HDR',
//         category: 'Electronics',
//       },
//       {
//         name: 'LG OLED 55" TV',
//         slug: 'lg-oled-55',
//         price: 1299.99,
//         stock: 12,
//         description: 'OLED evo 4K Smart TV',
//         category: 'Electronics',
//       },
//       {
//         name: 'iPad Pro 12.9"',
//         slug: 'ipad-pro-129',
//         price: 1099.99,
//         stock: 30,
//         description: 'M2 chip, 128GB, Wi-Fi',
//         category: 'Electronics',
//       },
//       {
//         name: 'Samsung Galaxy S24 Ultra',
//         slug: 'galaxy-s24-ultra',
//         price: 1199.99,
//         stock: 40,
//         description: '256GB, Titanium, 200MP camera',
//         category: 'Electronics',
//       },
//       {
//         name: 'iPhone 15 Pro Max',
//         slug: 'iphone-15-pro-max',
//         price: 1199.99,
//         stock: 35,
//         description: '256GB, A17 Pro chip',
//         category: 'Electronics',
//       },
//       {
//         name: 'Google Pixel 8 Pro',
//         slug: 'pixel-8-pro',
//         price: 999.99,
//         stock: 28,
//         description: '128GB, AI-powered camera',
//         category: 'Electronics',
//       },
//       {
//         name: 'Canon EOS R5 Camera',
//         slug: 'canon-eos-r5',
//         price: 3899.99,
//         stock: 8,
//         description: '45MP, 8K video, professional camera',
//         category: 'Electronics',
//       },
//       {
//         name: 'DJI Mini 4 Pro Drone',
//         slug: 'dji-mini-4-pro',
//         price: 759.99,
//         stock: 15,
//         description: '4K HDR video, 34 min flight time',
//         category: 'Electronics',
//       },
//       {
//         name: 'PlayStation 5',
//         slug: 'ps5',
//         price: 499.99,
//         stock: 50,
//         description: 'Next-gen gaming console',
//         category: 'Electronics',
//       },
//       {
//         name: 'Xbox Series X',
//         slug: 'xbox-series-x',
//         price: 499.99,
//         stock: 45,
//         description: '4K gaming console',
//         category: 'Electronics',
//       },
//       {
//         name: 'Nintendo Switch OLED',
//         slug: 'nintendo-switch-oled',
//         price: 349.99,
//         stock: 60,
//         description: 'Handheld gaming console with OLED screen',
//         category: 'Electronics',
//       },

//       // Home & Kitchen Products
//       {
//         name: 'Instant Pot Duo 7-in-1',
//         slug: 'instant-pot-duo',
//         price: 89.99,
//         stock: 75,
//         description: 'Pressure cooker, slow cooker, rice cooker',
//         category: 'Home & Kitchen',
//       },
//       {
//         name: 'Ninja Blender',
//         slug: 'ninja-blender',
//         price: 99.99,
//         stock: 60,
//         description: '1000W professional blender',
//         category: 'Home & Kitchen',
//       },
//       {
//         name: 'Dyson V15 Vacuum',
//         slug: 'dyson-v15',
//         price: 699.99,
//         stock: 20,
//         description: 'Cordless vacuum with laser detection',
//         category: 'Home & Kitchen',
//       },
//       {
//         name: 'Memory Foam Mattress',
//         slug: 'memory-foam-mattress',
//         price: 399.99,
//         stock: 25,
//         description: 'Queen size, gel-infused memory foam',
//         category: 'Home & Kitchen',
//       },
//       {
//         name: 'Air Fryer 5.8QT',
//         slug: 'air-fryer-58qt',
//         price: 119.99,
//         stock: 50,
//         description: 'Digital air fryer with 7 presets',
//         category: 'Home & Kitchen',
//       },

//       // Cosmetics Products
//       {
//         name: 'Foundation Liquid Makeup',
//         slug: 'foundation-liquid',
//         price: 29.99,
//         stock: 150,
//         description: 'Long-wear, full coverage foundation',
//         category: 'Cosmetics',
//       },
//       {
//         name: 'Mascara Volume Express',
//         slug: 'mascara-volume',
//         price: 12.99,
//         stock: 200,
//         description: 'Dramatic volume and length',
//         category: 'Cosmetics',
//       },
//       {
//         name: 'Lipstick Matte Collection',
//         slug: 'lipstick-matte',
//         price: 19.99,
//         stock: 180,
//         description: 'Long-lasting matte lipstick',
//         category: 'Cosmetics',
//       },
//       {
//         name: 'Eyeshadow Palette 12 Colors',
//         slug: 'eyeshadow-palette',
//         price: 39.99,
//         stock: 100,
//         description: 'Neutral and bold shades',
//         category: 'Cosmetics',
//       },
//       {
//         name: 'Skincare Set (5 pcs)',
//         slug: 'skincare-set',
//         price: 59.99,
//         stock: 80,
//         description: 'Cleanser, toner, serum, moisturizer, sunscreen',
//         category: 'Cosmetics',
//       },

//       // Fashion Products
//       {
//         name: 'Classic Denim Jeans',
//         slug: 'classic-denim-jeans',
//         price: 59.99,
//         stock: 120,
//         description: 'Regular fit, blue denim jeans',
//         category: 'Fashion',
//       },
//       {
//         name: 'Cotton T-Shirt (Pack of 3)',
//         slug: 'cotton-tshirt-pack',
//         price: 29.99,
//         stock: 200,
//         description: '100% cotton, various colors',
//         category: 'Fashion',
//       },
//       {
//         name: 'Leather Jacket',
//         slug: 'leather-jacket',
//         price: 199.99,
//         stock: 40,
//         description: 'Genuine leather, classic biker style',
//         category: 'Fashion',
//       },
//       {
//         name: 'Running Shoes',
//         slug: 'running-shoes',
//         price: 89.99,
//         stock: 85,
//         description: 'Lightweight, cushioned running shoes',
//         category: 'Fashion',
//       },
//       {
//         name: 'Winter Coat',
//         slug: 'winter-coat',
//         price: 149.99,
//         stock: 55,
//         description: 'Warm insulated winter parka',
//         category: 'Fashion',
//       },

//       // Jewelry Products
//       {
//         name: 'Gold Necklace',
//         slug: 'gold-necklace',
//         price: 299.99,
//         stock: 30,
//         description: '14k gold, 18" chain',
//         category: 'Jewelry',
//       },
//       {
//         name: 'Diamond Engagement Ring',
//         slug: 'diamond-ring',
//         price: 1999.99,
//         stock: 10,
//         description: '0.5 carat diamond, 14k white gold',
//         category: 'Jewelry',
//       },
//       {
//         name: 'Silver Earrings',
//         slug: 'silver-earrings',
//         price: 49.99,
//         stock: 75,
//         description: '925 sterling silver, cubic zirconia',
//         category: 'Jewelry',
//       },
//       {
//         name: 'Leather Bracelet',
//         slug: 'leather-bracelet',
//         price: 29.99,
//         stock: 100,
//         description: 'Braided leather with magnetic clasp',
//         category: 'Jewelry',
//       },
//       {
//         name: 'Pearl Necklace',
//         slug: 'pearl-necklace',
//         price: 149.99,
//         stock: 25,
//         description: 'Freshwater pearls, 16" length',
//         category: 'Jewelry',
//       },

//       // Children Products
//       {
//         name: 'Baby Onesie (Pack of 5)',
//         slug: 'baby-onesie',
//         price: 24.99,
//         stock: 150,
//         description: '100% cotton, newborn size',
//         category: 'Children',
//       },
//       {
//         name: 'LEGO Classic Set',
//         slug: 'lego-classic',
//         price: 39.99,
//         stock: 90,
//         description: '500 pieces, creative building set',
//         category: 'Children',
//       },
//       {
//         name: 'Kids Tablet',
//         slug: 'kids-tablet',
//         price: 99.99,
//         stock: 60,
//         description: '7" screen, parental controls, kids case',
//         category: 'Children',
//       },
//       {
//         name: 'Stroller',
//         slug: 'stroller',
//         price: 199.99,
//         stock: 25,
//         description: 'Lightweight, foldable baby stroller',
//         category: 'Children',
//       },
//       {
//         name: 'Educational Toys Set',
//         slug: 'educational-toys',
//         price: 49.99,
//         stock: 80,
//         description: 'ABC blocks, numbers, shapes',
//         category: 'Children',
//       },

//       // Supplements Products
//       {
//         name: 'Vitamin D3 1000 IU',
//         slug: 'vitamin-d3',
//         price: 19.99,
//         stock: 200,
//         description: 'Bone health and immune support',
//         category: 'Supplements',
//       },
//       {
//         name: 'Omega-3 Fish Oil',
//         slug: 'omega-3',
//         price: 29.99,
//         stock: 180,
//         description: 'Heart and brain health supplement',
//         category: 'Supplements',
//       },
//       {
//         name: 'Whey Protein Powder',
//         slug: 'whey-protein',
//         price: 59.99,
//         stock: 120,
//         description: 'Chocolate flavor, 2lb container',
//         category: 'Supplements',
//       },
//       {
//         name: 'Multivitamin for Men',
//         slug: 'multivitamin-men',
//         price: 24.99,
//         stock: 150,
//         description: 'Complete daily nutrition',
//         category: 'Supplements',
//       },
//       {
//         name: 'Probiotic 50 Billion CFU',
//         slug: 'probiotic',
//         price: 34.99,
//         stock: 100,
//         description: 'Digestive health support',
//         category: 'Supplements',
//       },
//     ];

//     // Insert products
//     let productCount = 0;
//     for (const product of productsData) {
//       const categoryId = categories[product.category];
//       if (categoryId) {
//         const productId = uuidv4();
//         await pool.query(
//           `INSERT INTO products (id, name, slug, description, price, stock, is_active, category_id)
//            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
//           [
//             productId,
//             product.name,
//             product.slug,
//             product.description,
//             product.price.toString(),
//             product.stock,
//             true,
//             categoryId,
//           ],
//         );
//         productCount++;
//         console.log(
//           `  ✓ Created product: ${product.name} (${product.category})`,
//         );
//       }
//     }

//     console.log(`\n✅ Seed completed successfully!`);
//     console.log(`📊 Statistics:`);
//     console.log(`   - ${Object.keys(categories).length} categories created`);
//     console.log(`   - ${productCount} products created`);
//   } catch (error) {
//     console.error('❌ Seed failed:', error);
//   } finally {
//     await pool.end();
//   }
// }

// seed();
