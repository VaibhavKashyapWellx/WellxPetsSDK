/// WellxPetsSDK - Embeddable pet health module for the Wellx platform.
///
/// Usage:
/// ```dart
/// final sdk = await WellxPetsSDK.initialize(
///   config: WellxPetsConfig(...),
///   authDelegate: myAuthDelegate,
///   xCoinDelegate: myXCoinDelegate,
/// );
/// // Embed in your widget tree:
/// sdk.buildRootWidget()
/// ```
library;

// SDK interface
export 'src/sdk/wellx_pets_sdk.dart';
export 'src/sdk/wellx_pets_config.dart';
export 'src/sdk/auth_delegate.dart';
export 'src/sdk/xcoin_delegate.dart';
