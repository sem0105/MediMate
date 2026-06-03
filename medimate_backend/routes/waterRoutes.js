const express = require("express");
const router = express.Router();
const {
  addWater,
  getUserWater,
  getWaterByDate,
  getWaterGoal,
  updateWaterGoal,
  getWaterStreak,
  updateWater,
  deleteWater,
} = require("../controllers/waterController");

router.post("/add", addWater);
router.get("/user/:userId", getUserWater);
router.get("/date/:userId/:date", getWaterByDate);
router.get("/goal/:userId", getWaterGoal);
router.put("/goal/:userId", updateWaterGoal);
router.get("/streak/:userId", getWaterStreak);
router.put("/:id", updateWater);
router.delete("/:id", deleteWater);

module.exports = router;
