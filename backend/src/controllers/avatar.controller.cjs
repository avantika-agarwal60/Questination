const prisma = require('../db/prismaClient.cjs');

// GET /api/avatars/items — full catalog, grouped by slot
async function getAvatarItems(req, res) {
  const items = await prisma.avatar_items.findMany();
  res.json(items);
}

// GET /api/avatars/me/:userId — current equipped config, coin balance, and owned items
async function getMyAvatar(req, res) {
  const { userId } = req.params;

  const user = await prisma.users.findUnique({
    where: { id: userId },
    select: { coins: true, avatar: true },
  });
  if (!user) return res.status(404).json({ error: 'User not found' });

  const owned = await prisma.user_avatar_items.findMany({
    where: { user_id: userId },
    select: { item_id: true },
  });

  res.json({
    coins: user.coins,
    equipped: user.avatar,
    ownedItemIds: owned.map((o) => o.item_id),
  });
}

// PUT /api/avatars/me/:userId — equip items (must already be owned or default)
async function saveEquippedAvatar(req, res) {
  const { userId } = req.params;
  const { avatar } = req.body; // e.g. { hair: "itemId", top: "itemId", ... }

  try {
    const ownedIds = new Set(
      (await prisma.user_avatar_items.findMany({ where: { user_id: userId }, select: { item_id: true } }))
        .map((o) => o.item_id)
    );
    const defaultIds = new Set(
      (await prisma.avatar_items.findMany({ where: { is_default: true }, select: { id: true } })).map((d) => d.id)
    );

    for (const slot in avatar) {
      const itemId = avatar[slot];
      if (itemId && !ownedIds.has(itemId) && !defaultIds.has(itemId)) {
        return res.status(403).json({ error: `Item not owned: ${itemId}` });
      }
    }

    await prisma.users.update({ where: { id: userId }, data: { avatar } });
    res.json({ message: 'Avatar updated' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to save avatar' });
  }
}

// POST /api/avatars/purchase — spend coins to unlock an item
async function purchaseAvatarItem(req, res) {
  const { userId, itemId } = req.body;

  if (!userId || !itemId) {
    return res.status(400).json({ error: 'userId and itemId are required' });
  }

  try {
    const item = await prisma.avatar_items.findUnique({ where: { id: itemId } });
    if (!item) return res.status(404).json({ error: 'Item not found' });

    const alreadyOwned = await prisma.user_avatar_items.findUnique({
      where: { user_id_item_id: { user_id: userId, item_id: itemId } },
    });
    if (alreadyOwned) return res.status(400).json({ error: 'Item already owned' });

    const user = await prisma.users.findUnique({ where: { id: userId }, select: { coins: true } });
    if (user.coins < item.price) {
      return res.status(400).json({ error: 'Not enough coins' });
    }

    await prisma.$transaction([
      prisma.users.update({ where: { id: userId }, data: { coins: { decrement: item.price } } }),
      prisma.user_avatar_items.create({ data: { user_id: userId, item_id: itemId } }),
    ]);

    res.json({ message: 'Item purchased' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to purchase item' });
  }
}

module.exports = { getAvatarItems, getMyAvatar, saveEquippedAvatar, purchaseAvatarItem };