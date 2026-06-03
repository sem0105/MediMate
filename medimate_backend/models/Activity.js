const mongoose = require("mongoose");

const activitySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    activityName: { type: String, required: true },
    frequency: { type: String, default: "Once Daily" },
    reminderTime: { type: String, default: "09:00" },
    reminderTimes: { type: [String], default: ["09:00"] },
    days: { type: [String], default: [] },
    notes: { type: String, default: "" },
    startDate: { type: Date },
    endDate: { type: Date },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Activity", activitySchema);
