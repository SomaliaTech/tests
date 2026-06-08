// import { drizzle } from 'drizzle-orm/node-postgres';
// import { Pool } from 'pg';
// import * as dotenv from 'dotenv';
// import { v4 as uuidv4 } from 'uuid';
// import { sql } from 'drizzle-orm';

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
//     console.log('✓ Existing data cleared');

//     // Parent Categories with subcategories structure
//     const parentCategories = [
//       {
//         name: 'Electronics',
//         slug: 'electronics',
//         description: 'Electronic devices, gadgets, and accessories',
//         subcategories: [
//           {
//             name: 'Smartphones',
//             slug: 'smartphones',
//             description: 'Mobile phones and accessories',
//           },
//           {
//             name: 'Laptops & Computers',
//             slug: 'laptops-computers',
//             description: 'Notebooks, desktops, and accessories',
//           },
//           {
//             name: 'Audio & Headphones',
//             slug: 'audio-headphones',
//             description: 'Headphones, speakers, and audio equipment',
//           },
//           {
//             name: 'Cameras & Photography',
//             slug: 'cameras-photography',
//             description: 'Digital cameras, lenses, and accessories',
//           },
//           {
//             name: 'Gaming',
//             slug: 'gaming',
//             description: 'Gaming consoles, accessories, and games',
//           },
//           {
//             name: 'TV & Home Theater',
//             slug: 'tv-home-theater',
//             description: 'Televisions, soundbars, and home theater systems',
//           },
//           {
//             name: 'Wearable Technology',
//             slug: 'wearable-tech',
//             description: 'Smartwatches, fitness trackers, and wearables',
//           },
//         ],
//       },
//       {
//         name: 'Fashion',
//         slug: 'fashion',
//         description: 'Clothing, shoes, and accessories',
//         subcategories: [
//           {
//             name: "Men's Clothing",
//             slug: 'mens-clothing',
//             description: 'Shirts, pants, jackets for men',
//           },
//           {
//             name: "Women's Clothing",
//             slug: 'womens-clothing',
//             description: 'Dresses, tops, skirts for women',
//           },
//           {
//             name: "Kids' Clothing",
//             slug: 'kids-clothing',
//             description: 'Clothing for children',
//           },
//           { name: 'Shoes', slug: 'shoes', description: 'Footwear for all' },
//           {
//             name: 'Accessories',
//             slug: 'accessories',
//             description: 'Bags, watches, belts, and jewelry',
//           },
//           {
//             name: 'Sportswear',
//             slug: 'sportswear',
//             description: 'Activewear and athletic clothing',
//           },
//         ],
//       },
//       {
//         name: 'Home & Living',
//         slug: 'home-living',
//         description: 'Home appliances, kitchenware, and furniture',
//         subcategories: [
//           {
//             name: 'Furniture',
//             slug: 'furniture',
//             description: 'Sofas, tables, chairs, and beds',
//           },
//           {
//             name: 'Kitchen Appliances',
//             slug: 'kitchen-appliances',
//             description: 'Refrigerators, ovens, microwaves',
//           },
//           {
//             name: 'Home Decor',
//             slug: 'home-decor',
//             description: 'Decoration, lighting, and artwork',
//           },
//           {
//             name: 'Bedding & Bath',
//             slug: 'bedding-bath',
//             description: 'Sheets, towels, and bathroom accessories',
//           },
//           {
//             name: 'Garden & Outdoor',
//             slug: 'garden-outdoor',
//             description: 'Patio furniture, gardening tools',
//           },
//           {
//             name: 'Tools & Home Improvement',
//             slug: 'tools-improvement',
//             description: 'Power tools, hardware',
//           },
//         ],
//       },
//       {
//         name: 'Beauty & Personal Care',
//         slug: 'beauty-personal-care',
//         description: 'Cosmetics, skincare, and personal care products',
//         subcategories: [
//           {
//             name: 'Makeup',
//             slug: 'makeup',
//             description: 'Cosmetics and makeup products',
//           },
//           {
//             name: 'Skincare',
//             slug: 'skincare',
//             description: 'Facial care, moisturizers, serums',
//           },
//           {
//             name: 'Hair Care',
//             slug: 'hair-care',
//             description: 'Shampoos, conditioners, styling products',
//           },
//           {
//             name: 'Fragrances',
//             slug: 'fragrances',
//             description: 'Perfumes and colognes',
//           },
//           {
//             name: 'Personal Care',
//             slug: 'personal-care',
//             description: 'Oral care, shaving, deodorants',
//           },
//         ],
//       },
//       {
//         name: 'Sports & Outdoors',
//         slug: 'sports-outdoors',
//         description: 'Sports equipment, outdoor gear, and fitness',
//         subcategories: [
//           {
//             name: 'Exercise & Fitness',
//             slug: 'exercise-fitness',
//             description: 'Equipment, weights, yoga mats',
//           },
//           {
//             name: 'Outdoor Recreation',
//             slug: 'outdoor-recreation',
//             description: 'Camping, hiking, climbing gear',
//           },
//           {
//             name: 'Team Sports',
//             slug: 'team-sports',
//             description: 'Basketball, soccer, football equipment',
//           },
//           {
//             name: 'Cycling',
//             slug: 'cycling',
//             description: 'Bikes, helmets, accessories',
//           },
//         ],
//       },
//       {
//         name: 'Health & Wellness',
//         slug: 'health-wellness',
//         description: 'Vitamins, supplements, and health products',
//         subcategories: [
//           {
//             name: 'Vitamins & Supplements',
//             slug: 'vitamins-supplements',
//             description: 'Dietary supplements and vitamins',
//           },
//           {
//             name: 'Wellness',
//             slug: 'wellness',
//             description: 'Wellness products and self-care',
//           },
//           {
//             name: 'Medical Supplies',
//             slug: 'medical-supplies',
//             description: 'First aid, braces, supports',
//           },
//         ],
//       },
//       {
//         name: 'Books & Media',
//         slug: 'books-media',
//         description: 'Books, magazines, and media',
//         subcategories: [
//           {
//             name: 'Fiction Books',
//             slug: 'fiction-books',
//             description: 'Novels and fiction',
//           },
//           {
//             name: 'Non-Fiction Books',
//             slug: 'nonfiction-books',
//             description: 'Educational and informative books',
//           },
//           { name: 'E-Books', slug: 'ebooks', description: 'Digital books' },
//           {
//             name: 'Audiobooks',
//             slug: 'audiobooks',
//             description: 'Audio books',
//           },
//         ],
//       },
//       {
//         name: 'Toys & Games',
//         slug: 'toys-games',
//         description: 'Toys, games, and hobbies',
//         subcategories: [
//           {
//             name: 'Action Figures',
//             slug: 'action-figures',
//             description: 'Collectible figures',
//           },
//           {
//             name: 'Board Games',
//             slug: 'board-games',
//             description: 'Family and strategy games',
//           },
//           {
//             name: 'Educational Toys',
//             slug: 'educational-toys',
//             description: 'Learning and development toys',
//           },
//           {
//             name: 'Remote Control',
//             slug: 'remote-control',
//             description: 'RC cars, drones, helicopters',
//           },
//         ],
//       },
//     ];

