# Services API Documentation (Frontend Integration)

This document is generated from current controller and DTO code in this repository.

Base gateway URL:
- `http://<host>:8091`

All paths below are gateway paths.

## 1. Authentication Service

Base paths:
- `/api/v1/auth`
- `/api/v1/super-admins`
- `/api/v1/admins`
- `/api/v1/users`
- `/api/v1/vendors`
- `/api/v1/vendors-engineer`

Response envelope (`MessageResponseDTO`):
```json
{
  "message": "string",
  "status": "SUCCESS|FAILED",
  "body": {}
}
```

Request DTOs:
- `LoginRequest`: `{ "email": "string", "password": "string", "role": "string" }`
- `OtpRequest`: `{ "email": "string" }`
- `SuperAdminOtpCreateRequest`: `{ "name": "string", "email": "string", "password": "string", "otp": "string" }`
- `SuperAdminCreateRequest`: `{ "name": "string", "email": "string", "password": "string" }`
- `AdminCreateRequest`: `{ "name": "string", "email": "string", "password": "string", "maxUsersAllowed": 0, "organizationId": 0 }`
- `UserCreateRequest`: `{ "name": "string", "email": "string", "password": "string", "organizationId": 0 }`
- `VendorCreateRequest`: `{ "name": "string", "email": "string", "password": "string", "organizationId": 0 }`
- `VendorEngineerCreateRequest`: `{ "name": "string", "email": "string", "password": "string", "organizationId": 0 }`
- `AccessAssignmentRequest`: `{ "principalType": "string", "principalId": 0, "siteId": 0, "zoneId": 0 }`

Key endpoint contracts:
- `POST /api/v1/auth/login`
  - Request: `LoginRequest`
  - Response body commonly contains `AuthResponse`: `{ "principalId": 0, "principalType": "string", "token": "jwt" }`
- `POST /api/v1/auth/logout`
  - Request: no body
  - Response: `MessageResponseDTO`
- `POST /api/v1/auth/otp/super-admin`
  - Request: `OtpRequest`
  - Response: `MessageResponseDTO`
- `POST /api/v1/auth/verified`
  - Request: `SuperAdminOtpCreateRequest`
  - Response: `MessageResponseDTO`
- `POST /api/v1/super-admins`
  - Request: `SuperAdminCreateRequest`
  - Response: `MessageResponseDTO`
- `POST /api/v1/super-admins/admins`
  - Request: `AdminCreateRequest`
  - Response: `MessageResponseDTO`
- `POST /api/v1/super-admins/admins/{adminId}/users`
  - Request: `UserCreateRequest`
  - Response: `MessageResponseDTO`
- `POST /api/v1/super-admins/access/assign`
  - Request: `AccessAssignmentRequest`
  - Response: `MessageResponseDTO`
- `POST /api/v1/super-admins/access/revoke`
  - Request: `AccessAssignmentRequest`
  - Response: `MessageResponseDTO`
- `POST /api/v1/admins/users`
  - Request: `UserCreateRequest`
  - Response: `MessageResponseDTO`
- `POST /api/v1/admins/access/assign`
  - Request: `AccessAssignmentRequest`
  - Response: `MessageResponseDTO`
- `POST /api/v1/admins/access/revoke`
  - Request: `AccessAssignmentRequest`
  - Response: `MessageResponseDTO`
- `POST /api/v1/users`
  - Request: `UserCreateRequest`
  - Response: `MessageResponseDTO`
- `POST /api/v1/vendors`
  - Request: `VendorCreateRequest`
  - Response: `MessageResponseDTO`
- `POST /api/v1/vendors-engineer/engineers`
  - Request: `VendorEngineerCreateRequest`
  - Response: `MessageResponseDTO`

## 2. Organization Service

Base paths:
- `/api/v1/org`
- `/api/v1/org/site`
- `/api/v1/org/zone`

