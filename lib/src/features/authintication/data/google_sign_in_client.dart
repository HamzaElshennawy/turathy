import 'package:google_sign_in/google_sign_in.dart';

/// Builds the shared Google Sign-In client used across interactive and silent auth flows.
GoogleSignIn buildGoogleSignInClient() {
  const fallbackServerClientId =
      '214584571316-0e25d07432f64jo817isd9hkusq87ppd.apps.googleusercontent.com';
  const configuredServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: fallbackServerClientId,
  );

  return GoogleSignIn(
    serverClientId: configuredServerClientId.isEmpty
        ? null
        : configuredServerClientId,
  );
}
