const express = require("express");
const router = express.Router();
const {
  addAppointment,
  getUserAppointments,
  getAppointmentsByDate,
  getTodayAppointments,
  updateAppointment,
  updateAppointmentStatus,
  deleteAppointment,
} = require("../controllers/appointmentController");

router.post("/add", addAppointment);
router.get("/user/:userId", getUserAppointments);
router.get("/today/:userId", getTodayAppointments);
router.get("/date/:userId/:date", getAppointmentsByDate);
router.put("/:id", updateAppointment);
router.put("/status/:id", updateAppointmentStatus);
router.delete("/:id", deleteAppointment);

module.exports = router;
