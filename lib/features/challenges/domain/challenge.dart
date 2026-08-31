enum ChallengeType {
  normal,
  wild,
  pvp;

  static ChallengeType fromJson(String value) {
    return ChallengeType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw FormatException('Unsupported challenge type: $value'),
    );
  }
}

class Challenge {
  const Challenge({required this.id, required this.text, required this.type});

  final String id;
  final String text;
  final ChallengeType type;

  factory Challenge.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final text = json['text'];
    final type = json['type'];

    if (id is! String || text is! String || type is! String) {
      throw const FormatException(
        'A challenge must contain string id, text, and type fields.',
      );
    }

    return Challenge(id: id, text: text, type: ChallengeType.fromJson(type));
  }
}
