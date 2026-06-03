const User = require("../models/User");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

// REGISTER
const register = async (req, res) => {
  try {
    let { email, password } = req.body;

    // normalize
    email = email.toLowerCase().trim();

    // check existing user
    const userExists = await User.findOne({ email });

    if (userExists) {
      return res.status(400).json({
        success: false,
        type: "EMAIL_EXISTS",
        message: "Email already registered. Please login.",
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      email,
      password: hashedPassword,
    });

    return res.status(201).json({
      success: true,
      message: "User registered successfully",
      user: {
        id: user._id,
        email: user.email,
      },
    });

  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        type: "EMAIL_EXISTS",
        message: "Email already exists (duplicate blocked)",
      });
    }

    return res.status(500).json({
      success: false,
      type: "SERVER_ERROR",
      message: error.message,
    });
  }
};

// LOGIN
const login = async (req, res) => {
  try {
    let { email, password } = req.body;

    email = email.toLowerCase().trim();

    const user = await User.findOne({ email });

    // 🔥 IMPORTANT: clear "register first" handling
    if (!user) {
      return res.status(400).json({
        success: false,
        type: "USER_NOT_FOUND",
        message: "User not found. Please register first.",
      });
    }

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(400).json({
        success: false,
        type: "INVALID_PASSWORD",
        message: "Invalid password",
      });
    }

    const token = jwt.sign(
      { id: user._id },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    res.json({
      message: "Login successful",
      token,
      user: {
        id: user._id,
        email: user.email,
        profileCompleted: user.profileCompleted,
        name: user.name,
        age: user.age,
        gender: user.gender,
        height: user.height,
        weight: user.weight
      },
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      type: "SERVER_ERROR",
      message: error.message,
    });
  }
};

const getProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    return res.json({
      success: true,
      user,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

const updateProfile = async (req, res) => {
  try {
    const userId = req.user.id; // 🔐 from token (NOT frontend)

    const { name, age, gender, height, weight } = req.body;

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        type: "USER_NOT_FOUND",
        message: "User not found",
      });
    }

    user.name = name;
    user.age = age;
    user.gender = gender;
    user.height = height;
    user.weight = weight;
    user.profileCompleted = true;

    await user.save();

    return res.json({
      success: true,
      message: "Profile updated successfully",
      user,
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      type: "SERVER_ERROR",
      message: error.message,
    });
  }
};

module.exports = {
  register,
  login,
  updateProfile,
  getProfile,
};