/// Base URL of the backend (no trailing slash).
///
/// Production by default for every build. To point at a local server use
/// `--dart-define=API_BASE_URL=http://127.0.0.1:8002`.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://admin.deineputzcrew.de',
);
