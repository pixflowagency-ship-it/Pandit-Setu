import 'dotenv/config';
import { db } from '../db/index.js';
import { poojas } from '../db/schema/poojas.js';
import { products } from '../db/schema/products.js';
import { sql } from 'drizzle-orm';

// Helper to run the seed script
async function seed() {
  // Seed Poojas
  const poojaEntries = [
    { title: 'Satyanarayan Pooja', slug: 'satyanarayan-pooja', description: 'Traditional Satyanarayan ritual', basePrice: '5000', durationMinutes: 120 },
    { title: 'Griha Pravesh', slug: 'griha-pravesh', description: 'Housewarming ceremony', basePrice: '8000', durationMinutes: 180 },
    { title: 'Vastu Shanti', slug: 'vastu-shanti', description: 'Vastu harmony pooja', basePrice: '6000', durationMinutes: 150 },
    { title: 'Navagraha Homa', slug: 'navagraha-homa', description: 'Remedy for planetary influences', basePrice: '7000', durationMinutes: 200 },
    { title: 'Vedic Wedding', slug: 'vedic-wedding', description: 'Traditional Hindu wedding', basePrice: '15000', durationMinutes: 300 },
    { title: 'Daily Nitya Pooja', slug: 'daily-nitya-pooja', description: 'Daily devotional pooja', basePrice: '2000', durationMinutes: 60 },
    { title: 'Ganesh Sthapana', slug: 'ganesh-sthapana', description: 'Installation of Ganesh idol', basePrice: '4000', durationMinutes: 90 },
    { title: 'Lakshmi Puja', slug: 'lakshmi-puja', description: 'Lakshmi worship for prosperity', basePrice: '3500', durationMinutes: 80 },
  ];

  await db.insert(poojas).values(poojaEntries);

  // Seed Products
  const productEntries = [
    {
      name: 'Satyanarayan Pooja Kit',
      description: 'All items required for a Satyanarayan pooja.',
      price: '5000',
      category: 'pooja_kits',
      badge: 'Bestseller',
      samagri: [],
      imageUrl: '',
      isActive: true,
    },
    {
      name: 'Griha Pravesh Essentials',
      description: 'Essential items for a housewarming ceremony.',
      price: '8000',
      category: 'essentials',
      badge: '',
      samagri: [],
      imageUrl: '',
      isActive: true,
    },
    {
      name: 'Vivah Sanskar Bundle',
      description: 'Complete bundle for a Vedic wedding.',
      price: '15000',
      category: 'pooja_kits',
      badge: 'Premium',
      samagri: [],
      imageUrl: '',
      isActive: true,
    },
    {
      name: 'Hawan Samagri Premium',
      description: 'High-quality samagri for various havan rituals.',
      price: '3000',
      category: 'essentials',
      badge: '',
      samagri: [],
      imageUrl: '',
      isActive: true,
    },
  ];

  await db.insert(products).values(productEntries);

  console.log('✅ Seed data inserted successfully');
}

seed().catch((err) => {
  console.error('🚨 Seed failed:', err);
  process.exit(1);
});
