const mongoose = require("mongoose");

const activityLogSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    activityId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Activity",
      required: true,
    },
    date: { type: String, required: true },
    scheduledTime: { type: String, required: true },
    status: {
      type: String,
      enum: ["pending", "done", "not_done"],
      default: "pending",
    },
  },
  { timestamps: true }
);

activityLogSchema.index(
  { activityId: 1, date: 1, scheduledTime: 1 },
  { unique: true }
);

module.exports = mongoose.model("ActivityLog", activityLogSchema);
