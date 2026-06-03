const express = require("express");
const router = express.Router();
const {
  addActivity,
  getUserActivities,
  getActivitiesByDate,
  updateActivity,
  deleteActivity,
} = require("../controllers/activityController");

router.post("/add", addActivity);
router.get("/user/:userId", getUserActivities);
router.get("/date/:userId/:date", getActivitiesByDate);
router.put("/:id", updateActivity);
router.delete("/:id", deleteActivity);

module.exports = router;