Response envelope (`MessageResponse<T>`):
```json
{
  "message": "string",
  "status": true,
  "body": {}
}
```

Request DTOs:
- `CreateOrganizationRequest`: `{ "name": "string", "email": "string" }`
- `CreateSiteRequest`: `{ "orgId": "uuid", "name": "string", "location": "string" }`
- `CreateZoneRequest`: `{ "siteId": "uuid", "name": "string" }`

Entity response shapes:
- Organization: `{ "organizationId": "uuid", "name": "string", "email": "string", "status": "ACTIVE|INACTIVE", "createdAt": "timestamp", "sites": [] }`
- Site: `{ "sitesID": "uuid", "organization": {}, "name": "string", "location": "string", "createdAt": "timestamp", "zones": [] }`
- Zone: `{ "zoneId": "uuid", "site": {}, "name": "string" }`

Endpoints:
- `GET /api/v1/org/organization`
- `GET /api/v1/org/organization/{orgId}`
- `POST /api/v1/org/organization` with `CreateOrganizationRequest`
- `PUT /api/v1/org/organization/{orgId}` with `CreateOrganizationRequest`
- `DELETE /api/v1/org/organization/{orgId}`
- `GET /api/v1/org/organization/{orgId}/sites`
- `POST /api/v1/org/organization/{orgId}/sites` with `CreateSiteRequest`
- `GET /api/v1/org/site/`
- `GET /api/v1/org/site/{siteId}`
- `POST /api/v1/org/site/` with `CreateSiteRequest`
- `PUT /api/v1/org/site/{siteId}` with `CreateSiteRequest`
- `DELETE /api/v1/org/site/{siteId}`
- `GET /api/v1/org/site/{siteId}/zones`
- `POST /api/v1/org/site/{siteId}/zones` with `CreateZoneRequest`
- `GET /api/v1/org/zone/?siteId={siteId}`
- `GET /api/v1/org/zone/{zoneId}`
- `POST /api/v1/org/zone/` with `CreateZoneRequest`
- `PUT /api/v1/org/zone/{zoneId}` with `CreateZoneRequest`
- `DELETE /api/v1/org/zone/{zoneId}`

## 3. Device Management Service

Base paths:
- `/api/v1/device`
- `/api/v1/sensors`
- `/api/v1/sensor-parameter`
- `/api/v1/sensor-type`
- `/api/v1/ingestion` (device-side ingestion API)

Request/response DTOs:
- `DeviceDTO`: `{ "id":"uuid", "siteId":"uuid", "serialNumber":"string", "firmwareVersion":"string", "status":"string", "lastHeartBeat":"datetime" }`
- `SensorDTO`: `{ "sensorId":"uuid", "deviceId":"uuid", "sensorTypeId":"uuid", "name":"string", "status":"string", "unit":"string" }`
- `SensorParameterDTO`: `{ "sensorParameterId":"uuid", "sensorTypeId":"uuid", "name":"string", "unit":"string", "minValue":0.0, "maxValue":0.0 }`
- `SensorTypeDTO`: `{ "sensorTypeId":"uuid", "name":"string", "category":"string", "description":"string" }`
- `SensorReadingDTO`: `{ "readingId":"uuid", "sensorId":"uuid", "sensorParameterId":"uuid", "value":0.0, "timestamp":"iso", "ingestionTime":"iso" }`

Endpoints:
- Device
  - `POST /api/v1/device/devices` body `DeviceDTO` -> `DeviceDTO`
  - `GET /api/v1/device/devices/{deviceId}` -> `DeviceDTO`
  - `GET /api/v1/device/sites/{siteId}/devices` -> `DeviceDTO[]`
  - `PUT /api/v1/device/devices/{deviceId}` body `DeviceDTO` -> `DeviceDTO`
  - `DELETE /api/v1/device/devices/{deviceId}` -> no body
