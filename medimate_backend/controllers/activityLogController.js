const Activity = require("../models/Activity");
const ActivityLog = require("../models/ActivityLog");
const { isActiveOnDate } = require("./activityController");

async function ensureLogsForDate(userId, date) {
  const activities = await Activity.find({ userId });
  const active = activities.filter((a) => isActiveOnDate(a, date));

  for (const activity of active) {
    const times =
      activity.reminderTimes?.length > 0
        ? activity.reminderTimes
        : [activity.reminderTime || "09:00"];

    for (const scheduledTime of times) {
      await ActivityLog.findOneAndUpdate(
        {
          activityId: activity._id,
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

exports.getLogsByDate = async (req, res) => {
  try {
    const { userId, date } = req.params;
    await ensureLogsForDate(userId, date);

    const logs = await ActivityLog.find({ userId, date })
      .populate("activityId")
      .sort({ scheduledTime: 1 });

    res.json({ success: true, date, logs });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateLogStatus = async (req, res) => {
  try {
    const { status } = req.body;
    if (!["done", "not_done", "pending"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid status",
      });
    }

    const log = await ActivityLog.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true }
    ).populate("activityId");

    if (!log) {
      return res.status(404).json({ success: false, message: "Not found" });
    }

    res.json({ success: true, log });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteActivityLogs = async (activityId) => {
  await ActivityLog.deleteMany({ activityId });
};

module.exports.ensureLogsForDate = ensureLogsForDate;
