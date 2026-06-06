import 'package:flutter/material.dart';

class SupportCategory {
  final String id;
  final String title;
  final IconData icon;
  final String description;

  const SupportCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
  });
}

class FAQItem {
  final String id;
  final String question;
  final String answer;
  final String category;

  const FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
  });
}

// Mock Data
const List<SupportCategory> supportCategories = [
  SupportCategory(
    id: '1',
    title: 'Order Issues',
    icon: Icons.shopping_cart_outlined,
    description: 'Track orders, returns, refunds',
  ),
  SupportCategory(
    id: '2',
    title: 'Payment',
    icon: Icons.credit_card_outlined,
    description: 'Payment methods, issues',
  ),
  SupportCategory(
    id: '3',
    title: 'Internet Services',
    icon: Icons.wifi_outlined,
    description: 'Connection, plans, billing',
  ),
  SupportCategory(
    id: '4',
    title: 'Account',
    icon: Icons.person_outline,
    description: 'Profile, settings, security',
  ),
  SupportCategory(
    id: '5',
    title: 'Shipping',
    icon: Icons.local_shipping_outlined,
    description: 'Delivery, tracking, locations',
  ),
  SupportCategory(
    id: '6',
    title: 'Products',
    icon: Icons.inventory_2_outlined,
    description: 'Product info, warranty',
  ),
];

const List<FAQItem> faqs = [
  FAQItem(
    id: '1',
    question: 'How do I track my order?',
    answer:
        'You can track your order by going to Order History in your account and clicking the "Track" button next to your order.',
    category: 'Order Issues',
  ),
  FAQItem(
    id: '2',
    question: 'What payment methods do you accept?',
    answer:
        'We accept credit cards, debit cards, mobile payments (EVC Plus, Zaad), and cash on delivery.',
    category: 'Payment',
  ),
  FAQItem(
    id: '3',
    question: 'How do I return a product?',
    answer:
        'You can return products within 7 days of delivery. Go to Order History, select the order, and click "Request Return".',
    category: 'Order Issues',
  ),
  FAQItem(
    id: '4',
    question: 'How do I activate my internet service?',
    answer:
        'After purchasing an internet plan, our team will contact you within 24 hours to schedule installation.',
    category: 'Internet Services',
  ),
  FAQItem(
    id: '5',
    question: 'What are your delivery hours?',
    answer:
        'We deliver Monday to Saturday, 9:00 AM to 6:00 PM. Sunday deliveries are available for an additional fee.',
    category: 'Shipping',
  ),
];
