const express = require('express');
const router = express.Router();
const {
  registerSeller,
  getSellerProfile,
  updateSellerProfile,
  verifySellerCraft
} = require('../controllers/seller.controller.cjs');

router.post('/register', registerSeller);
router.get('/:id', getSellerProfile);
router.put('/:id', updateSellerProfile);
router.put('/:id/verify-craft', verifySellerCraft);

module.exports = router;
