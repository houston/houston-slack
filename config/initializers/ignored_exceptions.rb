Action.ignored_exceptions.concat [
  Slacks::ConnectionError,
  Slacks::Response::MigrationInProgress,
  Slacks::Response::RateLimited,
  Slacks::Response::RequestTimeout
]
