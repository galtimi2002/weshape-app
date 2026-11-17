import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('PasswordCredential')
extension type _PasswordCredential._(JSObject _) implements JSObject {
  external factory _PasswordCredential(_PasswordData data);
  external String get id;
  external String? get password;
}

extension type _PasswordData._(JSObject _) implements JSObject {
  external factory _PasswordData({String id, String password});
}

extension type _GetOptions._(JSObject _) implements JSObject {
  external factory _GetOptions({bool password, String mediation});
}

@JS('navigator.credentials')
external _Credentials? get _credentials;

extension type _Credentials._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> store(JSObject credential);
  external JSPromise<JSAny?> get(_GetOptions options);
}

bool get _supported => globalContext.has('PasswordCredential') && _credentials != null;

Future<void> save(String email, String password) async {
  if (!_supported || email.trim().isEmpty || password.isEmpty) return;
  try {
    await _credentials!.store(_PasswordCredential(_PasswordData(id: email.trim(), password: password))).toDart;
  } catch (_) {
    // The person said no, or the browser refused: nothing to do.
  }
}

Future<({String email, String password})?> pick() async {
  if (!_supported) return null;
  try {
    final result = await _credentials!.get(_GetOptions(password: true, mediation: 'optional')).toDart;
    if (result == null || !(result as JSObject).has('password')) return null;
    final c = result as _PasswordCredential;
    final password = c.password;
    if (password == null || password.isEmpty) return null;
    return (email: c.id, password: password);
  } catch (_) {
    return null;
  }
}
