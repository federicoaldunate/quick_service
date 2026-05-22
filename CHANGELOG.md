# Changelog

## [0.1.0] - 2026-05-21

### Added
- Initial release. `QuickService::Service` base class for the Service Object
  pattern.
- `success!` — a halting counterpart to `success`.
- `success!`/`fail!` halt via `throw`/`catch`, so the unwind cannot be
  swallowed by a `rescue` inside a service's `call`.
- `ServiceResult#[]` — a collision-free accessor that raises `KeyError` for
  unknown keys.
- `ServiceResult` implements `respond_to_missing?` and raises `NoMethodError`
  for unknown keys accessed via `.key`.
- `ServiceError` carries a descriptive message and the failed `ServiceResult`.