- Sensor
  - `POST /api/v1/sensors/devices/{deviceId}/sensors` body `SensorDTO` -> `SensorDTO`
  - `GET /api/v1/sensors/sensors/{sensorId}` -> `SensorDTO`
  - `GET /api/v1/sensors/devices/{deviceId}/sensors` -> `SensorDTO[]`
  - `PUT /api/v1/sensors/sensors/{sensorId}` body `SensorDTO` -> `SensorDTO`
  - `DELETE /api/v1/sensors/sensors/{sensorId}` -> no body
- Sensor Parameter
  - `POST /api/v1/sensor-parameter/sensor-types/{typeId}/parameters` body `SensorParameterDTO` -> `SensorParameterDTO`
  - `GET /api/v1/sensor-parameter/sensor-types/{typeId}/parameters` -> `SensorParameterDTO[]`
  - `PUT /api/v1/sensor-parameter/parameters/{parameterId}` body `SensorParameterDTO` -> `SensorParameterDTO`
  - `DELETE /api/v1/sensor-parameter/parameters/{parameterId}` -> no body
- Sensor Type
  - `POST /api/v1/sensor-type/sensor-types` body `SensorTypeDTO` -> `SensorTypeDTO`
  - `GET /api/v1/sensor-type/sensor-types` -> `SensorTypeDTO[]`
  - `GET /api/v1/sensor-type/sensor-types/{typeId}` -> `SensorTypeDTO`
  - `PUT /api/v1/sensor-type/sensor-types/{typeId}` body `SensorTypeDTO` -> `SensorTypeDTO`
  - `DELETE /api/v1/sensor-type/sensor-types/{typeId}` -> no body
- Device Ingestion
  - `POST /api/v1/ingestion/readings` body `SensorReadingDTO` -> `SensorReadingDTO`
  - `POST /api/v1/ingestion/readings/batch` body `SensorReadingDTO[]` -> `SensorReadingDTO[]`
  - `GET /api/v1/ingestion/readings?sensorId=&from=&to=` -> `SensorReadingDTO[]`
  - `GET /api/v1/ingestion/readings/{readingId}` -> `SensorReadingDTO`
  - `GET /api/v1/ingestion/health` -> `{ "status":"UP", ... }`

## 4. Ingestion Service

Base path:
- `/api/v1/ingestion`

Primary response DTOs:
- `SensorReadingResponse`: `{ "status":"SUCCESS", "message":"string", "readingId":"uuid" }`
- `SensorReadingView`: `{ "readingId":"uuid", "sensorId":"string", "timestamp":"iso", "parameters":{} }`

Input format:
- Main ingest endpoint accepts JSON / text / form / query values and normalizes payload.
- Alias ingest route values: `""`, `/`, `/stream`, `/esp32`, `/readings`, `/sensor-data`

Endpoints:
- `POST /api/v1/ingestion` (also aliases above)
  - Body can be JSON object, form-like text, or plain text.
  - Response: `SensorReadingResponse`
- `GET /api/v1/ingestion/readings?sensorId=&from=&to=` -> `SensorReadingView[]`
- `GET /api/v1/ingestion/readings/getall` -> `SensorReadingView[]`
- `GET /api/v1/ingestion/readings/{readingId}` -> `SensorReadingView`
- `GET /api/v1/ingestion/readings/live` -> `text/event-stream` SSE
- `GET /api/v1/ingestion/health` -> `{ "status":"UP", "storedReadings": <number> }`

## 5. Processing Service

Base path:
- `/api/v1/processing`

Response envelope (`ProcessDataResponse<T>`):
```json
{
  "message": "string",
  "status": true,
  "body": {}
}
```

Input payload accepted for processing:
```json
{
  "dataType": "accelerometer|tiltmeter|vibration|...",
  "sensorId": "uuid|string",
  "readingId": "uuid|string",
  "timestamp": "iso|epoch",
  "parameters": {}
}
```

