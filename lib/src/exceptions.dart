/// An exception for file system errors
class FileSystemException implements Exception {
  /// Provide a message
  FileSystemException(this.message);

  /// The error message
  final String message;
}
