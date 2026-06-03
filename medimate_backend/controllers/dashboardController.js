const MedicationLog = require("../models/MedicationLog");

function localDateString(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function previousDateString(dateStr) {
  const date = new Date(`${dateStr}T12:00:00`);
  date.setDate(date.getDate() - 1);
  return localDateString(date);
}

function getDateRange(period) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  if (period === "monthly") {
    const start = new Date(today.getFullYear(), today.getMonth(), 1);
    const end = new Date(today.getFullYear(), today.getMonth() + 1, 0);
    return { start, end };
  }

  const start = new Date(today);
  start.setDate(today.getDate() - 6);
  return { start, end: today };
}

function eachDateInRange(start, end) {
  const dates = [];
  const current = new Date(start);
  current.setHours(0, 0, 0, 0);
  const last = new Date(end);
  last.setHours(0, 0, 0, 0);

  while (current <= last) {
    dates.push(localDateString(current));
    current.setDate(current.getDate() + 1);
  }

  return dates;
}

function formatLabel(dateStr, period) {
  const date = new Date(`${dateStr}T12:00:00`);
  if (period === "monthly") {
    return String(date.getDate());
  }
  return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][date.getDay()];
}

exports.getTaskStats = async (req, res) => {
  try {
    const { userId } = req.params;
    const period = req.query.period === "monthly" ? "monthly" : "weekly";
    const { start, end } = getDateRange(period);
    const dateKeys = eachDateInRange(start, end);

    const logs = await MedicationLog.find({
      userId,
      date: { $in: dateKeys },
    });

    const totals = { pending: 0, taken: 0, skipped: 0 };

    const breakdown = dateKeys.map((date) => {
      const dayLogs = logs.filter((log) => log.date === date);
      const entry = {
        date,
        label: formatLabel(date, period),
        pending: 0,
        taken: 0,
        skipped: 0,
      };

      dayLogs.forEach((log) => {
        if (log.status === "taken") {
          entry.taken += 1;
          totals.taken += 1;
        } else if (log.status === "skipped") {
          entry.skipped += 1;
          totals.skipped += 1;
        } else {
          entry.pending += 1;
          totals.pending += 1;
        }
      });

      return entry;
    });

    res.status(200).json({
      success: true,
      period,
      totals,
      breakdown,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getAdherence = async (req, res) => {
  try {
    const { userId } = req.params;

    const totalLogs = await MedicationLog.countDocuments({ userId });
    const takenLogs = await MedicationLog.countDocuments({
      userId,
      status: "taken",
    });
    const skippedLogs = await MedicationLog.countDocuments({
      userId,
      status: "skipped",
    });

    const adherence =
      totalLogs === 0 ? 0 : Math.round((takenLogs / totalLogs) * 100);

    res.status(200).json({
      success: true,
      totalLogs,
      takenLogs,
      skippedLogs,
      adherence,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getWeeklyAdherence = async (req, res) => {
  try {
    const { userId } = req.params;
    const { start, end } = getDateRange("weekly");
    const dateKeys = eachDateInRange(start, end);

    const logs = await MedicationLog.find({
      userId,
      date: { $in: dateKeys },
    });

    const week = dateKeys.map((date) => {
      const dayLogs = logs.filter((log) => log.date === date);
      const total = dayLogs.length;
      const taken = dayLogs.filter((log) => log.status === "taken").length;
      const adherence = total === 0 ? 0 : Math.round((taken / total) * 100);

      return {
        date,
        label: formatLabel(date, "weekly"),
        adherence,
      };
    });

    res.json({ success: true, week });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
};

exports.getStreak = async (req, res) => {
  try {
    const { userId } = req.params;
    const logs = await MedicationLog.find({ userId }).sort({ date: 1 });

    const map = {};

    logs.forEach((log) => {
      const day = log.date;
      if (!map[day]) {
        map[day] = { total: 0, taken: 0 };
      }
      map[day].total += 1;
      if (log.status === "taken") map[day].taken += 1;
    });

    const days = Object.keys(map).sort();
    const completedDays = new Set(
      days.filter((d) => map[d].total === map[d].taken && map[d].total > 0)
    );

    let maxStreak = 0;
    let temp = 0;
    let previousDay = null;

    days.forEach((d) => {
      if (map[d].total === map[d].taken && map[d].total > 0) {
        if (previousDay && previousDateString(d) !== previousDay) {
          temp = 0;
        }
        temp += 1;
        maxStreak = Math.max(maxStreak, temp);
      } else {
        temp = 0;
      }
      previousDay = d;
    });

    const today = localDateString(new Date());
    let currentStreak = 0;
    let cursor = today;
    while (completedDays.has(cursor)) {
      currentStreak += 1;
      cursor = previousDateString(cursor);
    }

    res.json({
      success: true,
      currentStreak,
      maxStreak,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
};
