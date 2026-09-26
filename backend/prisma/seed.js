
import { PrismaClient } from "@prisma/client";
import bcrypt from "bcrypt";

const prisma = new PrismaClient();

const ADMIN_ID = "3fc43206-57b0-44ce-ad61-6a62c50cd86e";

async function main() {

    // =========================================================
    // 0. ADMIN USER
    // =========================================================

    const adminPassword = await bcrypt.hash("DemoAdmin@123", 10);

    await prisma.users.upsert({
        where: {
            id: ADMIN_ID
        },
        update: {},
        create: {
            id: ADMIN_ID,
            username: "DemoAdmin",
            email: "admin@questination.com",
            phone: "9999999999",
            hashedPassword: adminPassword,
            role: "admin",
            verificationStatus: "not_applicable",
            isActive: true
        }
    });


    // =========================================================
    // 1. CITIES
    // =========================================================

    const lucknow = await prisma.cities.upsert({
        where: {
            name: "Lucknow"
        },
        update: {},
        create: {
            id: "city-lucknow",
            name: "Lucknow",
            level_thresholds: [150, 300, 500, 750]
        }
    });

    const varanasi = await prisma.cities.upsert({
        where: {
            name: "Varanasi"
        },
        update: {},
        create: {
            id: "city-varanasi",
            name: "Varanasi",
            level_thresholds: [150, 300, 500, 750]
        }
    });


    // =========================================================
    // 2. REMOVE OLD SAMPLE QUEST IDs
    // =========================================================
    // We are changing q1-q10 to q01-q10.
    // Delete old sample IDs first so the new IDs can be created.

    await prisma.quests.deleteMany({
        where: {
            id: {
                in: [
                    "q1",
                    "q2",
                    "q3",
                    "q4",
                    "q5",
                    "q6",
                    "q7",
                    "q8",
                    "q9",
                    "q10"
                ]
            }
        }
    });


    // =========================================================
    // 3. LUCKNOW — q01 to q05
    // =========================================================

    await prisma.quests.upsert({
        where: { id: "q01" },
        update: {},
        create: {
            id: "q01",
            city_id: lucknow.id,
            name: "Bara Imambara",
            description:
                "Explore the historic Bara Imambara and discover its grand Awadhi architecture.",
            lat: 26.86953,
            lng: 80.91351,
            geofence_radius_km: 0.05,
            xp: 150,
            qr_code: "BARA-IMAMBARA-001",
            created_by: ADMIN_ID
        }
    });


    await prisma.quests.upsert({
        where: { id: "q02" },
        update: {},
        create: {
            id: "q02",
            city_id: lucknow.id,
            name: "Chota Imambara",
            description:
                "Visit the elegant Chota Imambara and explore its historic architecture.",
            lat: 26.87373,
            lng: 80.90439,
            geofence_radius_km: 0.05,
            xp: 150,
            qr_code: "CHOTA-IMAMBARA-001",
            created_by: ADMIN_ID
        }
    });


    await prisma.quests.upsert({
        where: { id: "q03" },
        update: {},
        create: {
            id: "q03",
            city_id: lucknow.id,
            name: "Rumi Darwaza",
            description:
                "Discover the iconic Rumi Darwaza, one of Lucknow's most recognizable gateways.",
            lat: 26.860556,
            lng: 80.915833,
            geofence_radius_km: 0.05,
            xp: 150,
            qr_code: "RUMI-DARWAZA-001",
            created_by: ADMIN_ID
        }
    });


    await prisma.quests.upsert({
        where: { id: "q04" },
        update: {},
        create: {
            id: "q04",
            city_id: lucknow.id,
            name: "British Residency",
            description:
                "Explore the historic British Residency complex and learn about its role in Lucknow's history.",
            lat: 26.8667,
            lng: 80.9115,
            geofence_radius_km: 0.05,
            xp: 200,
            qr_code: "BRITISH-RESIDENCY-001",
            created_by: ADMIN_ID
        }
    });


    await prisma.quests.upsert({
        where: { id: "q05" },
        update: {},
        create: {
            id: "q05",
            city_id: lucknow.id,
            name: "Chattar Manzil",
            description:
                "Visit Chattar Manzil, the historic Umbrella Palace overlooking the Gomti.",
            lat: 26.85869,
            lng: 80.93239,
            geofence_radius_km: 0.05,
            xp: 200,
            qr_code: "CHATTAR-MANZIL-001",
            created_by: ADMIN_ID
        }
    });


    // =========================================================
    // 4. VARANASI — q06 to q10
    // =========================================================

    await prisma.quests.upsert({
        where: { id: "q06" },
        update: {},
        create: {
            id: "q06",
            city_id: varanasi.id,
            name: "Kashi Vishwanath Temple",
            description:
                "Explore the sacred Kashi Vishwanath Temple area in the heart of Varanasi.",
            lat: 25.3109,
            lng: 83.0107,
            geofence_radius_km: 0.05,
            xp: 150,
            qr_code: "KASHI-VISHWANATH-001",
            created_by: ADMIN_ID
        }
    });


    await prisma.quests.upsert({
        where: { id: "q07" },
        update: {},
        create: {
            id: "q07",
            city_id: varanasi.id,
            name: "Dashashwamedh Ghat",
            description:
                "Discover the famous Dashashwamedh Ghat on the banks of the Ganga.",
            lat: 25.3062,
            lng: 83.0103,
            geofence_radius_km: 0.05,
            xp: 150,
            qr_code: "DASHASHWAMEDH-GHAT-001",
            created_by: ADMIN_ID
        }
    });


    await prisma.quests.upsert({
        where: { id: "q08" },
        update: {},
        create: {
            id: "q08",
            city_id: varanasi.id,
            name: "Sarnath",
            description:
                "Explore Sarnath, an important Buddhist heritage site near Varanasi.",
            lat: 25.3716,
            lng: 83.0252,
            geofence_radius_km: 0.05,
            xp: 200,
            qr_code: "SARNATH-001",
            created_by: ADMIN_ID
        }
    });


    await prisma.quests.upsert({
        where: { id: "q09" },
        update: {},
        create: {
            id: "q09",
            city_id: varanasi.id,
            name: "Ramnagar Fort",
            description:
                "Explore the historic Ramnagar Fort and its royal heritage.",
            lat: 25.26971,
            lng: 83.02455,
            geofence_radius_km: 0.05,
            xp: 200,
            qr_code: "RAMNAGAR-FORT-001",
            created_by: ADMIN_ID
        }
    });


    await prisma.quests.upsert({
        where: { id: "q10" },
        update: {},
        create: {
            id: "q10",
            city_id: varanasi.id,
            name: "Assi Ghat",
            description:
                "Visit Assi Ghat, one of the southernmost and well-known ghats of Varanasi.",
            lat: 25.2886,
            lng: 83.0065,
            geofence_radius_km: 0.05,
            xp: 150,
            qr_code: "ASSI-GHAT-001",
            created_by: ADMIN_ID
        }
    });


    // =========================================================
    // DONE
    // =========================================================

    console.log("Seed completed successfully!");
    console.log("Lucknow: q01 - q05");
    console.log("Varanasi: q06 - q10");
}


main()
    .catch((error) => {
        console.error("Seed failed:", error);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
