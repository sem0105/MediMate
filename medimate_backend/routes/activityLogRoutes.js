const express = require("express");
const router = express.Router();
const {
  getLogsByDate,
  updateLogStatus,
} = require("../controllers/activityLogController");

router.get("/date/:userId/:date", getLogsByDate);
router.put("/status/:id", updateLogStatus);

module.exports = router;
