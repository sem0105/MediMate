const express = require("express");
const router = express.Router();

const {
  createLog,
  markTaken,
  markSkipped,
  getUserLogs,
  getTodayLogs,
  getLogsByDate,
  getCalendarDates,
} = require("../controllers/medicationLogController");

// ➕ create log manually (optional)
router.post("/create", createLog);

// 📦 get all logs for user
router.get("/user/:userId", getUserLogs);

// 📅 get today logs
router.get("/today/:userId", getTodayLogs);

// 📅 get logs for a specific date (YYYY-MM-DD)
router.get("/date/:userId/:date", getLogsByDate);

// 📆 calendar dates with tasks in a month
router.get("/calendar/:userId", getCalendarDates);

// ✅ mark taken
router.put("/taken/:id", markTaken);

// ⏭ mark skipped
router.put("/skipped/:id", markSkipped);

module.exports = router;