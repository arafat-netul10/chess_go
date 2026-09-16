class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final int eloRating;
  final int wins;
  final int losses;
  final int draws;
  final bool isGuest;

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl = '',
    this.eloRating = 1200,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.isGuest = false,
  });

  int get totalGames => wins + losses + draws;

  double get winRate =>
      totalGames > 0 ? (wins / totalGames) * 100 : 0.0;

  factory UserProfile.guest() {
    return const UserProfile(
      id: 'guest',
      username: 'GuestPlayer',
      displayName: 'Guest Player',
      isGuest: true,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'Player',
      displayName: json['display_name'] as String? ?? 'Player',
      avatarUrl: json['avatar_url'] as String? ?? '',
      eloRating: json['elo_rating'] as int? ?? 1200,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      isGuest: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'elo_rating': eloRating,
        'wins': wins,
        'losses': losses,
        'draws': draws,
      };

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    int? eloRating,
    int? wins,
    int? losses,
    int? draws,
    bool? isGuest,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      eloRating: eloRating ?? this.eloRating,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}
