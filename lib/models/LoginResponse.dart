class LoginResponse {

  final String token;
  final String username;
  final int expiresIn;

  LoginResponse({
    required this.token,
    required this.username,
    required this.expiresIn
  });



  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String? ?? '',
      username: json['username'] as String? ?? '',
      expiresIn: json['expiresIn'] as int? ?? 0
    );
  }
}