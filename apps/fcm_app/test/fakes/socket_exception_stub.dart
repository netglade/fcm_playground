/// Stands in for the socket failure a missing port forward produces, without
/// needing `dart:io` in a test that otherwise does not.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();

  @override
  String toString() => 'Connection refused';
}