//     const categoriesMap = new Map();

//     // Insert parent categories and subcategories
//     for (const parent of parentCategories) {
//       // Insert parent category
//       const parentId = uuidv4();
//       await db.execute(sql`
//         INSERT INTO categories (id, name, slug, description)
//         VALUES (${parentId}, ${parent.name}, ${parent.slug}, ${parent.description})
//       `);
//       categoriesMap.set(parent.name, parentId);
//       console.log(`✓ Created parent category: ${parent.name}`);

//       // Insert subcategories
//       for (const subcat of parent.subcategories) {
//         const subcatId = uuidv4();
//         await db.execute(sql`
//           INSERT INTO categories (id, name, slug, description, parent_id)
//           VALUES (${subcatId}, ${subcat.name}, ${subcat.slug}, ${subcat.description}, ${parentId})
//         `);
//         categoriesMap.set(subcat.name, subcatId);
//         console.log(`  ✓ Created subcategory: ${subcat.name}`);
//       }
//     }

//     // Colors
//     const colors = [
//       { name: 'Black', code: '#000000' },
//       { name: 'White', code: '#FFFFFF' },
//       { name: 'Red', code: '#FF0000' },
//       { name: 'Blue', code: '#0000FF' },
//       { name: 'Green', code: '#00FF00' },
//       { name: 'Yellow', code: '#FFFF00' },
//       { name: 'Purple', code: '#800080' },
//       { name: 'Orange', code: '#FFA500' },
//       { name: 'Pink', code: '#FFC0CB' },
//       { name: 'Gray', code: '#808080' },
//     ];

