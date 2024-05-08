class ocrtext {
  final String filename;
  final double confidence;
  final String text;
  final List<dynamic> bbox;

  ocrtext({
    required this.filename,
    required this.confidence,
    required this.text,
    required this.bbox,
  });

  factory ocrtext.fromJson(Map<String, dynamic> json) {
    return ocrtext(
      filename: json['filename'],
      confidence: double.parse(json['confidence']),
      text: json['string'],
      bbox: json['bbox'],
    );
  }
}