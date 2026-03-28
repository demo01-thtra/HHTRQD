class CalculateAllResponse {
  final String message;
  final int added;
  final int updated;
  final int total;

  CalculateAllResponse({
    required this.message,
    required this.added,
    required this.updated,
    required this.total,
  });

  factory CalculateAllResponse.fromJson(Map<String, dynamic> json) {
    return CalculateAllResponse(
      message: json['message'],
      added: json['added'],
      updated: json['updated'],
      total: json['total'],
    );
  }
}