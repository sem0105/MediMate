const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
  },

  password: {
    type: String,
    required: true,
  },

  // Profile
  name: {
    type: String,
    default: "",
  },

  age: {
    type: Number,
    default: null,
  },

  gender: {
    type: String,
    default: "",
  },

  height: {
    type: Number,
    default: null,
  },

  weight: {
    type: Number,
    default: null,
  },

  waterGoal: {
    type: Number,
    default: 8,
  },

  waterGoalLiters: {
    type: Number,
    default: null,
  },

  profileCompleted: {
    type: Boolean,
    default: false,
  }
}, {
  timestamps: true
});

module.exports = mongoose.model("User", UserSchema);
