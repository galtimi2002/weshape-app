import 'credential_store_stub.dart' if (dart.library.js_interop) 'credential_store_web.dart' as impl;

/// The browser's saved passwords, through the Credential Management API (Chrome, Edge and other
/// Chromium browsers; elsewhere nothing happens). Used instead of a browser password field, so the
/// browser offers to save only after a sign-in that worked.
abstract final class CredentialStore {
  /// Offers to save the email and password (the browser asks the person). Call after a sign-in
  /// that worked.
  static Future<void> save(String email, String password) => impl.save(email, password);

  /// Lets the person pick a saved email and password (the browser shows its own chooser); null when
  /// there is none, the person closes it, or the browser cannot.
  static Future<({String email, String password})?> pick() => impl.pick();
}
