const Medicine = require("../models/Medicine");
const MedicationLog = require("../models/MedicationLog");
const { generateLogsForMedicine } = require("../utils/logGenerator");

exports.addMedicine = async (req, res) => {
  try {
    const medicine = await Medicine.create(req.body);
    const logs = await generateLogsForMedicine(medicine);

    res.status(201).json({
      success: true,
      medicine,
      logsCreated: logs.length,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getMedicines = async (req, res) => {
  try {
    const medicines = await Medicine.find().sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      medicines,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getUserMedicines = async (req, res) => {
  try {
    const medicines = await Medicine.find({
      userId: req.params.userId,
    }).sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      medicines,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getMedicineById = async (req, res) => {
  try {
    const medicine = await Medicine.findById(req.params.id);

    if (!medicine) {
      return res.status(404).json({
        success: false,
        message: "Medicine not found",
      });
    }

    res.status(200).json({
      success: true,
      medicine,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.updateMedicine = async (req, res) => {
  try {
    const medicine = await Medicine.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!medicine) {
      return res.status(404).json({
        success: false,
        message: "Medicine not found",
      });
    }

    await MedicationLog.deleteMany({
      medicineId: medicine._id,
      status: "pending",
    });

    const logs = await generateLogsForMedicine(medicine);

    res.status(200).json({
      success: true,
      medicine,
      logsCreated: logs.length,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.deleteMedicine = async (req, res) => {
  try {
    const medicine = await Medicine.findById(req.params.id);

    if (!medicine) {
      return res.status(404).json({
        success: false,
        message: "Medicine not found",
      });
    }

    await MedicationLog.deleteMany({ medicineId: req.params.id });
    await Medicine.findByIdAndDelete(req.params.id);

    res.status(200).json({
      success: true,
      message: "Medicine deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getTodayMedicines = async (req, res) => {
  try {
    const { userId } = req.params;

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    const medicines = await Medicine.find({
      userId,
      startDate: { $lte: endOfDay },
      endDate: { $gte: startOfDay },
    }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      date: startOfDay,
      count: medicines.length,
      medicines,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
