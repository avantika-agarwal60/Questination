const express = require('express');
const router = express.Router();
const multer = require('multer');
const upload = multer({ storage: multer.memoryStorage() });
const {
  registerSeller,
  getSellerProfile,
  updateSellerProfile,
  verifySellerCraft,
  getPendingSellers,
  submitUdyamProof,
  getUdyamProofUrl,
} = require('../controllers/seller.controller.cjs');

router.post('/register', registerSeller);
router.get('/pending', getPendingSellers);
router.post('/:id/udyam', upload.single('udyam_proof'), submitUdyamProof);
router.get('/:id/udyam-proof-url', getUdyamProofUrl);   // ← Step E's route line goes here
router.put('/:id/verify-craft', verifySellerCraft);
router.get('/:id', getSellerProfile);
router.put('/:id', updateSellerProfile);

module.exports = router;
