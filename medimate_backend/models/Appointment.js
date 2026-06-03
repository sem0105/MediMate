const mongoose = require("mongoose");

const appointmentSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    doctorName: String,
    hospital: String,
    appointmentDate: Date,
    appointmentTime: String,
    reminderBefore: String,
    notes: String,
    status: {
      type: String,
      enum: ["pending", "done", "not_done"],
      default: "pending",
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Appointment", appointmentSchema);