//     for (const color of colors) {
//       const colorId = uuidv4();
//       await db.execute(sql`
//         INSERT INTO colors (id, name, code) VALUES (${colorId}, ${color.name}, ${color.code})
//       `);
//     }
//     console.log(`✓ Created ${colors.length} colors`);

//     // Sizes
//     const sizes = [
//       { name: 'Extra Small', value: 'XS' },
//       { name: 'Small', value: 'S' },
//       { name: 'Medium', value: 'M' },
//       { name: 'Large', value: 'L' },
//       { name: 'Extra Large', value: 'XL' },
//       { name: 'XXL', value: 'XXL' },
//     ];

//     for (const size of sizes) {
//       const sizeId = uuidv4();
//       await db.execute(sql`
//         INSERT INTO sizes (id, name, value) VALUES (${sizeId}, ${size.name}, ${size.value})
//       `);
//     }
//     console.log(`✓ Created ${sizes.length} sizes`);

//     // Products data
//     const productsData = [
//       // Electronics - Smartphones
//       {
//         name: 'iPhone 15 Pro Max',
//         slug: 'iphone-15-pro-max',
//         category: 'Smartphones',
//         price: 1199.99,
//         stock: 50,
//         brand: 'Apple',
//         description: 'A17 Pro chip, 256GB, Titanium design',
//         tags: 'apple,iphone,smartphone,5g',
//       },
//       {
//         name: 'Samsung Galaxy S24 Ultra',
//         slug: 'samsung-galaxy-s24-ultra',
//         category: 'Smartphones',
//         price: 1199.99,
//         stock: 45,
//         brand: 'Samsung',
//         description: '256GB, 200MP camera, S Pen included',
//         tags: 'samsung,galaxy,smartphone,android',
//       },
//       {
//         name: 'Google Pixel 8 Pro',
//         slug: 'google-pixel-8-pro',
//         category: 'Smartphones',
//         price: 999.99,
//         stock: 30,
//         brand: 'Google',
//         description: 'AI-powered camera, 128GB',
//         tags: 'google,pixel,smartphone,android',
//       },

//       // Electronics - Laptops
//       {
//         name: 'MacBook Pro 14"',
//         slug: 'macbook-pro-14',
//         category: 'Laptops & Computers',
//         price: 1999.99,
//         stock: 25,
//         brand: 'Apple',
//         description: 'M3 chip, 16GB RAM, 512GB SSD',
//         tags: 'apple,macbook,laptop,pro',
//       },
//       {
//         name: 'Dell XPS 15',
//         slug: 'dell-xps-15',
//         category: 'Laptops & Computers',
//         price: 1799.99,
//         stock: 20,
//         brand: 'Dell',
//         description: 'Intel i7, 32GB RAM, 1TB SSD',
//         tags: 'dell,xps,laptop,windows',
//       },
//       {
//         name: 'LG Gram 17',
//         slug: 'lg-gram-17',
//         category: 'Laptops & Computers',
//         price: 1499.99,
//         stock: 15,
//         brand: 'LG',
//         description: 'Ultra-lightweight, 17" display',
//         tags: 'lg,gram,laptop,lightweight',
//       },

