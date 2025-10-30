class CollectedDoc {
  final String path; // cropped image path
  final String pdfUrl; // generated PDF URL

  CollectedDoc({required this.path, required this.pdfUrl});

  Map<String, dynamic> toJson() => {"path": path, "pdfUrl": pdfUrl};

  factory CollectedDoc.fromJson(Map<String, dynamic> json) =>
      CollectedDoc(path: json["path"], pdfUrl: json["pdfUrl"]);
}
