const express = require("express");
const router = express.Router();

const {
  getAdherence,
  getWeeklyAdherence,
  getStreak,
  getTaskStats,
} = require("../controllers/dashboardController");

router.get("/task-stats/:userId", getTaskStats);
router.get("/adherence/:userId", getAdherence);

router.get(
  "/weekly-adherence/:userId",
  getWeeklyAdherence
);

router.get("/streak/:userId", getStreak);

module.exports = router;