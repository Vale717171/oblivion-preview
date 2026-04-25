class AppLogger {
  const AppLogger._();

  static void log(String tag, Object? message, [StackTrace? stack]) {
    // ignore: avoid_print
    print('[$tag] $message');
    if (stack != null) {
      // ignore: avoid_print
      print(stack);
    }
  }
}
