class Failure implements Exception {
  final String error;

  Failure([this.error = "Unexpected error occurs"]);
  @override
  String toString() => "Errror : $error";
}
