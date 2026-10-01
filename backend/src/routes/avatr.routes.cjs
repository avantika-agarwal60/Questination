const express = require('express');
const router = express.Router();
const {
  getAvatarItems,
  getMyAvatar,
  saveEquippedAvatar,
  purchaseAvatarItem,
} = require('../controllers/avatar.controller.cjs');

router.get('/items', getAvatarItems);
router.get('/me/:userId', getMyAvatar);
router.put('/me/:userId', saveEquippedAvatar);
router.post('/purchase', purchaseAvatarItem);

module.exports = router;