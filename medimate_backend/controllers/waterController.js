const WaterIntake = require("../models/WaterIntake");
const WaterDailySummary = require("../models/WaterDailySummary");
const User = require("../models/User");

function dateBefore(dateStr) {
  const date = new Date(`${dateStr}T12:00:00`);
  date.setDate(date.getDate() - 1);
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

async function getGoalLitersForUser(userId) {
  const user = await User.findById(userId).select("waterGoal waterGoalLiters");
  if (!user) return null;
  return user.waterGoalLiters ?? (user.waterGoal ? user.waterGoal / 4 : null);
}

async function refreshDailySummary(userId, date) {
  const entries = await WaterIntake.find({ userId, date });
  const totalMl = entries.reduce((sum, e) => sum + (e.amountMl || 0), 0);
  const goalLiters = await getGoalLitersForUser(userId);
  const goalMl = goalLiters ? Math.round(goalLiters * 1000) : 0;

  const summary = await WaterDailySummary.findOneAndUpdate(
    { userId, date },
    {
      userId,
      date,
      totalMl,
      goalLiters,
      completed: goalMl > 0 && totalMl >= goalMl,
    },
    { new: true, upsert: true }
  );

  return summary;
}

exports.addWater = async (req, res) => {
  try {
    const entry = await WaterIntake.create(req.body);
    const summary = await refreshDailySummary(entry.userId, entry.date);
    res.status(201).json({ success: true, entry, summary });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getUserWater = async (req, res) => {
  try {
    const entries = await WaterIntake.find({
      userId: req.params.userId,
    })
      .sort({ recordedAt: -1 })
      .limit(100);

    const totalMl = entries.reduce((sum, e) => sum + (e.amountMl || 0), 0);

    res.json({ success: true, entries, totalMl });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getWaterByDate = async (req, res) => {
  try {
    const { userId, date } = req.params;
    const entries = await WaterIntake.find({ userId, date }).sort({
      recordedAt: -1,
    });
    const summary = await refreshDailySummary(userId, date);

    res.json({
      success: true,
      date,
      entries,
      totalMl: summary.totalMl,
      summary,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getWaterGoal = async (req, res) => {
  try {
    const goalLiters = await getGoalLitersForUser(req.params.userId);
    if (goalLiters == null) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    res.json({ success: true, goalLiters });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateWaterGoal = async (req, res) => {
  try {
    const goalLiters = Number(req.body.goalLiters);

    if (!Number.isFinite(goalLiters) || goalLiters <= 0) {
      return res.status(400).json({
        success: false,
        message: "Enter a valid daily water goal in liters",
      });
    }

    const user = await User.findByIdAndUpdate(
      req.params.userId,
      { waterGoalLiters: goalLiters },
      { new: true }
    ).select("waterGoalLiters");

    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    const goalMl = Math.round(goalLiters * 1000);
    const summaries = await WaterDailySummary.find({ userId: req.params.userId });
    for (const summary of summaries) {
      summary.goalLiters = goalLiters;
      summary.completed = summary.totalMl >= goalMl;
      await summary.save();
    }

    res.json({ success: true, goalLiters: user.waterGoalLiters });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateWater = async (req, res) => {
  try {
    const oldEntry = await WaterIntake.findById(req.params.id);
    const entry = await WaterIntake.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    if (!entry) {
      return res.status(404).json({ success: false, message: "Not found" });
    }

    if (oldEntry) await refreshDailySummary(oldEntry.userId, oldEntry.date);
    const summary = await refreshDailySummary(entry.userId, entry.date);

    res.json({ success: true, entry, summary });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteWater = async (req, res) => {
  try {
    const entry = await WaterIntake.findByIdAndDelete(req.params.id);
    const summary = entry
      ? await refreshDailySummary(entry.userId, entry.date)
      : null;
    res.json({ success: true, message: "Water entry deleted", summary });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getWaterStreak = async (req, res) => {
  try {
    const { userId } = req.params;

    const rawDates = await WaterIntake.distinct("date", { userId });
    for (const date of rawDates) {
      await refreshDailySummary(userId, date);
    }

    const summaries = await WaterDailySummary.find({ userId }).sort({
      date: 1,
    });
    const completedDates = new Set(
      summaries.filter((s) => s.completed).map((s) => s.date)
    );

    let maxStreak = 0;
    let running = 0;
    let previousDate = null;

    summaries.forEach((summary) => {
      if (!summary.completed) {
        running = 0;
        previousDate = summary.date;
        return;
      }

      if (previousDate && dateBefore(summary.date) !== previousDate) {
        running = 0;
      }

      running += 1;
      maxStreak = Math.max(maxStreak, running);
      previousDate = summary.date;
    });

    const today = new Date();
    const todayStr = `${today.getFullYear()}-${String(
      today.getMonth() + 1
    ).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;

    let currentStreak = 0;
    let cursor = todayStr;
    while (completedDates.has(cursor)) {
      currentStreak += 1;
      cursor = dateBefore(cursor);
    }

    res.json({ success: true, currentStreak, maxStreak });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
