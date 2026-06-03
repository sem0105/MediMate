const mongoose = require("mongoose");

const waterIntakeSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    amountMl: { type: Number, required: true },
    date: { type: String, required: true },
    notes: { type: String, default: "" },
    recordedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model("WaterIntake", waterIntakeSchema);
