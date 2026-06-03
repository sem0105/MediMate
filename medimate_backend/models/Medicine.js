const mongoose = require("mongoose");

const medicineSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    name: {
      type: String,
      required: true,
    },

    units: {
      type: String,
      required: true,
    },

    dose: {
      type: String,
      required: true,
    },

    frequency: {
      type: String,
      default: "daily",
    },

    reminderTimes: {
      type: [String],
      default: [],
    },

    startDate: {
      type: Date,
      required: true,
    },

    endDate: {
      type: Date,
      required: true,
    },

    notes: {
      type: String,
      default: "",
    },

    reminderEnabled: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Medicine", medicineSchema);