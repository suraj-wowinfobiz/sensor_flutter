# Sensor Platform Flutter

Flutter admin dashboard for the sensor monitoring platform.

## What is implemented

- Role-based routing for `SUPER_SUPER_ADMIN`, `SUPER_ADMIN`, `ADMIN`, `ENGINEER`, `USER`
- Tenant scope state (`organization_id`, `site_id`, `zone_id`)
- REST API client for backend endpoints under `/api`
- Alerts list with resolve action
- Sensor readings graph (time-series)
- Engineer diagnostics loading features and predictions
- Admin and super-admin management screens scaffold

## Run locally with Flutter

1. Install Flutter.
2. Fetch dependencies:
   - `flutter pub get`
3. Run the app:
   - `flutter run`

Local API defaults:
- Web/Desktop will call `http://localhost:8091`
- Android emulator will call `http://10.0.2.2:8091`

Override manually when needed:
- `flutter run --dart-define=ADMIN_API_BASE_URL=http://localhost:8091`
- Add the same pattern for `USER_API_BASE_URL`, `USER_ADMIN_API_BASE_URL`, `ENGINEER_API_BASE_URL`, and `VENDOR_API_BASE_URL` if you want to point roles at different services

## Run with Docker

This project is set up to run as a Flutter Web app inside Docker.

### Quick start

1. Build and start:
   - `docker compose up --build`
2. Open:
   - `http://localhost:8080`

### Change backend URLs

The Docker build supports per-role API endpoints through build args.

Example:

```bash
ADMIN_API_BASE_URL=http://host.docker.internal:8091 \
USER_API_BASE_URL=http://host.docker.internal:8091 \
USER_ADMIN_API_BASE_URL=http://host.docker.internal:8091 \
ENGINEER_API_BASE_URL=http://host.docker.internal:8091 \
VENDOR_API_BASE_URL=http://host.docker.internal:8091 \
APP_PORT=8080 \
docker compose up --build
```

You can also place those values in a `.env` file next to `docker-compose.yml`.

### Build image manually

```bash
docker build \
  --build-arg ADMIN_API_BASE_URL=http://host.docker.internal:8091 \
  --build-arg USER_API_BASE_URL=http://host.docker.internal:8091 \
  --build-arg USER_ADMIN_API_BASE_URL=http://host.docker.internal:8091 \
  --build-arg ENGINEER_API_BASE_URL=http://host.docker.internal:8091 \
  --build-arg VENDOR_API_BASE_URL=http://host.docker.internal:8091 \
  -t sensor-platform-flutter .
docker run --rm -p 8080:80 sensor-platform-flutter
```

## Notes

- The Docker image serves the compiled Flutter Web app through Nginx.
- API URLs are configurable with Dart defines, so you do not need to edit Dart source for each environment.
- This app intentionally maps schema-backed API resources only.
- `users.role` mapping is preserved:
  - `operator -> USER`
  - `engineer -> ENGINEER`
  - `admin -> ADMIN`
- `SUPER_ADMIN` and `SUPER_SUPER_ADMIN` are expected from token claims.
