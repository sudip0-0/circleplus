import 'dart:math';

const _inviteAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

String generateInviteCode({Random? random}) {
  final source = random ?? Random.secure();

  return List.generate(
    6,
    (_) => _inviteAlphabet[source.nextInt(_inviteAlphabet.length)],
  ).join();
}

bool isValidInviteCode(String code) {
  return RegExp(r'^[A-Z0-9]{6}$').hasMatch(code);
}
