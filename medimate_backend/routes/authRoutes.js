const express = require("express");
const router = express.Router();

const {
  register,
  login,
  updateProfile,
  getProfile,
} = require("../controllers/authController");

const protect = require("../middleware/authMiddleware");

router.post("/register", register);
router.post("/login", login);

router.post("/update-profile", protect, updateProfile);
router.get("/profile", protect, getProfile);

module.exports = router;