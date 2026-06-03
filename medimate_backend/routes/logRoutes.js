const router = require("express").Router();
const controller = require("../controllers/logController");

router.get("/today/:userId", controller.getTodayLogs);
router.put("/taken/:logId", controller.markTaken);
router.get("/date/:userId/:date", controller.getLogsByDate);

module.exports = router;