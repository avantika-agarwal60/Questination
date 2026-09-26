require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const demoArtisans = [
  { email: 'artisan1@demo.com', shop_name: 'Rahim Chikankari Works', craft: 'Lucknow Chikankari', description: 'Hand-embroidered Chikankari garments and dupattas', city: 'Lucknow' },
  { email: 'artisan2@demo.com', shop_name: 'Shalini Zardozi House', craft: 'Zari Zardozi', description: 'Traditional gold-thread embroidery work', city: 'Lucknow' },
];

async function main() {
  for (const artisan of demoArtisans) {
    let city = await prisma.cities.findFirst({ where: { name: artisan.city } });
    if (!city) {
      city = await prisma.cities.create({
        data: { name: artisan.city, level_thresholds: [100, 300, 600, 1000], max_level: 5 },
      });
    }

    let user = await prisma.users.findFirst({ where: { email: artisan.email } });
    if (!user) {
      user = await prisma.users.create({
        data: {
          username: artisan.shop_name,
          email: artisan.email,
          hashed_password: 'demo_seed_not_real',
          role: 'seller',
          verification_status: 'approved',
        },
      });
    }

    let craftCategory = await prisma.craft_categories.findUnique({
      where: { name_city_id: { name: artisan.craft, city_id: city.id } },
    });
    if (!craftCategory) {
      craftCategory = await prisma.craft_categories.create({
        data: { name: artisan.craft, city_id: city.id },
      });
    }

    const existingSeller = await prisma.sellers.findUnique({ where: { id: user.id } });
    if (!existingSeller) {
      await prisma.sellers.create({
        data: {
          id: user.id,
          shop_name: artisan.shop_name,
          description: artisan.description,
          craft_category_id: craftCategory.id,
          city_id: city.id,
        },
      });
    }
  }
  console.log('Demo artisans + cities + craft categories seeded');
}

main()
  .catch((e) => console.error(e))
  .finally(() => prisma.$disconnect());