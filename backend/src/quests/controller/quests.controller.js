//import quests from "../routes/quests.json" with {"type": "json"};
import { getDistanceKm } from "../../common/utils/geodistance.js";
//import users from "../../auth/routes/users.json" with {"type": "json"};
//import cities from "../../quests/routes/cities.json" with {"type": "json"};
import { awardXp } from "../../xp/xp.service.js";
import { PrismaClient } from '@prisma/client';
import crypto from "crypto"
const prisma = new PrismaClient();
export async function getQuests(req,res)
{
    const {city_id}=req.query;
    if (!city_id)
        return res.status(200).json({quests: await prisma.quests.findMany()});  
    const quests= await prisma.quests.findMany({
        where: {
            city_id: city_id,
        },
    });
    if (quests.length===0)
        return res.status(404).json({message: "no quests found in the specified city"});
    return res.status(200).json({quests: quests});
}
export async function getCities(req,res)
{
    const cities= await prisma.cities.findMany();  
    if (cities.length===0)
        return res.status(404).json({message: "no cities found"});
    return res.status(200).json({cities: cities});
}
export async function questById(req,res)
{
    const {id}=req.params;
    if (!id)
        return res.status(400).json({message: "missing required fields"});
    const quest= await prisma.quests.findUnique({
        where: {
            id: id,
        },
    });
    if (!quest)
        return res.status(404).json({message: "quest not found"});  
    return res.status(200).json({quest: quest});
}
export async function questCompletion(req,res)
{
    const questId=req.params.id;
    const {lat, lng, qr_code, photoUrl}= req.body;
    const userId=req.user.id;
    if (!questId ||!userId || !lat || !lng || !qr_code || !photoUrl)
        return res.status(400).json({message: "missing required fields, quest incomplete"});
    const user= await prisma.users.findUnique({
        where: {
            id: userId,
        },
    });
    if (!user)
        return res.status(404).json({message: "user not found"});
    const alreadyCompleted = await prisma.completed_quests.findFirst({
    where: {
        user_id: userId,
        quest_id: questId,
    },
});
if (alreadyCompleted) {
    return res.status(409).json({ message: "quest already completed" });
};
    const quest=await prisma.quests.findUnique({
        where: {
            id: questId,
        },
    });
    if (!quest)
        return res.status(404).json({message: "quest not found"});
    const distance= getDistanceKm(lat, lng, quest.lat, quest.lng);
    
    if (distance>0.05)
        return res.status(400).json({message: "user is not at the quest location, quest incomplete"});
    if (qr_code!==quest.qr_code)
        return res.status(400).json({message: "invalid QR code, quest incomplete"});
    if(!photoUrl)
        return res.status(400).json({message: "photo evidence is required, quest incomplete"});
    const city= await prisma.cities.findUnique({
        where: {
            id: quest.city_id,
        },
    });
    if (!city)
        return res.status(404).json({message: "city not found"});
     await prisma.completed_quests.create({
        data: {
            id: crypto.randomUUID(),
            user_id: userId,
            quest_id: questId,
        },
    });

    const result = await awardXp(userId, city.id, quest.xp);

    if (result.success === true) {
        return res.status(200).json({
            message: `quest completed successfully. Congratulations! xp awarded: ${quest.xp}, current level in ${city.name}: ${result.cityProgress.level}`,
        });
    } else {
        return res.status(500).json({ message: "quest completed but xp not awarded due to an internal error" });
    }
}