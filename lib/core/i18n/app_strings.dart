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
    required this.resourceSolar,
    required this.resourceWind,
    required this.resourceHydro,
    required this.resourceGeothermal,
    required this.resourceBiomass,
    required this.comingSoon,
    required this.comingSoonMessage,
    required this.layerIrradiation,
    required this.layerPvProduction,
    required this.layerOptimumTilt,
    required this.irradiationTitle,
    required this.pvProductionTitle,
    required this.optimumTiltTitle,
    required this.legendIrradiation,
    required this.legendPvProduction,
    required this.legendOptimumTilt,
    required this.perYear,
    required this.searchAddress,
    required this.mapCountryHint,
    required this.mapClickHint,
    required this.selectedPoint,
    required this.exampleValuesNote,
    required this.south,
    required this.zoomIn,
    required this.zoomOut,
    required this.close,
    required this.noPlaceFound,
    required this.mapLoadFailed,
    required this.noSolarDataHere,
    required this.layerWindSpeed,
    required this.layerPowerDensity,
    required this.layerByHeight,
    required this.windSpeedTitle,
    required this.powerDensityTitle,
    required this.atHeight,
    required this.legendWindSpeed,
    required this.legendPowerDensity,
    required this.noWindDataHere,
    required this.layerHydroPotential,
    required this.layerRiverFlow,
    required this.layerHead,
    required this.hydroPotentialTitle,
    required this.riverFlowTitle,
    required this.headTitle,
    required this.legendHydroPotential,
    required this.legendRiverFlow,
    required this.legendHead,
    required this.riverAway,
    required this.driestMonth,
    required this.averageFlow,
    required this.wettestMonth,
    required this.noHydroDataHere,
    required this.ecologicalFlowNote,
    required this.flatReachNote,
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

  // Home: resource map
  final String resourceSolar;
  final String resourceWind;
  final String resourceHydro;
  final String resourceGeothermal;
  final String resourceBiomass;
  /// Short badge on resources that are not ready yet.
  final String comingSoon;
  /// Use {resource} where the resource name goes.
  final String comingSoonMessage;
  final String layerIrradiation;
  final String layerPvProduction;
  final String layerOptimumTilt;
  final String irradiationTitle;
  final String pvProductionTitle;
  final String optimumTiltTitle;
  final String legendIrradiation;
  final String legendPvProduction;
  final String legendOptimumTilt;
  final String perYear;
  final String searchAddress;
  /// Use {country} where the country name goes.
  final String mapCountryHint;
  final String mapClickHint;
  final String selectedPoint;
  final String exampleValuesNote;
  final String south;
  final String zoomIn;
  final String zoomOut;
  final String close;
  final String noPlaceFound;
  final String mapLoadFailed;
  final String noSolarDataHere;

  // Home: wind map
  final String layerWindSpeed;
  final String layerPowerDensity;
  final String layerByHeight;
  final String windSpeedTitle;
  final String powerDensityTitle;
  /// Use {height} where the height in metres goes.
  final String atHeight;
  /// Use {height} where the height in metres goes.
  final String legendWindSpeed;
  final String legendPowerDensity;
  final String noWindDataHere;
  final String layerHydroPotential;
  final String layerRiverFlow;
  final String layerHead;
  final String hydroPotentialTitle;
  final String riverFlowTitle;
  final String headTitle;
  final String legendHydroPotential;
  final String legendRiverFlow;
  final String legendHead;
  final String riverAway;
  final String driestMonth;
  final String averageFlow;
  final String wettestMonth;
  final String noHydroDataHere;
  final String ecologicalFlowNote;
  final String flatReachNote;

  /// "Hi, Ada" in the current language.
  String greet(String name) => greeting.replaceAll('{name}', name);

  /// "Wind is coming soon."
  String comingSoonFor(String resource) => comingSoonMessage.replaceAll('{resource}', resource);

  /// "Showing Romania from your profile. …"
  String mapCountryHintFor(String country) => mapCountryHint.replaceAll('{country}', country);

  /// "at 100 m"
  String atHeightFor(int height) => atHeight.replaceAll('{height}', '$height');

  /// "Mean wind speed at 100 m · m/s"
  String legendWindSpeedFor(int height) => legendWindSpeed.replaceAll('{height}', '$height');

  /// "River reach 0.4 km away"
  String riverAwayFor(String km) => riverAway.replaceAll('{km}', km);

  /// "10% of the mean flow stays in the river for nature."
  String ecologicalFlowNoteFor(int percent) => ecologicalFlowNote.replaceAll('{percent}', '$percent');
}
