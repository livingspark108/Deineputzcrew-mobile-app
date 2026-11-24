/// Base URL of the backend (no trailing slash).
///
/// Production by default for every build. To point at a local server use
/// `--dart-define=API_BASE_URL=http://127.0.0.1:8002`.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://admin.deineputzcrew.de',
);

/// How long a manual punch-in / punch-out waits for the server (photo upload
/// + answer). Past this, the punch is saved offline and delivered by the
/// offline sync instead.
const Duration kPunchRequestTimeout = Duration(minutes: 1);
