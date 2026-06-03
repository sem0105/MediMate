const express = require("express");
const router = express.Router();

const {
  addMedicine,
  getMedicines,
  getUserMedicines,
  getMedicineById,
  updateMedicine,
  deleteMedicine,
  getTodayMedicines,
} = require("../controllers/medicineController");

// ➕ Add Medicine
router.post("/add", addMedicine);

// 📦 Get all medicines
router.get("/", getMedicines);

// 👤 Get medicines by user
router.get("/user/:userId", getUserMedicines);

router.get("/today/:userId", getTodayMedicines);

// 📄 Get single medicine
router.get("/detail/:id", getMedicineById);

// ✏️ Update medicine
router.put("/:id", updateMedicine);

// ❌ Delete medicine
router.delete("/:id", deleteMedicine);

module.exports = router;