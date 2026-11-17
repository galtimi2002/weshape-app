import 'package:flutter/widgets.dart';

/// A password field's text drawn as dots while [obscure], without making the field a browser
/// password field. A browser password field brings the browsers' own pop-ups: "suggested strong
/// password" on registration, and "save your password?" even after a sign-in that failed. Saving is
/// asked for by the app instead, after a sign-in that worked (credential_store.dart).
class MaskedController extends TextEditingController {
  bool obscure = true;

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (!obscure) return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    // One dot per UTF-16 unit, so the cursor and selection stay where they are in the text.
    return TextSpan(style: style, text: '•' * text.length);
  }
}
