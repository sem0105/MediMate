const mongoose = require("mongoose");

const MedicationLogSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    medicineId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Medicine",
      required: true,
    },
    date: {
      type: String,
      required: true,
    },
    scheduledTime: {
      type: String,
      required: true,
    },
    status: {
      type: String,
      enum: ["pending", "taken", "skipped", "missed"],
      default: "pending",
    },
    takenAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

MedicationLogSchema.index(
  { medicineId: 1, date: 1, scheduledTime: 1 },
  { unique: true }
);

module.exports = mongoose.model("MedicationLog", MedicationLogSchema);
