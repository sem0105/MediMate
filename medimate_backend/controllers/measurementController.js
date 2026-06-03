const Measurement = require("../models/Measurement");

exports.addMeasurement = async (req, res) => {
  try {
    const measurement = await Measurement.create(req.body);
    res.status(201).json({ success: true, measurement });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getUserMeasurements = async (req, res) => {
  try {
    const measurements = await Measurement.find({
      userId: req.params.userId,
    })
      .sort({ recordedAt: -1 })
      .limit(50);

    res.json({ success: true, measurements });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getMeasurementsByDate = async (req, res) => {
  try {
    const { userId, date } = req.params;

    const measurements = await Measurement.find({ userId, date }).sort({
      recordedAt: -1,
    });

    res.json({ success: true, date, measurements });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteMeasurement = async (req, res) => {
  try {
    await Measurement.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: "Measurement deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
