class MedicineDashboardModel {
  final String logId;
  final String medicineName;
  final String dosage;
  final String unit;
  final String time;
  final String status;

  MedicineDashboardModel({
    required this.logId,
    required this.medicineName,
    required this.dosage,
    required this.unit,
    required this.time,
    required this.status,
  });

  factory MedicineDashboardModel.fromJson(Map<String, dynamic> json) {
    return MedicineDashboardModel(
      logId: json['logId'],
      medicineName: json['medicineName'],
      dosage: json['dosage'],
      unit: json['unit'],
      time: json['time'],
      status: json['status'],
    );
  }
}