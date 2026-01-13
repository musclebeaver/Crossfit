class WodModel {
  final int id;
  final String type;
  final String title;
  final String description;
  final int? timeCap;
  final int? boxId;
  final String date;

  WodModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.timeCap,
    this.boxId,
    required this.date,
  });

  factory WodModel.fromJson(Map<String, dynamic> json) {
    return WodModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      timeCap: json['timeCap'],
      boxId: json['boxId'],
      date: json['date'],
    );
  }
}
