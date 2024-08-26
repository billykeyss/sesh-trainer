class LeaderboardEntry {
  final int? id;
  final String name;
  final String email;
  final double maxWeight;
  final String gender;
  final DateTime date;

  LeaderboardEntry({
    this.id,
    required this.name,
    required this.email,
    required this.maxWeight,
    required this.gender,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'maxWeight': maxWeight,
      'gender': gender,
      'date': date.toIso8601String(),
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      maxWeight: map['maxWeight'],
      gender: map['gender'],
      date: DateTime.parse(map['date']),
    );
  }
}
