const mongoose = require("mongoose");

const waterDailySummarySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    date: {
      type: String,
      required: true,
    },
    totalMl: {
      type: Number,
      default: 0,
    },
    goalLiters: {
      type: Number,
      default: null,
    },
    completed: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

waterDailySummarySchema.index({ userId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model("WaterDailySummary", waterDailySummarySchema);