Endpoints:
- `POST /api/v1/processing/process` body `Map<String,Object>` -> `ProcessDataResponse`
- `GET /api/v1/processing/readings?sensorId=&from=&to=` -> `ProcessDataResponse`
- `GET /api/v1/processing/readings/{readingId}` -> `ProcessDataResponse`
- `GET /api/v1/processing/readings/live` -> `text/event-stream` SSE
- `POST /api/v1/processing/recalculate/{readingId}` -> `ProcessDataResponse`
- `POST /api/v1/processing/recalculate?sensorId=&from=&to=` -> `ProcessDataResponse`
- `GET /api/v1/processing/kafka/status` -> `ProcessDataResponse`
- `GET /api/v1/processing/kafka/threshold-publish-status` -> `ProcessDataResponse`
- `GET /api/v1/processing/kafka/probe?timeoutMs=3000&maxRecords=5` -> `ProcessDataResponse`

## 6. Threshold Alert Service

Base paths:
- `/api/v1/alerts`
- `/api/v1/thresholds`

Response envelope (`MessageResponse<T>`):
```json
{
  "message": "string",
  "status": true,
  "body": {}
}
```

Request DTOs:
- `AlertCreateRequest`: `{ "sensorId":"uuid", "sensorParameterId":"uuid", "alertLevel":"string", "message":"string", "assignedTo":"string" }`
- `AlertUpdateRequest`: `{ "alertLevel":"string", "message":"string", "status":"string", "assignedTo":"string" }`
- `AssignAlertRequest`: `{ "assignee":"string" }`
- `ThresholdCreateRequest`: `{ "sensorParameterId":"uuid", "thresholdProfileId":"uuid", "minThresholdValue":0, "maxThresholdValue":0, "warningLevel":0, "criticalLevel":0 }`
- `ThresholdProfileCreateRequest`: `{ "name":"string", "description":"string" }`

Response DTOs:
- `AlertResponse`
- `ThresholdValueResponse`
- `ThresholdProfileResponse`

Alert endpoints:
- `GET /api/v1/alerts?status=&level=&sensorId=&assignedTo=&from=&to=`
- `GET /api/v1/alerts/{id}`
- `POST /api/v1/alerts` body `AlertCreateRequest`
- `PUT /api/v1/alerts/{id}` body `AlertUpdateRequest`
- `DELETE /api/v1/alerts/{id}`
- `POST /api/v1/alerts/{id}/resolve`
- `POST /api/v1/alerts/{id}/acknowledge`
- `POST /api/v1/alerts/{id}/escalate`
- `POST /api/v1/alerts/{id}/assign` body `AssignAlertRequest`
- `GET /api/v1/alerts/active`
- `GET /api/v1/alerts/resolved`
- `GET /api/v1/alerts/history`
- `GET /api/v1/alerts/stats`
- `GET /api/v1/alerts/summary`
- `POST /api/v1/alerts/bulk-resolve` body `UUID[]`

Threshold endpoints:
- `GET /api/v1/thresholds`
- `GET /api/v1/thresholds/{id}`
- `POST /api/v1/thresholds` body `ThresholdCreateRequest`
- `PUT /api/v1/thresholds/{id}` body `ThresholdCreateRequest`
- `DELETE /api/v1/thresholds/{id}`
- `GET /api/v1/thresholds/profiles`
- `GET /api/v1/thresholds/profiles/{id}`
- `POST /api/v1/thresholds/profiles` body `ThresholdProfileCreateRequest`
- `PUT /api/v1/thresholds/profiles/{id}` body `ThresholdProfileCreateRequest`
- `DELETE /api/v1/thresholds/profiles/{id}`
- `POST /api/v1/thresholds/{id}/apply` body `UUID` (sensorId raw)
- `POST /api/v1/thresholds/bulk-apply` body `Map<String,Object>`
- `GET /api/v1/thresholds/defaults`
- `GET /api/v1/thresholds/kafka/status`
- `GET /api/v1/thresholds/kafka/probe?timeoutMs=&maxRecords=`
- `POST /api/v1/thresholds/kafka/replay-to-analytics?maxRecords=`

