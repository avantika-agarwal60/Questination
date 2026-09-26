import express from "express";
import auth_router from "./auth/routes/auth.routes.js";
import quests_router from "./quests/routes/quests.routes.js";

// ADDED — your CommonJS route files, imported via default import
import sellerRoutes from "./routes/seller.routes.cjs";
import couponRoutes from "./routes/coupon.routes.cjs";
import preferencesRoutes from "./routes/preferences.routes.cjs";
import recommendationsRoutes from "./routes/recommendations.routes.cjs";
import artisanRoutes from "./routes/artisan.routes.cjs";

const app = express();
app.use(express.json());
app.use("/auth", auth_router);
app.use("/quests", quests_router);
app.use("/quiz", quiz_router); // NOTE: quiz_router is not imported — ask Person 1 to fix

// ADDED — your routes mounted
app.use("/api/sellers", sellerRoutes);
app.use("/api/coupons", couponRoutes);
app.use("/api/preferences", preferencesRoutes);
app.use("/api/recommendations", recommendationsRoutes);
app.use("/api/artisans", artisanRoutes);

export default app;