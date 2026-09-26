import express from 'express';
import { generateQuestQR } from '../controllers/qr.controller.js';

const router = express.Router();

router.get('/quest/:id', generateQuestQR);

export default router;
