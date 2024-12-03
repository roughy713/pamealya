class Profile {
  final String userId;
  final String firstName;
  final String lastName;
  final String? profession; // Optional for cases like cooks or others.

  Profile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profession,
  });

  // Factory constructor for creating a profile from a map (e.g., database record)
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      userId: map['user_id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      profession: map['profession'], // Optional field
    );
  }

  // Full name getter for convenience
  String get fullName => '$firstName $lastName';
}
