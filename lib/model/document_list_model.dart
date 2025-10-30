import 'dart:convert';

// Define the Document class to hold the data from the API.
class Document {
  final String docName;
  final String docId;

  // Constructor for the Document class.
  Document({
    required this.docName,
    required this.docId,
  });

  // Factory constructor to create a Document object from a JSON map.
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      // The trim() method is used here to remove any leading/trailing whitespace
      // that might be present in the JSON data, ensuring clean output.
      docName: json['doc_name'].trim(),
      docId: json['doc_id'],
    );
  }
}