//       // Electronics - Audio
//       {
//         name: 'Sony WH-1000XM5',
//         slug: 'sony-wh1000xm5',
//         category: 'Audio & Headphones',
//         price: 399.99,
//         stock: 45,
//         brand: 'Sony',
//         description: 'Noise-cancelling headphones',
//         tags: 'sony,headphones,noise-cancelling,wireless',
//       },
//       {
//         name: 'Apple AirPods Pro 2',
//         slug: 'airpods-pro-2',
//         category: 'Audio & Headphones',
//         price: 249.99,
//         stock: 60,
//         brand: 'Apple',
//         description: 'Active noise cancellation, spatial audio',
//         tags: 'apple,airpods,earbuds,wireless',
//       },
//       {
//         name: 'Bose QuietComfort',
//         slug: 'bose-quietcomfort',
//         category: 'Audio & Headphones',
//         price: 349.99,
//         stock: 35,
//         brand: 'Bose',
//         description: 'Comfortable noise-cancelling headphones',
//         tags: 'bose,headphones,noise-cancelling',
//       },

//       // Electronics - Gaming
//       {
//         name: 'PlayStation 5',
//         slug: 'ps5',
//         category: 'Gaming',
//         price: 499.99,
//         stock: 50,
//         brand: 'Sony',
//         description: 'Next-gen gaming console',
//         tags: 'sony,playstation,gaming,console',
//       },
//       {
//         name: 'Xbox Series X',
//         slug: 'xbox-series-x',
//         category: 'Gaming',
//         price: 499.99,
//         stock: 45,
//         brand: 'Microsoft',
//         description: '4K gaming console',
//         tags: 'microsoft,xbox,gaming,console',
//       },
//       {
//         name: 'Nintendo Switch OLED',
//         slug: 'nintendo-switch-oled',
//         category: 'Gaming',
//         price: 349.99,
//         stock: 60,
//         brand: 'Nintendo',
//         description: 'Handheld gaming console',
//         tags: 'nintendo,switch,gaming,handheld',
//       },

//       // Electronics - TVs
//       {
//         name: 'Samsung 65" 4K TV',
//         slug: 'samsung-65-4k-tv',
//         category: 'TV & Home Theater',
//         price: 899.99,
//         stock: 15,
//         brand: 'Samsung',
//         description: 'QLED 4K Smart TV',
//         tags: 'samsung,tv,4k,smart-tv',
//       },
//       {
//         name: 'LG OLED 55" TV',
//         slug: 'lg-oled-55',
//         category: 'TV & Home Theater',
//         price: 1299.99,
//         stock: 12,
//         brand: 'LG',
//         description: 'OLED evo 4K Smart TV',
//         tags: 'lg,oled,tv,4k',
//       },

//       // Fashion - Men's Clothing
//       {
//         name: 'Classic Denim Jeans',
//         slug: 'classic-denim-jeans',
//         category: "Men's Clothing",
//         price: 59.99,
//         stock: 120,
//         brand: "Levi's",
//         description: 'Regular fit, blue denim jeans',
//         tags: 'jeans,denim,mens,clothing',
//       },
//       {
//         name: 'Leather Jacket',
//         slug: 'leather-jacket',
//         category: "Men's Clothing",
//         price: 199.99,
//         stock: 40,
//         brand: 'Schott',
//         description: 'Genuine leather jacket',
//         tags: 'jacket,leather,mens,clothing',
//       },

//       // Fashion - Women's Clothing
//       {
//         name: 'Summer Dress',
//         slug: 'summer-dress',
//         category: "Women's Clothing",
//         price: 49.99,
//         stock: 80,
//         brand: 'Zara',
//         description: 'Floral print summer dress',
//         tags: 'dress,womens,summer,clothing',
//       },
//       {
//         name: 'Cashmere Sweater',
//         slug: 'cashmere-sweater',
//         category: "Women's Clothing",
//         price: 129.99,
//         stock: 35,
//         brand: 'Ralph Lauren',
//         description: 'Luxury cashmere sweater',
//         tags: 'sweater,cashmere,womens,clothing',
//       },

