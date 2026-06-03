const Appointment = require("../models/Appointment");
const { getToday } = require("../utils/dateUtils");

function dayRange(dateStr) {
  const start = new Date(`${dateStr}T00:00:00`);
  const end = new Date(`${dateStr}T23:59:59`);
  return { start, end };
}

exports.addAppointment = async (req, res) => {
  try {
    const appointment = await Appointment.create({
      ...req.body,
      status: req.body.status || "pending",
    });
    res.status(201).json({ success: true, appointment });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getUserAppointments = async (req, res) => {
  try {
    const appointments = await Appointment.find({
      userId: req.params.userId,
    }).sort({ appointmentDate: 1, appointmentTime: 1 });

    res.json({ success: true, appointments });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getAppointmentsByDate = async (req, res) => {
  try {
    const { userId, date } = req.params;
    const { start, end } = dayRange(date);

    const appointments = await Appointment.find({
      userId,
      appointmentDate: { $gte: start, $lte: end },
    }).sort({ appointmentTime: 1 });

    res.json({ success: true, date, appointments });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getTodayAppointments = async (req, res) => {
  req.params.date = getToday();
  req.params.userId = req.params.userId;
  return exports.getAppointmentsByDate(req, res);
};

exports.updateAppointment = async (req, res) => {
  try {
    const appointment = await Appointment.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    if (!appointment) {
      return res.status(404).json({ success: false, message: "Not found" });
    }

    res.json({ success: true, appointment });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateAppointmentStatus = async (req, res) => {
  try {
    const { status } = req.body;
    if (!["done", "not_done", "pending"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid status",
      });
    }

    const appointment = await Appointment.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true }
    );

    if (!appointment) {
      return res.status(404).json({ success: false, message: "Not found" });
    }

    res.json({ success: true, appointment });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteAppointment = async (req, res) => {
  try {
    await Appointment.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: "Appointment deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
