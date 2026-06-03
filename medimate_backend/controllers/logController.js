const Log = require("../models/MedicationLog");
const Medicine = require("../models/Medicine");
const { getToday } = require("../utils/dateUtils");

exports.getTodayLogs = async (req, res) => {
  try {
    const today = getToday();

    const medicines = await Medicine.find({
      userId: req.params.userId,
      startDate: { $lte: new Date(today) },
      endDate: { $gte: new Date(today) }
    });

    const results = [];

    for (let med of medicines) {
      let log = await Log.findOne({
        userId: req.params.userId,
        medicineId: med._id,
        date: today
      });

      if (!log) {
        log = await Log.create({
          userId: req.params.userId,
          medicineId: med._id,
          date: today,
          status: "pending"
        });
      }

      results.push({
        medicine: med,
        log
      });
    }

    res.json(results);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.markTaken = async (req, res) => {
  try {
    const { logId } = req.params;

    const updated = await Log.findByIdAndUpdate(
      logId,
      { status: "taken" },
      { new: true }
    );

    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getLogsByDate = async (req, res) => {
  try {
    const { userId, date } = req.params;

    const logs = await Log.find({ userId, date })
      .populate("medicineId");

    res.json(logs);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};