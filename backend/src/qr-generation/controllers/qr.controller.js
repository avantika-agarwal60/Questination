import QRCode from 'qrcode';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function generateQuestQR(req, res) {
  try {
    const questId = req.params.id;

    const quest = await prisma.quests.findUnique({
      where: { id: questId }
    });

    if (!quest) {
      return res.status(404).json({ message: 'quest not found' });
    }

    const qrDataUrl = await QRCode.toDataURL(quest.qr_code);
    return res.status(200).json({ qrImage: qrDataUrl });
  } catch (error) {
    console.error('Error generating QR code:', error);
    return res.status(500).json({ message: 'Internal server error' });
  }
}
