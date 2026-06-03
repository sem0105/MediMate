class MeasurementTypeInfo {
  final String id;
  final String label;
  final String unit;
  final bool hasSecondary;
  final String secondaryLabel;

  const MeasurementTypeInfo({
    required this.id,
    required this.label,
    required this.unit,
    this.hasSecondary = false,
    this.secondaryLabel = "",
  });
}

const measurementTypes = [
  MeasurementTypeInfo(
    id: "blood_pressure",
    label: "Blood Pressure",
    unit: "mmHg",
    hasSecondary: true,
    secondaryLabel: "Diastolic",
  ),
  MeasurementTypeInfo(
    id: "heart_rate",
    label: "Heart Rate",
    unit: "bpm",
  ),
  MeasurementTypeInfo(
    id: "blood_sugar",
    label: "Blood Sugar",
    unit: "mg/dL",
  ),
  MeasurementTypeInfo(
    id: "weight",
    label: "Weight",
    unit: "kg",
  ),
  MeasurementTypeInfo(
    id: "temperature",
    label: "Body Temperature",
    unit: "°C",
  ),
  MeasurementTypeInfo(
    id: "oxygen_saturation",
    label: "Oxygen Saturation (SpO2)",
    unit: "%",
  ),
  MeasurementTypeInfo(
    id: "steps",
    label: "Steps",
    unit: "steps",
  ),
];

MeasurementTypeInfo? findMeasurementType(String id) {
  for (final t in measurementTypes) {
    if (t.id == id) return t;
  }
  return null;
}

String measurementDisplayLabel(String type) {
  return findMeasurementType(type)?.label ?? type;
}

String measurementDisplayValue(Map<String, dynamic> m) {
  final info = findMeasurementType(m["type"]?.toString() ?? "");
  final v = m["value"]?.toString() ?? "";
  final extra = m["extraValue"]?.toString() ?? "";
  final unit = m["unit"]?.toString() ?? info?.unit ?? "";

  if (m["type"] == "blood_pressure" && extra.isNotEmpty) {
    return "$v / $extra $unit";
  }
  return "$v $unit".trim();
}