## 7. Analytics Service

Base paths:
- `/api/v1/analytics`
- `/api/v1/dashboard`
- `/api/v1/stats`
- `/api/v1/search`
- `/api/v1/reports`
- `/api/v1/audit-logs`

Response format:
- Mostly `ResponseEntity<Map<String,Object>>` or `List<Map<String,Object>>`
- SSE stream at `/api/v1/analytics/events/live`

Analytics endpoints:
- `GET /api/v1/analytics/events`
- `GET /api/v1/analytics/events/live` (SSE)
- `GET /api/v1/analytics/events/recent?limit=50`
- `GET /api/v1/analytics/events/alerts`
- `GET /api/v1/analytics/kafka/status`
- `GET /api/v1/analytics/dashboard/summary`
- `GET /api/v1/analytics/dashboard`
- `GET /api/v1/analytics/overview`
- `GET /api/v1/analytics/sensors/{id}/trends?from=&to=`
- `GET /api/v1/analytics/sensors/{id}/predictions?horizon=`
- `GET /api/v1/analytics/sensors/compare?sensorIds=a,b`
- `GET /api/v1/analytics/anomalies`
- `GET /api/v1/analytics/health-score`
- `GET /api/v1/analytics/distribution`
- `GET /api/v1/analytics/performance`
- `GET /api/v1/analytics/utilization`
- `GET /api/v1/analytics/downtime`
- `GET /api/v1/analytics/alerts-trend`
- `GET /api/v1/analytics/sensor-reliability`
- `GET /api/v1/analytics/device-uptime`
- `GET /api/v1/analytics/custom-query?query=&from=&to=`

Dashboard endpoints:
- `GET /api/v1/dashboard/stats`
- `GET /api/v1/dashboard/overview`
- `GET /api/v1/dashboard/recent-alerts`
- `GET /api/v1/dashboard/sensor-status`
- `GET /api/v1/dashboard/device-status`
- `GET /api/v1/dashboard/system-health`
- `GET /api/v1/dashboard/charts/tilt-readings`
- `GET /api/v1/dashboard/charts/sensor-distribution`
- `GET /api/v1/dashboard/charts/alerts-trend`
- `GET /api/v1/dashboard/charts/device-uptime`
- `GET /api/v1/dashboard/activity-feed`
- `GET /api/v1/dashboard/quick-stats`

Stats endpoints:
- `GET /api/v1/stats/overview`
- `GET /api/v1/stats/sensors`
- `GET /api/v1/stats/devices`
- `GET /api/v1/stats/alerts`
- `GET /api/v1/stats/users`
- `GET /api/v1/stats/organizations`
- `GET /api/v1/stats/readings`
- `GET /api/v1/stats/custom?metric=&from=&to=`

Search endpoints:
- `GET /api/v1/search?q=&type=&page=&size=`
- `GET /api/v1/search/sensors?q=&page=&size=`
- `GET /api/v1/search/devices?q=&page=&size=`
- `GET /api/v1/search/users?q=&page=&size=`
- `GET /api/v1/search/organizations?q=&page=&size=`
- `GET /api/v1/search/global?q=&page=&size=`

Reports endpoints:
- `GET /api/v1/reports`
- `GET /api/v1/reports/{id}`
- `POST /api/v1/reports/generate` body `Map<String,Object>`
- `GET /api/v1/reports/{id}/download`
- `DELETE /api/v1/reports/{id}`
- `GET /api/v1/reports/templates`
- `GET /api/v1/reports/templates/{id}`
- `POST /api/v1/reports/templates` body `Map<String,Object>`
- `PUT /api/v1/reports/templates/{id}` body `Map<String,Object>`
- `DELETE /api/v1/reports/templates/{id}`
- `POST /api/v1/reports/schedule` body `Map<String,Object>`
- `GET /api/v1/reports/scheduled`

