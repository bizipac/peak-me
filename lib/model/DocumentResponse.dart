class DocumentResponse {
  final String status;
  final int docCount;
  final List<Doc> doclist;

  DocumentResponse({
    required this.status,
    required this.docCount,
    required this.doclist,
  });

  factory DocumentResponse.fromJson(Map<String, dynamic> json) {
    return DocumentResponse(
      status: json['status'] ?? '',
      docCount: json['docCount'] ?? 0,
      doclist: (json['doclist'] as List<dynamic>?)
          ?.map((e) => Doc.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'docCount': docCount,
      'doclist': doclist.map((e) => e.toJson()).toList(),
    };
  }
}

class Doc {
  final String docId;
  final String docName;
  final String docType;
  final String docStatus;
  final String docCategory;
  final String docClient;
  final String? createdBy;
  final String? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  Doc({
    required this.docId,
    required this.docName,
    required this.docType,
    required this.docStatus,
    required this.docCategory,
    required this.docClient,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Doc.fromJson(Map<String, dynamic> json) {
    return Doc(
      docId: json['doc_id'] ?? '',
      docName: json['doc_name'] ?? '',
      docType: json['doc_type'] ?? '',
      docStatus: json['doc_status'] ?? '',
      docCategory: json['doc_category'] ?? '',
      docClient: json['doc_client'] ?? '',
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doc_id': docId,
      'doc_name': docName,
      'doc_type': docType,
      'doc_status': docStatus,
      'doc_category': docCategory,
      'doc_client': docClient,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
