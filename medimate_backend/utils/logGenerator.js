const MedicationLog = require("../models/MedicationLog");

function toDateString(date) {
  const d = new Date(date);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

function eachDayInclusive(startDate, endDate) {
  const days = [];
  const current = new Date(startDate);
  current.setHours(0, 0, 0, 0);
  const end = new Date(endDate);
  end.setHours(0, 0, 0, 0);

  while (current <= end) {
    days.push(toDateString(current));
    current.setDate(current.getDate() + 1);
  }

  return days;
}

async function generateLogsForMedicine(medicine) {
  const days = eachDayInclusive(medicine.startDate, medicine.endDate);
  const times =
    medicine.reminderTimes?.length > 0
      ? medicine.reminderTimes
      : ["09:00"];

  const created = [];

  for (const date of days) {
    for (const scheduledTime of times) {
      const log = await MedicationLog.findOneAndUpdate(
        {
          medicineId: medicine._id,
          userId: medicine.userId,
          date,
          scheduledTime,
        },
        {
          $setOnInsert: {
            status: "pending",
          },
        },
        { upsert: true, new: true }
      );
      created.push(log);
    }
  }

  return created;
}

async function generateTodayLogsForActiveMedicines() {
  const today = toDateString(new Date());
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  const endOfDay = new Date();
  endOfDay.setHours(23, 59, 59, 999);

  const Medicine = require("../models/Medicine");
  const medicines = await Medicine.find({
    startDate: { $lte: endOfDay },
    endDate: { $gte: startOfDay },
  });

  let count = 0;
  for (const medicine of medicines) {
    const times =
      medicine.reminderTimes?.length > 0
        ? medicine.reminderTimes
        : ["09:00"];

    for (const scheduledTime of times) {
      const result = await MedicationLog.findOneAndUpdate(
        {
          medicineId: medicine._id,
          userId: medicine.userId,
          date: today,
          scheduledTime,
        },
        {
          $setOnInsert: { status: "pending" },
        },
        { upsert: true }
      );
      if (result) count += 1;
    }
  }

  return count;
}

module.exports = {
  toDateString,
  eachDayInclusive,
  generateLogsForMedicine,
  generateTodayLogsForActiveMedicines,
};
