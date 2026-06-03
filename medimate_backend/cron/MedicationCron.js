const cron = require("node-cron");
const { generateTodayLogsForActiveMedicines } = require("../utils/logGenerator");

const startMedicationCron = () => {
  cron.schedule("0 0 * * *", async () => {
    try {
      const count = await generateTodayLogsForActiveMedicines();
      console.log(`Medication cron: ensured logs for today (${count} upserts)`);
    } catch (error) {
      console.error("Medication cron failed:", error.message);
    }
  });

  console.log("Medication cron scheduled (daily at midnight)");
};

module.exports = startMedicationCron;
