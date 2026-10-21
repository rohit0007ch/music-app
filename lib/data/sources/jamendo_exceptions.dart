/// Failures talking to or interpreting the Jamendo API.
sealed class JamendoException implements Exception {
  const JamendoException(this.message);
  final String message;

  @override
  String toString() => 'JamendoException: $message';
}

final class JamendoConfigException extends JamendoException {
  const JamendoConfigException(super.message);
}

final class JamendoHttpException extends JamendoException {
  const JamendoHttpException(super.message, {this.statusCode});
  final int? statusCode;
}

final class JamendoParseException extends JamendoException {
  const JamendoParseException(super.message);
}

final class JamendoApiException extends JamendoException {
  const JamendoApiException(super.message, {this.code});
  final int? code;
}
