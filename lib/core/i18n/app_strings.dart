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
    required this.layerGroundTemp,
    required this.layerAtDepth,
    required this.layerHeatFlow,
    required this.groundTempTitle,
    required this.depthTempTitle,
    required this.heatFlowTitle,
    required this.legendGroundTemp,
    required this.legendDepthTemp,
    required this.legendHeatFlow,
    required this.nearSurface,
    required this.noGeoDataHere,
    required this.noHeatFlowNearby,
    required this.depthEstimateNote,
    required this.layerBioDensity,
    required this.layerBioResource,
    required this.layerBioEnergy,
    required this.bioDensityTitle,
    required this.bioResourceTitle,
    required this.bioEnergyTitle,
    required this.legendBioDensity,
    required this.legendBioResource,
    required this.legendBioEnergy,
    required this.withinRadius,
    required this.cropResidues,
    required this.forestResidues,
    required this.homesHeated,
    required this.bioNote,
    required this.noBioDataHere,
    required this.navMap,
    required this.navAssessment,
    required this.navSaved,
    required this.navSavedShort,
    required this.assessStep,
    required this.assessTitle,
    required this.assessHint,
    required this.assessHome,
    required this.assessHomeDesc,
    required this.assessBusiness,
    required this.assessBusinessDesc,
    required this.assessCommunity,
    required this.assessCommunityDesc,
    required this.assessExplore,
    required this.assessExploreDesc,
    required this.assessContinue,
    required this.assessStepsSoon,
    required this.savedTitle,
    required this.savedHint,
    required this.savedNew,
    required this.savedEmpty,
    required this.savedEmptyHint,
    required this.savedCompare,
    required this.savedCompareHint,
    required this.stepOf,
    required this.back,
    required this.seeResult,
    required this.resultSoon,
    required this.placeTitle,
    required this.placeHint,
    required this.placeFromMap,
    required this.placePickOnMap,
    required this.placeChosen,
    required this.assessThisPlace,
    required this.buildingTitle,
    required this.buildingHint,
    required this.typeLabel,
    required this.typeHouse,
    required this.typeFlat,
    required this.floorsLabel,
    required this.peopleLabel,
    required this.areaLabel,
    required this.condTitle,
    required this.condHint,
    required this.builtLabel,
    required this.eraBefore1960,
    required this.era1960,
    required this.era1990,
    required this.era2010,
    required this.wallsLabel,
    required this.wallBrick,
    required this.wallPanel,
    required this.wallAerated,
    required this.wallWood,
    required this.wallStone,
    required this.insLabel,
    required this.insNone,
    required this.insThin,
    required this.insThick,
    required this.windowsLabel,
    required this.winSingle,
    required this.winDouble,
    required this.winTriple,
    required this.condUnknown,
    required this.heatTitle,
    required this.heatHint,
    required this.heatGas,
    required this.heatWood,
    required this.heatElectric,
    required this.heatDistrict,
    required this.heatPump,
    required this.elecTitle,
    required this.elecHint,
    required this.kwhPerMonth,
    required this.kwhPerYearAbout,
    required this.elecUnknown,
    required this.elecKnown,
    required this.elecEstimated,
    required this.spaceTitle,
    required this.spaceHint,
    required this.hasRoof,
    required this.hasRoofDesc,
    required this.hasGarden,
    required this.hasGardenDesc,
    required this.hasLand,
    required this.hasLandDesc,
    required this.hasStream,
    required this.hasStreamDesc,
    required this.hasBalcony,
    required this.hasBalconyDesc,
    required this.roofSizeLabel,
    required this.roofSmall,
    required this.roofMedium,
    required this.roofLarge,
    required this.facingLabel,
    required this.faceSouth,
    required this.faceEastWest,
    required this.faceNorth,
    required this.aimLabel,
    required this.aimBills,
    required this.aimIndep,
    required this.aimCo2,
    required this.pickOnMapHint,
    required this.pickConfirm,
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
  final String layerGroundTemp;
  final String layerAtDepth;
  final String layerHeatFlow;
  final String groundTempTitle;
  final String depthTempTitle;
  final String heatFlowTitle;
  final String legendGroundTemp;
  final String legendDepthTemp;
  final String legendHeatFlow;
  final String nearSurface;
  final String noGeoDataHere;
  final String noHeatFlowNearby;
  final String depthEstimateNote;
  final String layerBioDensity;
  final String layerBioResource;
  final String layerBioEnergy;
  final String bioDensityTitle;
  final String bioResourceTitle;
  final String bioEnergyTitle;
  final String legendBioDensity;
  final String legendBioResource;
  final String legendBioEnergy;
  final String withinRadius;
  final String cropResidues;
  final String forestResidues;
  final String homesHeated;
  final String bioNote;
  final String noBioDataHere;

  /// Header tabs: the map, the assessment, the saved assessments (short form on phones).
  final String navMap;
  final String navAssessment;
  final String navSaved;
  final String navSavedShort;

  /// Assessment start page.
  final String assessStep;
  final String assessTitle;
  final String assessHint;
  final String assessHome;
  final String assessHomeDesc;
  final String assessBusiness;
  final String assessBusinessDesc;
  final String assessCommunity;
  final String assessCommunityDesc;
  final String assessExplore;
  final String assessExploreDesc;
  final String assessContinue;
  final String assessStepsSoon;

  /// Saved assessments page.
  final String savedTitle;
  final String savedHint;
  final String savedNew;
  final String savedEmpty;
  final String savedEmptyHint;
  final String savedCompare;
  final String savedCompareHint;

  /// The home assessment's six steps.
  final String stepOf;
  final String back;
  final String seeResult;
  final String resultSoon;
  final String placeTitle;
  final String placeHint;
  final String placeFromMap;
  final String placePickOnMap;
  final String placeChosen;
  final String assessThisPlace;
  final String buildingTitle;
  final String buildingHint;
  final String typeLabel;
  final String typeHouse;
  final String typeFlat;
  final String floorsLabel;
  final String peopleLabel;
  final String areaLabel;
  final String condTitle;
  final String condHint;
  final String builtLabel;
  final String eraBefore1960;
  final String era1960;
  final String era1990;
  final String era2010;
  final String wallsLabel;
  final String wallBrick;
  final String wallPanel;
  final String wallAerated;
  final String wallWood;
  final String wallStone;
  final String insLabel;
  final String insNone;
  final String insThin;
  final String insThick;
  final String windowsLabel;
  final String winSingle;
  final String winDouble;
  final String winTriple;
  final String condUnknown;
  final String heatTitle;
  final String heatHint;
  final String heatGas;
  final String heatWood;
  final String heatElectric;
  final String heatDistrict;
  final String heatPump;
  final String elecTitle;
  final String elecHint;
  final String kwhPerMonth;
  final String kwhPerYearAbout;
  final String elecUnknown;
  final String elecKnown;
  final String elecEstimated;
  final String spaceTitle;
  final String spaceHint;
  final String hasRoof;
  final String hasRoofDesc;
  final String hasGarden;
  final String hasGardenDesc;
  final String hasLand;
  final String hasLandDesc;
  final String hasStream;
  final String hasStreamDesc;
  final String hasBalcony;
  final String hasBalconyDesc;
  final String roofSizeLabel;
  final String roofSmall;
  final String roofMedium;
  final String roofLarge;
  final String facingLabel;
  final String faceSouth;
  final String faceEastWest;
  final String faceNorth;
  final String aimLabel;
  final String aimBills;
  final String aimIndep;
  final String aimCo2;

  /// Banner on the map while a place is being chosen for the assessment.
  final String pickOnMapHint;
  final String pickConfirm;

  /// "Hi, Ada" in the current language.
  String greet(String name) => greeting.replaceAll('{name}', name);

  /// "Wind is coming soon."
  String stepOfN(int n) => stepOf.replaceAll('{n}', '$n');
  String kwhPerYearAboutN(String n) => kwhPerYearAbout.replaceAll('{n}', n);
  String elecEstimatedFor(int people, String n) =>
      elecEstimated.replaceAll('{people}', '$people').replaceAll('{n}', n);
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

  /// "Temperature at 2 km depth"
  String depthTempTitleFor(int depth) => depthTempTitle.replaceAll('{depth}', '$depth');

  /// "Estimated temperature at 2 km depth · °C"
  String legendDepthTempFor(int depth) => legendDepthTemp.replaceAll('{depth}', '$depth');

  /// "Temperature at depth = ground temperature + heat flow ÷ 2.5 W/m·K × depth: …"
  String depthEstimateNoteFor(String conductivity) => depthEstimateNote.replaceAll('{k}', conductivity);

  /// "within 25 km, per year"
  String withinRadiusFor(int km) => withinRadius.replaceAll('{km}', '$km');

  /// "≈ 59,400 family homes heated for a year"
  String homesHeatedFor(String n) => homesHeated.replaceAll('{n}', n);
}