//       // Home & Living - Furniture
//       {
//         name: 'Sectional Sofa',
//         slug: 'sectional-sofa',
//         category: 'Furniture',
//         price: 899.99,
//         stock: 10,
//         brand: 'IKEA',
//         description: 'L-shaped sectional sofa',
//         tags: 'sofa,furniture,living-room',
//       },
//       {
//         name: 'Dining Table Set',
//         slug: 'dining-table-set',
//         category: 'Furniture',
//         price: 499.99,
//         stock: 15,
//         brand: 'Ashley',
//         description: '6-person dining table with chairs',
//         tags: 'dining,table,furniture',
//       },

//       // Beauty - Makeup
//       {
//         name: 'Foundation Liquid',
//         slug: 'foundation-liquid',
//         category: 'Makeup',
//         price: 29.99,
//         stock: 150,
//         brand: 'Maybelline',
//         description: 'Long-wear foundation',
//         tags: 'makeup,foundation,cosmetics',
//       },
//       {
//         name: 'Lipstick Set',
//         slug: 'lipstick-set',
//         category: 'Makeup',
//         price: 39.99,
//         stock: 100,
//         brand: 'MAC',
//         description: '5-piece lipstick collection',
//         tags: 'lipstick,makeup,cosmetics',
//       },

//       // Sports - Fitness
//       {
//         name: 'Yoga Mat',
//         slug: 'yoga-mat',
//         category: 'Exercise & Fitness',
//         price: 29.99,
//         stock: 200,
//         brand: 'Lululemon',
//         description: 'Non-slip yoga mat',
//         tags: 'yoga,fitness,exercise',
//       },
//       {
//         name: 'Dumbbell Set',
//         slug: 'dumbbell-set',
//         category: 'Exercise & Fitness',
//         price: 89.99,
//         stock: 50,
//         brand: 'Bowflex',
//         description: 'Adjustable dumbbell set',
//         tags: 'weights,dumbbells,fitness',
//       },

//       // Health - Supplements
//       {
//         name: 'Whey Protein',
//         slug: 'whey-protein',
//         category: 'Vitamins & Supplements',
//         price: 59.99,
//         stock: 120,
//         brand: 'Optimum Nutrition',
//         description: 'Chocolate flavor, 2lb',
//         tags: 'protein,health,supplements',
//       },
//       {
//         name: 'Multivitamin',
//         slug: 'multivitamin',
//         category: 'Vitamins & Supplements',
//         price: 24.99,
//         stock: 200,
//         brand: 'Centrum',
//         description: 'Complete daily nutrition',
//         tags: 'vitamins,health,supplements',
//       },
//     ];

//     // Insert products
//     let productCount = 0;
//     for (const product of productsData) {
//       const categoryId = categoriesMap.get(product.category);
//       if (categoryId) {
//         const productId = uuidv4();
//         await db.execute(sql`
//           INSERT INTO products (id, name, slug, description, price, stock, is_active, category_id, brand, tags, created_at, updated_at)
//           VALUES (${productId}, ${product.name}, ${product.slug}, ${product.description}, ${product.price.toString()}, ${product.stock}, true, ${categoryId}, ${product.brand}, ${product.tags}, NOW(), NOW())
//         `);

//         // Add product images (sample)
//         for (let i = 0; i < 2; i++) {
//           const imageId = uuidv4();
//           await db.execute(sql`
//             INSERT INTO media_assets (id, url, public_id, product_id)
//             VALUES (${imageId}, ${`https://picsum.photos/id/${100 + productCount + i}/800/800`}, ${`product_${productId}_${i}`}, ${productId})
//           `);
//         }

//         productCount++;
//         console.log(
//           `  ✓ Created product: ${product.name} (${product.category})`,
//         );
//       }
//     }

//     console.log(`\n✅ Seed completed successfully!`);
//     console.log(`📊 Statistics:`);
//     console.log(`   - ${parentCategories.length} parent categories created`);
//     console.log(
//       `   - ${categoriesMap.size - parentCategories.length} subcategories created`,
//     );
//     console.log(`   - ${colors.length} colors created`);
//     console.log(`   - ${sizes.length} sizes created`);
//     console.log(`   - ${productCount} products created`);
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