Audit log endpoints:
- `GET /api/v1/audit-logs`
- `GET /api/v1/audit-logs/{id}`
- `GET /api/v1/audit-logs/export`
- `GET /api/v1/audit-logs/stats`
- `GET /api/v1/audit-logs/user/{userId}`
- `GET /api/v1/audit-logs/resource/{resourceType}/{resourceId}`
- `DELETE /api/v1/audit-logs/{id}`

## 8. Notification Service

Base path:
- `/api/v1/notification`

DTOs:
- `NotificationRequest`: `{ "userId":"string", "title":"string", "message":"string", "type":"string" }`
- `NotificationResponse`: `{ "id":"string", "userId":"string", "title":"string", "message":"string", "type":"string", "read":true, "createdAt":"iso" }`
- `NotificationSettingsRequest`: `{ "emailEnabled":true, "pushEnabled":true, "smsEnabled":false }`
- `NotificationSettingsResponse`: `{ "userId":"string", "emailEnabled":true, "pushEnabled":true, "smsEnabled":false }`
- `UnreadCountResponse`: `{ "userId":"string", "unreadCount":0 }`

Endpoints:
- `GET /api/v1/notification/?userId=...` -> `NotificationResponse[]`
- `GET /api/v1/notification/{notificationId}?userId=...` -> `NotificationResponse`
- `POST /api/v1/notification/` body `NotificationRequest` -> `"string message"`
- `DELETE /api/v1/notification/{notificationId}?userId=...` -> `"string message"`
- `GET /api/v1/notification/unread?userId=...` -> `NotificationResponse[]`
- `GET /api/v1/notification/unread/count?userId=...` -> `UnreadCountResponse`
- `POST /api/v1/notification/{notificationId}/mark-read?userId=...` -> `NotificationResponse`
- `POST /api/v1/notification/mark-all-read?userId=...` -> `NotificationResponse[]`
- `GET /api/v1/notification/settings?userId=...` -> `NotificationSettingsResponse`
- `PUT /api/v1/notification/settings?userId=...` body `NotificationSettingsRequest` -> `NotificationSettingsResponse`
- `POST /api/v1/notification/test?userId=...` -> `"string message"`

## 9. Configuration Service

Base path families:
- `/api/v1/config*`
- `/api/v1/calibrations`
- `/api/v1/comments`
- `/api/v1/favorites`
- `/api/v1/webhooks`
- `/api/v1/tags`
- `/api/v1/integrations`
- `/api/v1/locations`
- `/api/v1/maintenance`
- `/api/v1/schedules`, `/api/v1/jobs`
- `/api/v1/roles`, `/api/v1/permissions`
- `/api/v1/upload`, `/api/v1/download`, `/api/v1/files`
- `/api/v1/import`, `/api/v1/export`
- `/api/v1/batch`
- `/api/v1/health`, `/api/v1/system/*`, `/api/v1/version`

Important response behavior:
- Most endpoints return `JsonNode` or `List<JsonNode>`.
- Request bodies are mostly flexible `JsonNode` payloads.
- File download endpoint returns binary: `GET /api/v1/files/{id}` returns `ResponseEntity<byte[]>`.

Core endpoint groups:
- Config:
  - `GET/PUT /api/v1/config`
  - `GET/PUT /api/v1/configsystem`
  - `GET/PUT /api/v1/confignotifications`
  - `GET/PUT /api/v1/configthresholds`
  - `GET/PUT /api/v1/configalerts`
  - `GET /api/v1/configbackup`
  - `POST /api/v1/configbackup/create`
  - `POST /api/v1/configbackup/restore`
  - `GET /api/v1/configbackup/list`
  - `DELETE /api/v1/configbackup/{id}`
  - `GET/PUT /api/v1/configemail`
  - `POST /api/v1/config/test-email`
