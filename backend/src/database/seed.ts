import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { faqs } from '../drizzle/schema';
import * as dotenv from 'dotenv';

dotenv.config();

const faqData = [
  {
    question: 'How do I create an account?',
    answer:
      'To create an account, download the app and click on "Sign Up". Enter your phone number, verify with OTP, and complete your profile.',
    category: 'General',
    order: 1,
    isActive: true,
  },
  {
    question: 'How do I reset my password?',
    answer:
      'You can reset your password by clicking "Forgot Password" on the login screen. You will receive an OTP to reset your password.',
    category: 'Account',
    order: 2,
    isActive: true,
  },
  {
    question: 'How do I place an order?',
    answer:
      'To place an order, browse products, add items to your cart, proceed to checkout, and confirm your order.',
    category: 'Orders',
    order: 3,
    isActive: true,
  },
  {
    question: 'What payment methods are accepted?',
    answer:
      'We accept cash on delivery and mobile money (EVC Plus, e-Dahab, etc.).',
    category: 'Payments',
    order: 4,
    isActive: true,
  },
  {
    question: 'How can I track my order?',
    answer:
      'You can track your order in the "Orders" section of the app. You will also receive SMS notifications about your order status.',
    category: 'Orders',
    order: 5,
    isActive: true,
  },
  {
    question: 'What is your return policy?',
    answer:
      'We accept returns within 7 days of delivery for defective or incorrect products. Please contact customer support.',
    category: 'Policies',
    order: 6,
    isActive: true,
  },
  {
    question: 'How do I contact customer support?',
    answer:
      'You can contact customer support via the "Help Center" in the app or by calling our support hotline.',
    category: 'Support',
    order: 7,
    isActive: true,
  },
];

async function seedFaqs() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
  });

  const db = drizzle(pool);

  try {
    console.log('🌱 Seeding FAQs...');

    for (const faq of faqData) {
      const result = await db
        .insert(faqs)
        .values({
          id: crypto.randomUUID(),
          question: faq.question,
          answer: faq.answer,
          category: faq.category,
          order: faq.order,
          isActive: faq.isActive,
          createdAt: new Date(),
          updatedAt: new Date(),
        })
        .returning();

      console.log(`✅ Created FAQ: ${faq.question}`);
    }

    console.log('✅ All FAQs seeded successfully!');
  } catch (error) {
    console.error('❌ Error seeding FAQs:', error);
  } finally {
    await pool.end();
  }
}

seedFaqs();
