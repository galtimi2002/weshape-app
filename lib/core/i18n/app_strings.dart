/// Every user-facing string in the app.
///
/// A constructor with required named parameters means a string cannot be added
/// to English without the compiler demanding it in every language: missing
/// translations are a build error, not something to catch in review.
class AppStrings {
  const AppStrings({
    required this.tagline,
    required this.language,
    required this.switchToDark,
    required this.switchToLight,
    required this.welcomeBack,
    required this.signInSubtitle,
    required this.email,
    required this.password,
    required this.rememberMe,
    required this.forgotPassword,
    required this.signIn,
    required this.orDivider,
    required this.continueWithGoogle,
    required this.noAccount,
    required this.createAccount,
    required this.createAccountTitle,
    required this.signUpSubtitle,
    required this.firstName,
    required this.lastName,
    required this.country,
    required this.selectCountry,
    required this.searchCountry,
    required this.noResults,
    required this.languageHint,
    required this.confirmPassword,
    required this.passwordHint,
    required this.haveAccount,
    required this.completeProfileTitle,
    required this.completeProfileSubtitle,
    required this.saveAndContinue,
    required this.greeting,
    required this.greetingSubtitle,
    required this.contentPlaceholder,
    required this.yourCode,
    required this.copy,
    required this.copied,
    required this.signOut,
    required this.resetPasswordTitle,
    required this.resetPasswordBody,
    required this.send,
    required this.cancel,
    required this.resetPasswordSent,
    required this.fieldRequired,
    required this.invalidEmail,
    required this.passwordTooShort,
    required this.passwordsDoNotMatch,
    required this.errorInvalidCredentials,
    required this.errorEmailInUse,
    required this.errorTooManyRequests,
    required this.errorNetwork,
    required this.errorGeneric,
    required this.errorSessionExpired,
    required this.retry,
    required this.serverWakingUp,
    required this.serverWakingUpHint,
    required this.demoModeNotice,
  });

  final String tagline;
  final String language;
  final String switchToDark;
  final String switchToLight;
  final String welcomeBack;
  final String signInSubtitle;
  final String email;
  final String password;
  final String rememberMe;
  final String forgotPassword;
  final String signIn;
  final String orDivider;
  final String continueWithGoogle;
  final String noAccount;
  final String createAccount;
  final String createAccountTitle;
  final String signUpSubtitle;
  final String firstName;
  final String lastName;
  final String country;
  final String selectCountry;
  final String searchCountry;
  final String noResults;
  final String languageHint;
  final String confirmPassword;
  final String passwordHint;
  final String haveAccount;
  final String completeProfileTitle;
  final String completeProfileSubtitle;
  final String saveAndContinue;
  /// Use {name} where the first name goes.
  final String greeting;
  final String greetingSubtitle;
  final String contentPlaceholder;
  final String yourCode;
  final String copy;
  final String copied;
  final String signOut;
  final String resetPasswordTitle;
  final String resetPasswordBody;
  final String send;
  final String cancel;
  final String resetPasswordSent;
  final String fieldRequired;
  final String invalidEmail;
  final String passwordTooShort;
  final String passwordsDoNotMatch;
  final String errorInvalidCredentials;
  final String errorEmailInUse;
  final String errorTooManyRequests;
  final String errorNetwork;
  final String errorGeneric;
  final String errorSessionExpired;
  final String retry;
  final String serverWakingUp;
  final String serverWakingUpHint;
  final String demoModeNotice;

  /// "Hi, Ada" in the current language.
  String greet(String name) => greeting.replaceAll('{name}', name);
}
