const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");
const connectDB = require("./config/db");

dotenv.config();

const app = express();

// ================= MIDDLEWARE =================
app.use(cors());
app.use(express.json());

// ================= HEALTH CHECK =================
app.get("/", (req, res) => {
  res.send("Medimate Backend Running 🚀");
});

// ================= ROUTES =================
const authRoutes = require("./routes/authRoutes");
const medicineRoutes = require("./routes/medicineRoutes");
const medicationLogRoutes = require("./routes/medicationLogRoutes");
const dashboardRoutes = require("./routes/dashboardRoutes");
const appointmentRoutes = require("./routes/appointmentRoutes");
const activityRoutes = require("./routes/activityRoutes");
const measurementRoutes = require("./routes/measurementRoutes");
const activityLogRoutes = require("./routes/activityLogRoutes");
const waterRoutes = require("./routes/waterRoutes");
const startMedicationCron = require("./cron/MedicationCron");

app.use("/api/auth", authRoutes);
app.use("/api/medicine", medicineRoutes);
app.use("/api/medication-logs", medicationLogRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/appointments", appointmentRoutes);
app.use("/api/activities", activityRoutes);
app.use("/api/measurements", measurementRoutes);
app.use("/api/activity-logs", activityLogRoutes);
app.use("/api/water", waterRoutes);

// ================= GLOBAL ERROR HANDLER =================
app.use((err, req, res, next) => {
  console.error("🔥 Server Error:", err.message);
  res.status(500).json({
    success: false,
    message: "Internal Server Error",
  });
});

// ================= START SERVER =================
const PORT = process.env.PORT || 5000;

connectDB()
  .then(() => {
    console.log("MongoDB Connected ✅");

    startMedicationCron();

    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT} 🚀`);
    });
  })
  .catch((err) => {
    console.error("DB Connection Failed ❌", err.message);
  });