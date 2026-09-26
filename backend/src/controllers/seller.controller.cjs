const prisma = require('../db/prismaClient.cjs');

// POST /api/sellers/register
// Assumes the user already exists in `users` (created via Firebase auth + Person 1's flow)
async function registerSeller(req, res) {
  const { userId, shop_name, description, tax_bracket_tier } = req.body;

  if (!userId || !shop_name) {
    return res.status(400).json({ error: 'userId and shop_name are required' });
  }

  try {
    const seller = await prisma.sellers.create({
      data: { id: userId, shop_name, description, tax_bracket_tier },
    });
    res.status(201).json(seller);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to register seller' });
  }
}

// GET /api/sellers/:id
async function getSellerProfile(req, res) {
  const { id } = req.params;
  const seller = await prisma.sellers.findUnique({ where: { id } });
  if (!seller) return res.status(404).json({ error: 'Seller not found' });
  res.json(seller);
}

// PUT /api/sellers/:id
async function updateSellerProfile(req, res) {
  const { id } = req.params;
  const { shop_name, description, tax_bracket_tier } = req.body;

  try {
    const updated = await prisma.sellers.update({
      where: { id },
      data: { shop_name, description, tax_bracket_tier },
    });
    res.json(updated);
  } catch (err) {
    res.status(404).json({ error: 'Seller not found' });
  }
}

// PUT /api/sellers/:id/verify-craft
async function verifySellerCraft(req, res) {
  const { id } = req.params;
  const { craftName, city_id } = req.body;

  if (!craftName || !city_id) {
    return res.status(400).json({ error: 'craftName and city_id are required' });
  }

  try {
    // Find or create the craft category for this city — this is what makes
    // the category list grow dynamically as new sellers register
    let craftCategory = await prisma.craft_categories.findUnique({
      where: { name_city_id: { name: craftName, city_id } },
    });

    if (!craftCategory) {
      craftCategory = await prisma.craft_categories.create({
        data: { name: craftName, city_id },
      });
    }

    const updated = await prisma.sellers.update({
      where: { id },
      data: { craft_category_id: craftCategory.id, city_id },
    });

    res.json(updated);
  } catch (err) {
    console.error(err);
    res.status(404).json({ error: 'Seller not found' });
  }
}

module.exports = { registerSeller, getSellerProfile, updateSellerProfile, verifySellerCraft };