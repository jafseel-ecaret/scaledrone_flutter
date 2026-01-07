// Connection callbacks
typedef OnOpenCallback = void Function();
typedef OnOpenFailureCallback = void Function(Exception ex);
typedef OnFailureCallback = void Function(Exception ex);
typedef OnClosedCallback = void Function(String reason);
