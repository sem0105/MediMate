const Activity = require("../models/Activity");
const ActivityLog = require("../models/ActivityLog");

const DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

function isActiveOnDate(activity, dateStr) {
  const date = new Date(`${dateStr}T12:00:00`);
  const dayName = DAY_NAMES[date.getDay()];

  if (activity.startDate && date < new Date(activity.startDate)) return false;
  if (activity.endDate) {
    const end = new Date(activity.endDate);
    end.setHours(23, 59, 59, 999);
    if (date > end) return false;
  }

  const freq = (activity.frequency || "Daily").toLowerCase();

  if (freq.includes("weekly")) {
    const days = activity.days || [];
    return days.length === 0 || days.includes(dayName);
  }

  if (freq.includes("demand")) {
    return true;
  }

  if (
    freq.includes("daily") ||
    freq.includes("once") ||
    freq.includes("twice") ||
    freq.includes("thrice")
  ) {
    return true;
  }

  return true;
}

exports.addActivity = async (req, res) => {
  try {
    const body = { ...req.body };
    if (body.reminderTimes?.length) {
      body.reminderTime = body.reminderTimes[0];
    } else if (body.reminderTime) {
      body.reminderTimes = [body.reminderTime];
    }
    const activity = await Activity.create(body);
    res.status(201).json({ success: true, activity });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getUserActivities = async (req, res) => {
  try {
    const activities = await Activity.find({
      userId: req.params.userId,
    }).sort({ createdAt: -1 });

    res.json({ success: true, activities });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getActivitiesByDate = async (req, res) => {
  try {
    const { userId, date } = req.params;
    const all = await Activity.find({ userId });
    const activities = all
      .filter((a) => isActiveOnDate(a, date))
      .sort((a, b) =>
        (a.reminderTime || "").localeCompare(b.reminderTime || "")
      );

    res.json({ success: true, date, activities });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateActivity = async (req, res) => {
  try {
    const activity = await Activity.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    if (!activity) {
      return res.status(404).json({ success: false, message: "Not found" });
    }

    res.json({ success: true, activity });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteActivity = async (req, res) => {
  try {
    await ActivityLog.deleteMany({ activityId: req.params.id });
    await Activity.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: "Activity deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports.isActiveOnDate = isActiveOnDate;
