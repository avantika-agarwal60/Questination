const prisma = require('../db/prismaClient.cjs');

// GET /api/recommendations/:userId
async function getRecommendations(req, res) {
  const { userId } = req.params;

  try {
    const preferences = await prisma.user_preferences.findMany({
      where: { user_id: userId },
      select: { craft_category_id: true },
    });

    if (!preferences.length) {
      return res.status(400).json({ error: 'User has not set preferences yet' });
    }

    const categoryIds = preferences.map((p) => p.craft_category_id);

    const sellers = await prisma.sellers.findMany({
      where: { craft_category_id: { in: categoryIds } },
      include: { craft_category: true },
    });

    res.json(sellers);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch recommendations' });
  }
}

module.exports = { getRecommendations };