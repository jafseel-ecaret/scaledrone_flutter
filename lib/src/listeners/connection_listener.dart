abstract class ConnectionListener {
  void onOpen();
  void onOpenFailure(Exception ex);
  void onFailure(Exception ex);
  void onClosed(String reason);
}
