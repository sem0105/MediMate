const MedicationLog = require("../models/MedicationLog");
const Medicine = require("../models/Medicine");
const { getToday } = require("../utils/dateUtils");

async function ensureLogsForDate(userId, date) {
  const day = new Date(`${date}T12:00:00`);
  const endOfDay = new Date(day);
  endOfDay.setHours(23, 59, 59, 999);

  const medicines = await Medicine.find({
    userId,
    startDate: { $lte: endOfDay },
    endDate: { $gte: day },
  });

  for (const medicine of medicines) {
    const times =
      medicine.reminderTimes?.length > 0
        ? medicine.reminderTimes
        : ["09:00"];

    for (const scheduledTime of times) {
      await MedicationLog.findOneAndUpdate(
        {
          medicineId: medicine._id,
          userId,
          date,
          scheduledTime,
        },
        { $setOnInsert: { status: "pending" } },
        { upsert: true }
      );
    }
  }
}

exports.createLog = async (req, res) => {
  try {
    const existingLog = await MedicationLog.findOne({
      medicineId: req.body.medicineId,
      userId: req.body.userId,
      date: req.body.date,
      scheduledTime: req.body.scheduledTime,
    });

    if (existingLog) {
      return res.status(400).json({
        success: false,
        message: "Log already exists for this schedule",
      });
    }

    const log = await MedicationLog.create(req.body);

    res.status(201).json({
      success: true,
      log,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.markTaken = async (req, res) => {
  try {
    const log = await MedicationLog.findByIdAndUpdate(
      req.params.id,
      {
        status: "taken",
        takenAt: new Date(),
      },
      { new: true }
    ).populate("medicineId");

    if (!log) {
      return res.status(404).json({
        success: false,
        message: "Log not found",
      });
    }

    res.json({
      success: true,
      log,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
};

exports.markSkipped = async (req, res) => {
  try {
    const log = await MedicationLog.findByIdAndUpdate(
      req.params.id,
      {
        status: "skipped",
      },
      { new: true }
    ).populate("medicineId");

    if (!log) {
      return res.status(404).json({
        success: false,
        message: "Log not found",
      });
    }

    res.json({
      success: true,
      log,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
};

exports.getUserLogs = async (req, res) => {
  try {
    const logs = await MedicationLog.find({
      userId: req.params.userId,
    })
      .populate("medicineId")
      .sort({ date: 1, scheduledTime: 1 });

    res.status(200).json({
      success: true,
      logs,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getTodayLogs = async (req, res) => {
  try {
    const today = getToday();
    await ensureLogsForDate(req.params.userId, today);

    const logs = await MedicationLog.find({
      userId: req.params.userId,
      date: today,
    }).populate("medicineId");

    res.status(200).json({
      success: true,
      date: today,
      logs,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getLogsByDate = async (req, res) => {
  try {
    const { userId, date } = req.params;

    await ensureLogsForDate(userId, date);

    const logs = await MedicationLog.find({
      userId,
      date,
    }).populate("medicineId");

    res.status(200).json({
      success: true,
      date,
      logs,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getCalendarDates = async (req, res) => {
  try {
    const { userId } = req.params;
    const year = parseInt(req.query.year, 10);
    const month = parseInt(req.query.month, 10);

    if (!year || !month) {
      return res.status(400).json({
        success: false,
        message: "year and month query params are required",
      });
    }

    const monthStr = String(month).padStart(2, "0");
    const prefix = `${year}-${monthStr}`;

    const dates = await MedicationLog.distinct("date", {
      userId,
      date: { $regex: `^${prefix}` },
    });

    res.status(200).json({
      success: true,
      year,
      month,
      dates: dates.sort(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
