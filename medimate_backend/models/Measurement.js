const mongoose = require("mongoose");

const measurementSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    type: { type: String, required: true },
    value: { type: String, required: true },
    extraValue: { type: String, default: "" },
    unit: { type: String, default: "" },
    notes: { type: String, default: "" },
    date: { type: String, required: true },
    recordedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Measurement", measurementSchema);
