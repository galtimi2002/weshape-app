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
    required this.assessContinue,
    required this.savedTitle,
    required this.savedHint,
    required this.savedNew,
    required this.savedEmpty,
    required this.savedEmptyHint,
    required this.savedCompare,
    required this.savedCompareHint,
    required this.back,
    required this.seeResult,
    required this.resultSoon,
    required this.placeTitle,
    required this.placeHint,
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
    required this.eraBefore1960,
    required this.era1960,
    required this.era1990,
    required this.era2010,
    required this.insNone,
    required this.insThin,
    required this.insThick,
    required this.winSingle,
    required this.winTriple,
    required this.roofSmall,
    required this.roofMedium,
    required this.roofLarge,
    required this.faceSouth,
    required this.faceEastWest,
    required this.faceNorth,
    required this.pickOnMapHint,
    required this.pickConfirm,
    required this.stepOfTotal,
    required this.toFirst,
    required this.resetAnswers,
    required this.resetTitle,
    required this.resetBody,
    required this.resetConfirm,
    required this.oneMore,
    required this.confirmTitle,
    required this.confirmBody,
    required this.confirmCheck,
    required this.confirmGo,
    required this.assessIntro,
    required this.audTitle,
    required this.audHome,
    required this.audHomeDesc,
    required this.audFarm,
    required this.audFarmDesc,
    required this.audBusiness,
    required this.audBusinessDesc,
    required this.audCommunity,
    required this.audCommunityDesc,
    required this.audVillage,
    required this.audVillageDesc,
    required this.audSite,
    required this.audSiteDesc,
    required this.usesTitle,
    required this.useAppliances,
    required this.useCooking,
    required this.useHeating,
    required this.useHotWater,
    required this.useCar,
    required this.usePumping,
    required this.eraTitle,
    required this.eraTitleFlat,
    required this.dontKnow,
    required this.renoTitle,
    required this.renoWalls,
    required this.renoRoof,
    required this.renoWindows,
    required this.renoHeating,
    required this.renoNone,
    required this.renoWhen,
    required this.ageRecent,
    required this.ageMiddle,
    required this.ageOld,
    required this.insTitle,
    required this.insWalls,
    required this.insRoof,
    required this.insFloor,
    required this.insMedium,
    required this.insInsulated,
    required this.helpCheck,
    required this.takePhoto,
    required this.insHelpWalls,
    required this.insHelpRoof,
    required this.insHelpFloor,
    required this.winTitle,
    required this.winDoubleOld,
    required this.winDoubleNew,
    required this.winMix,
    required this.winHelpPanes,
    required this.winHelpDate,
    required this.srcTitle,
    required this.srcMains,
    required this.srcPipedGas,
    required this.srcDistrict,
    required this.srcBottles,
    required this.srcWood,
    required this.srcGenerator,
    required this.srcNothing,
    required this.cutsTitle,
    required this.cutsNever,
    required this.cutsHardly,
    required this.cutsMonthly,
    required this.cutsDaily,
    required this.elecUseTitle,
    required this.monthNames,
    required this.dontKnowExact,
    required this.knowExact,
    required this.avgElecQuestion,
    required this.avgNote,
    required this.tooHigh,
    required this.sameMonthTwice,
    required this.billPhoto,
    required this.paidTitle,
    required this.avgPaidQuestion,
    required this.currencyLabel,
    required this.gasTitle,
    required this.gasUnitLabel,
    required this.gasUsed,
    required this.gasPaid,
    required this.unitLooksKwh,
    required this.unitLooksM3,
    required this.yes,
    required this.no,
    required this.fuelsTitle,
    required this.fuelFirewood,
    required this.fuelPellets,
    required this.fuelBottles,
    required this.fuelDistrict,
    required this.spacesTitle,
    required this.spacesHint,
    required this.spRoof,
    required this.spGarden,
    required this.spLand,
    required this.spBalcony,
    required this.spNotSure,
    required this.spNowhere,
    required this.sizesTitle,
    required this.notSureNote,
    required this.sizeRoofLabel,
    required this.aboutM2,
    required this.exactSize,
    required this.facingQuestion,
    required this.faceFlat,
    required this.sizeGardenLabel,
    required this.sizeLandLabel,
    required this.sizeBalconyLabel,
    required this.landSmall,
    required this.landMedium,
    required this.landLarge,
    required this.noGarden,
    required this.drawOnMap,
    required this.balconySmall,
    required this.balconyLarge,
    required this.ownTitle,
    required this.ownHint,
    required this.ownYes,
    required this.ownBuilding,
    required this.ownRent,
    required this.ownShared,
    required this.fixTitle,
    required this.fixHint,
    required this.fixSelf,
    required this.fixTech,
    required this.fixInstaller,
    required this.fixUnknown,
    required this.handsTitle,
    required this.handsNone,
    required this.handsLittle,
    required this.handsRegular,
    required this.prioTitle,
    required this.prioUpfront,
    required this.prioUpfrontDesc,
    required this.prioRunning,
    required this.prioRunningDesc,
    required this.prioReliable,
    required this.prioReliableDesc,
    required this.prioEnv,
    required this.prioEnvDesc,
    required this.prioBalanced,
    required this.prioBalancedDesc,
    required this.followTitle,
    required this.animalsQ,
    required this.animFew,
    required this.animHerd,
    required this.animWaste,
    required this.animNone,
    required this.riverFound,
    required this.riverThrough,
    required this.riverOthers,
    required this.riverCannot,
    required this.riverNotSure,
    required this.brookQ,
    required this.windFound,
    required this.windOpen,
    required this.windSome,
    required this.windLots,
    required this.checkingMap,
    required this.nothingMore,
    required this.exclTitle,
    required this.exclNo,
    required this.exclYes,
    required this.exclTapHint,
    required this.exclSketchNote,
    required this.exclSketchNoteHouse,
    required this.roofShapeLabel,
    required this.roofGable,
    required this.roofHip,
    required this.zoneRoofWhole,
    required this.zoneSideLeft,
    required this.zoneSideRight,
    required this.rotateLeft,
    required this.rotateRight,
    required this.roofHidden,
    required this.markModeLabel,
    required this.markKeepFree,
    required this.markMissing,
    required this.keepFreeList,
    required this.missingList,
    required this.newKindQ,
    required this.newBuilding,
    required this.newPool,
    required this.newTrees,
    required this.newOther,
    required this.newWhereQ,
    required this.newTitle,
    required this.newNo,
    required this.newYes,
    required this.newWhereHint,
    required this.newUseQ,
    required this.zoneRoofFront,
    required this.zoneRoofBack,
    required this.zoneRoofLeft,
    required this.zoneRoofRight,
    required this.zoneFrontYard,
    required this.zoneBackYard,
    required this.markOnMap,
    required this.whyLabel,
    required this.whyUnsafe,
    required this.whyReach,
    required this.whyLooks,
    required this.whyRules,
    required this.whyPlans,
    required this.dirFront,
    required this.fuelsHint,
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
  final String assessContinue;

  /// Saved assessments page.
  final String savedTitle;
  final String savedHint;
  final String savedNew;
  final String savedEmpty;
  final String savedEmptyHint;
  final String savedCompare;
  final String savedCompareHint;

  /// The home assessment's six steps.
  final String back;
  final String seeResult;
  final String resultSoon;
  final String placeTitle;
  final String placeHint;
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
  final String eraBefore1960;
  final String era1960;
  final String era1990;
  final String era2010;
  final String insNone;
  final String insThin;
  final String insThick;
  final String winSingle;
  final String winTriple;
  final String roofSmall;
  final String roofMedium;
  final String roofLarge;
  final String faceSouth;
  final String faceEastWest;
  final String faceNorth;

  /// Banner on the map while a place is being chosen for the assessment.
  final String pickOnMapHint;
  final String pickConfirm;
  final String stepOfTotal;
  final String toFirst;
  final String resetAnswers;
  final String resetTitle;
  final String resetBody;
  final String resetConfirm;
  final String oneMore;
  final String confirmTitle;
  final String confirmBody;
  final String confirmCheck;
  final String confirmGo;
  final String assessIntro;
  final String audTitle;
  final String audHome;
  final String audHomeDesc;
  final String audFarm;
  final String audFarmDesc;
  final String audBusiness;
  final String audBusinessDesc;
  final String audCommunity;
  final String audCommunityDesc;
  final String audVillage;
  final String audVillageDesc;
  final String audSite;
  final String audSiteDesc;
  final String usesTitle;
  final String useAppliances;
  final String useCooking;
  final String useHeating;
  final String useHotWater;
  final String useCar;
  final String usePumping;
  final String eraTitle;
  final String eraTitleFlat;
  final String dontKnow;
  final String renoTitle;
  final String renoWalls;
  final String renoRoof;
  final String renoWindows;
  final String renoHeating;
  final String renoNone;
  final String renoWhen;
  final String ageRecent;
  final String ageMiddle;
  final String ageOld;
  final String insTitle;
  final String insWalls;
  final String insRoof;
  final String insFloor;
  final String insMedium;
  final String insInsulated;
  final String helpCheck;
  final String takePhoto;
  final String insHelpWalls;
  final String insHelpRoof;
  final String insHelpFloor;
  final String winTitle;
  final String winDoubleOld;
  final String winDoubleNew;
  final String winMix;
  final String winHelpPanes;
  final String winHelpDate;
  final String srcTitle;
  final String srcMains;
  final String srcPipedGas;
  final String srcDistrict;
  final String srcBottles;
  final String srcWood;
  final String srcGenerator;
  final String srcNothing;
  final String cutsTitle;
  final String cutsNever;
  final String cutsHardly;
  final String cutsMonthly;
  final String cutsDaily;
  final String elecUseTitle;
  final String monthNames;
  final String dontKnowExact;
  final String knowExact;
  final String avgElecQuestion;
  final String avgNote;
  final String tooHigh;
  final String sameMonthTwice;
  final String billPhoto;
  final String paidTitle;
  final String avgPaidQuestion;
  final String currencyLabel;
  final String gasTitle;
  final String gasUnitLabel;
  final String gasUsed;
  final String gasPaid;
  final String unitLooksKwh;
  final String unitLooksM3;
  final String yes;
  final String no;
  final String fuelsTitle;
  final String fuelFirewood;
  final String fuelPellets;
  final String fuelBottles;
  final String fuelDistrict;
  final String spacesTitle;
  final String spacesHint;
  final String spRoof;
  final String spGarden;
  final String spLand;
  final String spBalcony;
  final String spNotSure;
  final String spNowhere;
  final String sizesTitle;
  final String notSureNote;
  final String sizeRoofLabel;
  final String aboutM2;
  final String exactSize;
  final String facingQuestion;
  final String faceFlat;
  final String sizeGardenLabel;
  final String sizeLandLabel;
  final String sizeBalconyLabel;
  final String landSmall;
  final String landMedium;
  final String landLarge;
  final String noGarden;
  final String drawOnMap;
  final String balconySmall;
  final String balconyLarge;
  final String ownTitle;
  final String ownHint;
  final String ownYes;
  final String ownBuilding;
  final String ownRent;
  final String ownShared;
  final String fixTitle;
  final String fixHint;
  final String fixSelf;
  final String fixTech;
  final String fixInstaller;
  final String fixUnknown;
  final String handsTitle;
  final String handsNone;
  final String handsLittle;
  final String handsRegular;
  final String prioTitle;
  final String prioUpfront;
  final String prioUpfrontDesc;
  final String prioRunning;
  final String prioRunningDesc;
  final String prioReliable;
  final String prioReliableDesc;
  final String prioEnv;
  final String prioEnvDesc;
  final String prioBalanced;
  final String prioBalancedDesc;
  final String followTitle;
  final String animalsQ;
  final String animFew;
  final String animHerd;
  final String animWaste;
  final String animNone;
  final String riverFound;
  final String riverThrough;
  final String riverOthers;
  final String riverCannot;
  final String riverNotSure;
  final String brookQ;
  final String windFound;
  final String windOpen;
  final String windSome;
  final String windLots;
  final String checkingMap;
  final String nothingMore;
  final String exclTitle;
  final String exclNo;
  final String exclYes;
  final String exclTapHint;
  final String exclSketchNote;
  final String exclSketchNoteHouse;
  final String roofShapeLabel;
  final String roofGable;
  final String roofHip;
  final String zoneRoofWhole;
  final String zoneSideLeft;
  final String zoneSideRight;
  final String rotateLeft;
  final String rotateRight;
  final String roofHidden;
  final String markModeLabel;
  final String markKeepFree;
  final String markMissing;
  final String keepFreeList;
  final String missingList;
  final String newKindQ;
  final String newBuilding;
  final String newPool;
  final String newTrees;
  final String newOther;
  final String newWhereQ;
  final String newTitle;
  final String newNo;
  final String newYes;
  final String newWhereHint;
  final String newUseQ;
  final String zoneRoofFront;
  final String zoneRoofBack;
  final String zoneRoofLeft;
  final String zoneRoofRight;
  final String zoneFrontYard;
  final String zoneBackYard;
  final String markOnMap;
  final String whyLabel;
  final String whyUnsafe;
  final String whyReach;
  final String whyLooks;
  final String whyRules;
  final String whyPlans;
  final String dirFront;
  final String fuelsHint;

  /// "Hi, Ada" in the current language.
  String greet(String name) => greeting.replaceAll('{name}', name);

  /// "Step 3 of 14"
  String stepOfTotalFor(int n, int total) => stepOfTotal.replaceAll('{n}', '$n').replaceAll('{total}', '$total');

  /// "about 60 m²"
  String aboutM2For(int n) => aboutM2.replaceAll('{n}', '$n');

  /// "We found a river about 350 m from your place. …"
  String riverFoundFor(int metres) => riverFound.replaceAll('{m}', '$metres');

  /// "The wind here is about 4.2 m/s at 20 m height. …"
  String windFoundFor(String speed) => windFound.replaceAll('{speed}', speed);

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