- Batch:
  - `POST /api/v1/batch/sensors/create`
  - `POST /api/v1/batch/sensors/update`
  - `POST /api/v1/batch/sensors/delete`
  - `POST /api/v1/batch/devices/update`
  - `POST /api/v1/batch/alerts/resolve`
  - `POST /api/v1/batch/users/create`
  - `POST /api/v1/batch/thresholds/apply`
  - `POST /api/v1/batch/export`
- Calibrations:
  - `GET /api/v1/calibrations`
  - `GET /api/v1/calibrations/{id}`
  - `POST /api/v1/calibrations`
  - `GET /api/v1/calibrations/history`
  - `GET /api/v1/calibrations/due`
  - `POST /api/v1/calibrations/bulk`
- Comments:
  - `GET /api/v1/comments`
  - `GET /api/v1/comments/{id}`
  - `POST /api/v1/comments`
  - `PUT /api/v1/comments/{id}`
  - `DELETE /api/v1/comments/{id}`
  - `GET /api/v1/comments/resource/{resourceType}/{resourceId}`
  - `POST /api/v1/comments/{id}/reply`
- Favorites:
  - `GET/POST /api/v1/favorites`
  - `DELETE /api/v1/favorites/{id}`
  - `GET /api/v1/favorites/sensors`
  - `GET /api/v1/favorites/devices`
  - `GET /api/v1/favorites/sites`
- Webhooks / Tags / Integrations / Maintenance:
  - Standard CRUD + action endpoints exactly as controller paths define.
- Location:
  - `GET /api/v1/locations`
  - `GET /api/v1/locations/nearby`
  - `POST /api/v1/locations/geocode`
  - `POST /api/v1/locations/reverse-geocode`
  - `GET /api/v1/locations/map-data`
- Schedules / Roles:
  - `GET/POST /api/v1/schedules`
  - `GET/PUT/DELETE /api/v1/schedules/{id}`
  - `POST /api/v1/schedules/{id}/run`
  - `GET /api/v1/schedules/{id}/history`
  - `GET /api/v1/jobs/status`
  - `GET/POST /api/v1/roles`
  - `GET/PUT/DELETE /api/v1/roles/{id}`
  - `GET /api/v1/permissions`
  - `GET /api/v1/permissions/{id}`
  - `POST /api/v1/roles/{id}/permissions`
  - `GET /api/v1/roles/{id}/users`
  - `POST /api/v1/roles/{id}/assign-user`
- File and import/export:
  - `POST /api/v1/upload/sensor-config` (`multipart/form-data`, field `file`)
  - `POST /api/v1/upload/device-config` (`multipart/form-data`, field `file`)
  - `POST /api/v1/upload/bulk-import` (`multipart/form-data`, field `file`)
  - `POST /api/v1/upload/avatar` (`multipart/form-data`, field `file`)
  - `POST /api/v1/upload/document` (`multipart/form-data`, field `file`)
  - `GET /api/v1/download/template/{type}`
  - `GET /api/v1/download/export/{id}`
  - `GET /api/v1/files/{id}` -> file bytes
  - `POST /api/v1/import/sensors|devices|users` with JSON body
  - `GET /api/v1/export/sensors|devices|readings`
- System health:
  - `GET /api/v1/health`
  - `GET /api/v1/health/detailed`
  - `GET /api/v1/version`
  - `GET /api/v1/system/status|info|metrics|logs|performance|database-status|cache-status`
  - `POST /api/v1/system/cache-clear`
  - `POST /api/v1/system/maintenance-mode` body JSON

## Notes for Frontend Team

- Date/time fields are primarily ISO-8601 strings unless endpoint explicitly uses epoch.
- IDs are UUID for most services except auth/notification where several IDs are numeric/string.
- SSE endpoints:
  - `/api/v1/ingestion/readings/live`
  - `/api/v1/processing/readings/live`
  - `/api/v1/analytics/events/live`
- For SSE in web frontend use `EventSource` (not standard XHR JSON flow).
