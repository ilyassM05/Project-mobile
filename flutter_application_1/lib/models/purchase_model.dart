class PurchaseModel {
  final String purchaseId;
  final String userId;
  final String courseId;
  final String transactionHash;
  final double priceETH;
  final DateTime purchasedAt;

  PurchaseModel({
    required this.purchaseId,
    required this.userId,
    required this.courseId,
    required this.transactionHash,
    required this.priceETH,
    required this.purchasedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'purchaseId': purchaseId,
      'userId': userId,
      'courseId': courseId,
      'transactionHash': transactionHash,
      'priceETH': priceETH.toString(),
      'purchasedAt': purchasedAt.toIso8601String(),
    };
  }

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      purchaseId: json['purchaseId'] ?? '',
      userId: json['userId'] ?? '',
      courseId: json['courseId'] ?? '',
      transactionHash: json['transactionHash'] ?? '',
      priceETH: double.tryParse(json['priceETH'] ?? '0') ?? 0.0,
      purchasedAt: json['purchasedAt'] != null
          ? DateTime.parse(json['purchasedAt'])
          : DateTime.now(),
    );
  }

  // Format transaction hash for display (show first and last 6 characters)
  String get shortTransactionHash {
    if (transactionHash.length > 12) {
      return '${transactionHash.substring(0, 6)}...${transactionHash.substring(transactionHash.length - 6)}';
    }
    return transactionHash;
  }
}
