# Sensor Platform Flutter

Flutter conversion of the mobile layer for the sensor monitoring platform.

## What is implemented

- Role-based routing for `SUPER_SUPER_ADMIN`, `SUPER_ADMIN`, `ADMIN`, `ENGINEER`, `USER`
- Tenant scope state (`organization_id`, `site_id`, `zone_id`)
- REST API client for backend endpoints under `/api`
- Alerts list with resolve action
- Sensor readings graph (time-series)
- Engineer diagnostics loading features + predictions
- Admin and super-admin management screens scaffold

## Run

1. Ensure backend is running (`backend/` service).
2. Update API URL in `lib/api/api_client.dart`.
3. Install deps:
   - `flutter pub get`
4. Launch:
   - `flutter run`

## Notes

- This app intentionally maps schema-backed API resources only.
- `users.role` mapping is preserved:
  - `operator -> USER`
  - `engineer -> ENGINEER`
  - `admin -> ADMIN`
- `SUPER_ADMIN` and `SUPER_SUPER_ADMIN` are expected from token claims.
