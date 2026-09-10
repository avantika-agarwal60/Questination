import express from "express";
import auth_router from "./auth/routes/auth.routes.js";
import quests_router from "./quests/routes/quests.routes.js";
const app= express();
app.use(express.json());
app.use("/auth", auth_router);
app.use("/quests", quests_router);
export default app;