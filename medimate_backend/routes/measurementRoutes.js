const express = require("express");
const router = express.Router();
const {
  addMeasurement,
  getUserMeasurements,
  getMeasurementsByDate,
  deleteMeasurement,
} = require("../controllers/measurementController");

router.post("/add", addMeasurement);
router.get("/user/:userId", getUserMeasurements);
router.get("/date/:userId/:date", getMeasurementsByDate);
router.delete("/:id", deleteMeasurement);

module.exports = router;
