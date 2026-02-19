# API Endpoints Documentation

This document outlines all possible API endpoints for the Industrial Sensor Monitoring System.

## Base URL
```
https://api.monitoring-system.com/v1
```

---

## Authentication

### POST /auth/login
Login to the system.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "USER-1234567890",
      "name": "John Doe",
      "email": "user@example.com",
      "role": "user_admin",
      "organizationId": "ORG-1234567890",
      "isActive": true,
      "createdAt": "2024-01-15T10:30:00Z",
      "lastLogin": "2024-01-20T14:22:00Z",
      "avatar": "https://avatar.url/user.jpg"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### POST /auth/logout
Logout from the system.

**Response:**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## Users

### GET /users
Get all users (requires: user_admin or super_admin).

**Query Parameters:**
- `role` (optional): Filter by role (super_admin, installation_engineer, user_admin, user, vendor)
- `status` (optional): Filter by status (active, inactive)
- `search` (optional): Search by name or email
- `organizationId` (optional): Filter by organization

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "USER-1234567890",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "organizationId": "ORG-1234567890",
      "isActive": true,
      "createdAt": "2024-01-15T10:30:00Z",
      "lastLogin": "2024-01-20T14:22:00Z",
      "accessControl": {
        "organizationId": "ORG-1234567890",
        "siteIds": ["SITE-001", "SITE-002"],
        "zoneIds": ["ZONE-001"],
        "sensorIds": ["SENSOR-001"],
        "hasFullOrganizationAccess": false
      }
    }
  ],
  "total": 1
}
```

### GET /users/:id
Get user by ID.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "USER-1234567890",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "organizationId": "ORG-1234567890",
    "isActive": true,
    "createdAt": "2024-01-15T10:30:00Z",
    "profile": {
      "phone": "+1234567890",
      "department": "Operations",
      "title": "Senior Operator",
      "timezone": "UTC",
      "language": "en",
      "notifications": {
        "email": true,
        "sms": true,
        "whatsapp": false,
        "push": true,
        "alertTypes": {
          "critical": true,
          "warning": true,
          "info": false
        },
        "deviceUpdates": true,
        "systemNotifications": true,
        "dailyDigest": false
      }
    }
  }
}
```

### POST /users
Create new user (requires: user_admin or super_admin).

**Request:**
```json
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "role": "user",
  "organizationId": "ORG-1234567890",
  "accessControl": {
    "siteIds": ["SITE-001"],
    "zoneIds": ["ZONE-001"],
    "sensorIds": ["SENSOR-001"],
    "hasFullOrganizationAccess": false
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "USER-9876543210",
    "name": "Jane Smith",
    "email": "jane@example.com",
    "role": "user",
    "organizationId": "ORG-1234567890",
    "isActive": true,
    "createdAt": "2024-01-20T15:45:00Z"
  }
}
```

### PUT /users/:id
Update user (requires: user_admin or super_admin).

**Request:**
```json
{
  "name": "Jane Smith Updated",
  "isActive": true,
  "accessControl": {
    "siteIds": ["SITE-001", "SITE-002"],
    "zoneIds": ["ZONE-001", "ZONE-002"],
    "sensorIds": []
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "USER-9876543210",
    "name": "Jane Smith Updated",
    "isActive": true,
    "updatedAt": "2024-01-21T09:15:00Z"
  }
}
```

### DELETE /users/:id
Delete user (requires: super_admin).

**Response:**
```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

---

## Organizations

### GET /organizations
Get all organizations.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "ORG-1234567890",
      "name": "Acme Corporation",
      "contactEmail": "contact@acme.com",
      "createdAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### POST /organizations
Create organization (requires: super_admin).

**Request:**
```json
{
  "name": "New Corp",
  "contactEmail": "info@newcorp.com"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "ORG-9876543210",
    "name": "New Corp",
    "contactEmail": "info@newcorp.com",
    "createdAt": "2024-01-20T16:00:00Z"
  }
}
```

### PUT /organizations/:id
Update organization.

**Request:**
```json
{
  "name": "Updated Corp Name",
  "contactEmail": "contact@updated.com"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "ORG-9876543210",
    "name": "Updated Corp Name",
    "contactEmail": "contact@updated.com",
    "updatedAt": "2024-01-21T10:30:00Z"
  }
}
```

### DELETE /organizations/:id
Delete organization (requires: super_admin).

**Response:**
```json
{
  "success": true,
  "message": "Organization and all associated data deleted"
}
```

---

## Sites

### GET /sites
Get all sites.

**Query Parameters:**
- `organizationId` (optional): Filter by organization

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "SITE-1234567890",
      "name": "Manufacturing Plant A",
      "organizationId": "ORG-1234567890",
      "location": "New York, NY",
      "createdAt": "2024-01-05T08:00:00Z"
    }
  ]
}
```

### POST /sites
Create site.

**Request:**
```json
{
  "name": "Plant B",
  "organizationId": "ORG-1234567890",
  "location": "Los Angeles, CA"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "SITE-9876543210",
    "name": "Plant B",
    "organizationId": "ORG-1234567890",
    "location": "Los Angeles, CA",
    "createdAt": "2024-01-20T16:30:00Z"
  }
}
```

### PUT /sites/:id
Update site.

**Request:**
```json
{
  "name": "Plant B Updated",
  "location": "San Francisco, CA"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "SITE-9876543210",
    "name": "Plant B Updated",
    "location": "San Francisco, CA",
    "updatedAt": "2024-01-21T11:00:00Z"
  }
}
```

### DELETE /sites/:id
Delete site.

**Response:**
```json
{
  "success": true,
  "message": "Site deleted successfully"
}
```

---

## Zones

### GET /zones
Get all zones.

**Query Parameters:**
- `siteId` (optional): Filter by site

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "ZONE-1234567890",
      "name": "Production Floor",
      "siteId": "SITE-1234567890",
      "description": "Main production area"
    }
  ]
}
```

### POST /zones
Create zone.

**Request:**
```json
{
  "name": "Storage Area",
  "siteId": "SITE-1234567890",
  "description": "Temperature-controlled storage"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "ZONE-9876543210",
    "name": "Storage Area",
    "siteId": "SITE-1234567890",
    "description": "Temperature-controlled storage"
  }
}
```

---

## Locations

### GET /locations
Get all locations.

**Query Parameters:**
- `zoneId` (optional): Filter by zone

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "LOC-1234567890",
      "name": "Sector A1",
      "zoneId": "ZONE-1234567890",
      "coordinates": {
        "lat": 40.7128,
        "lng": -74.0060
      }
    }
  ]
}
```

### POST /locations
Create location.

**Request:**
```json
{
  "name": "Sector B2",
  "zoneId": "ZONE-1234567890",
  "coordinates": {
    "lat": 40.7589,
    "lng": -73.9851
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "LOC-9876543210",
    "name": "Sector B2",
    "zoneId": "ZONE-1234567890",
    "coordinates": {
      "lat": 40.7589,
      "lng": -73.9851
    }
  }
}
```

---

## Devices

### GET /devices
Get all devices.

**Query Parameters:**
- `status` (optional): Filter by status (active, offline, warning, error)
- `locationId` (optional): Filter by location
- `search` (optional): Search by device ID or serial number

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "DEV-1234567890",
      "deviceId": "DVC-2024-001",
      "serialNumber": "SN-ABC123",
      "macId": "00:1B:44:11:3A:B7",
      "ipUrl": "192.168.1.100",
      "numberOfChannels": 4,
      "status": "active",
      "activationDate": "2024-01-10T09:00:00Z",
      "locationId": "LOC-1234567890",
      "coordinates": {
        "lat": 40.7128,
        "lng": -74.0060
      },
      "wifiConfig": {
        "ssid": "IndustrialNet",
        "configured": true
      },
      "webhookUrl": "https://webhook.site/device-updates",
      "dataTransmissionActive": true,
      "lastSeen": "2024-01-20T18:45:00Z"
    }
  ],
  "total": 1
}
```

### POST /devices
Create device (requires: installation_engineer or super_admin).

**Request:**
```json
{
  "deviceId": "DVC-2024-002",
  "serialNumber": "SN-XYZ789",
  "macId": "00:1B:44:22:4B:C8",
  "ipUrl": "192.168.1.101",
  "numberOfChannels": 8,
  "locationId": "LOC-1234567890",
  "coordinates": {
    "lat": 40.7589,
    "lng": -73.9851
  },
  "webhookUrl": "https://webhook.site/device-updates",
  "dataTransmissionActive": true
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "DEV-9876543210",
    "deviceId": "DVC-2024-002",
    "status": "active",
    "activationDate": "2024-01-20T19:00:00Z"
  }
}
```

### PUT /devices/:id
Update device.

**Request:**
```json
{
  "ipUrl": "192.168.1.102",
  "numberOfChannels": 8,
  "dataTransmissionActive": false
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "DEV-9876543210",
    "ipUrl": "192.168.1.102",
    "numberOfChannels": 8,
    "dataTransmissionActive": false,
    "updatedAt": "2024-01-21T12:00:00Z"
  }
}
```

### DELETE /devices/:id
Delete device (requires: super_admin).

**Response:**
```json
{
  "success": true,
  "message": "Device deleted successfully"
}
```

---

## Sensors

### GET /sensors
Get all sensors.

**Query Parameters:**
- `status` (optional): Filter by status
- `sensorType` (optional): Filter by type (temperature, humidity, pressure, etc.)
- `deviceId` (optional): Filter by connected device
- `search` (optional): Search by sensor ID

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "SEN-1234567890",
      "sensorId": "SENS-2024-001",
      "serialNumber": "SN-SENS-001",
      "macId": "00:1B:44:33:5C:D9",
      "connectedDeviceId": "DEV-1234567890",
      "channelNumber": 1,
      "sensorType": "temperature",
      "activationDate": "2024-01-10T10:00:00Z",
      "status": "active",
      "unit": "°C",
      "locationId": "LOC-1234567890",
      "coordinates": {
        "lat": 40.7128,
        "lng": -74.0060
      },
      "lastReading": {
        "sensorId": "SENS-2024-001",
        "timestamp": "2024-01-20T18:50:00Z",
        "value": 23.5,
        "unit": "°C"
      }
    }
  ],
  "total": 1
}
```

### POST /sensors
Create sensor (requires: installation_engineer or super_admin).

**Request:**
```json
{
  "sensorId": "SENS-2024-002",
  "serialNumber": "SN-SENS-002",
  "macId": "00:1B:44:44:6D:EA",
  "connectedDeviceId": "DEV-1234567890",
  "channelNumber": 2,
  "sensorType": "humidity",
  "locationId": "LOC-1234567890",
  "coordinates": {
    "lat": 40.7128,
    "lng": -74.0060
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "SEN-9876543210",
    "sensorId": "SENS-2024-002",
    "status": "active",
    "unit": "%",
    "activationDate": "2024-01-20T19:30:00Z"
  }
}
```

### PUT /sensors/:id
Update sensor.

**Request:**
```json
{
  "channelNumber": 3,
  "locationId": "LOC-9876543210"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "SEN-9876543210",
    "channelNumber": 3,
    "locationId": "LOC-9876543210",
    "updatedAt": "2024-01-21T13:00:00Z"
  }
}
```

### DELETE /sensors/:id
Delete sensor (requires: super_admin).

**Response:**
```json
{
  "success": true,
  "message": "Sensor deleted successfully"
}
```

---

## Sensor Readings

### GET /sensors/:id/readings
Get sensor readings.

**Query Parameters:**
- `startTime` (optional): Start timestamp (ISO 8601)
- `endTime` (optional): End timestamp (ISO 8601)
- `limit` (optional): Number of readings (default: 100)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "sensorId": "SENS-2024-001",
      "timestamp": "2024-01-20T18:50:00Z",
      "value": 23.5,
      "unit": "°C"
    },
    {
      "sensorId": "SENS-2024-001",
      "timestamp": "2024-01-20T18:51:00Z",
      "value": 23.7,
      "unit": "°C"
    }
  ],
  "total": 2
}
```

### POST /sensors/:id/readings
Submit sensor reading (system/device endpoint).

**Request:**
```json
{
  "timestamp": "2024-01-20T19:00:00Z",
  "value": 24.2
}
```

**Response:**
```json
{
  "success": true,
  "message": "Reading recorded"
}
```

---

## Alerts

### GET /alerts
Get all alerts.

**Query Parameters:**
- `level` (optional): Filter by level (info, warning, critical)
- `resolved` (optional): Filter by resolution status (true/false)
- `sensorId` (optional): Filter by sensor

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "ALERT-1234567890",
      "thresholdId": "THR-001",
      "sensorId": "SENS-2024-001",
      "level": "critical",
      "message": "Temperature exceeded threshold: 45°C",
      "triggeredAt": "2024-01-20T18:55:00Z",
      "acknowledgedAt": null,
      "acknowledgedBy": null,
      "resolved": false
    }
  ],
  "total": 1
}
```

### PUT /alerts/:id/acknowledge
Acknowledge an alert.

**Request:**
```json
{
  "acknowledgedBy": "USER-1234567890"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "ALERT-1234567890",
    "acknowledgedAt": "2024-01-20T19:05:00Z",
    "acknowledgedBy": "USER-1234567890",
    "resolved": true
  }
}
```

---

## Alert Thresholds

### GET /alert-thresholds
Get all alert thresholds.

**Query Parameters:**
- `sensorId` (optional): Filter by sensor

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "THR-001",
      "sensorId": "SENS-2024-001",
      "level": "critical",
      "condition": "above",
      "value": 40,
      "enabled": true,
      "notificationChannels": ["app", "sms", "whatsapp"],
      "recipients": ["USER-001", "USER-002"]
    }
  ]
}
```

### POST /alert-thresholds
Create alert threshold.

**Request:**
```json
{
  "sensorId": "SENS-2024-001",
  "level": "warning",
  "condition": "above",
  "value": 35,
  "enabled": true,
  "notificationChannels": ["app"],
  "recipients": ["USER-001"]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "THR-002",
    "sensorId": "SENS-2024-001",
    "level": "warning",
    "condition": "above",
    "value": 35,
    "enabled": true
  }
}
```

---

## Notifications

### GET /notifications
Get user notifications.

**Query Parameters:**
- `read` (optional): Filter by read status (true/false)
- `type` (optional): Filter by type (alert, info, warning, success, system)
- `priority` (optional): Filter by priority (low, medium, high, critical)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "NOTIF-1234567890",
      "userId": "USER-1234567890",
      "title": "Critical Alert",
      "message": "Temperature sensor SENS-2024-001 exceeded threshold",
      "type": "alert",
      "priority": "critical",
      "read": false,
      "createdAt": "2024-01-20T18:55:00Z",
      "metadata": {
        "alertId": "ALERT-1234567890",
        "sensorId": "SENS-2024-001",
        "location": "Production Floor - Sector A1"
      }
    }
  ],
  "total": 1,
  "unreadCount": 1
}
```

### PUT /notifications/:id/read
Mark notification as read.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "NOTIF-1234567890",
    "read": true,
    "readAt": "2024-01-20T19:10:00Z"
  }
}
```

### PUT /notifications/mark-all-read
Mark all notifications as read.

**Response:**
```json
{
  "success": true,
  "message": "All notifications marked as read",
  "count": 5
}
```

---

## Dashboard Metrics

### GET /dashboard/metrics
Get dashboard overview metrics.

**Response:**
```json
{
  "success": true,
  "data": {
    "totalDevices": 25,
    "activeDevices": 23,
    "offlineDevices": 2,
    "totalSensors": 100,
    "activeSensors": 98,
    "activeAlerts": 3,
    "criticalAlerts": 1
  }
}
```

---

## Analytics

### GET /analytics/sensor-statistics
Get sensor statistics and trends.

**Query Parameters:**
- `sensorIds` (required): Comma-separated sensor IDs
- `startTime` (required): Start timestamp
- `endTime` (required): End timestamp
- `aggregation` (optional): Data aggregation interval (1m, 5m, 1h, 1d)

**Response:**
```json
{
  "success": true,
  "data": {
    "sensorId": "SENS-2024-001",
    "period": {
      "start": "2024-01-20T00:00:00Z",
      "end": "2024-01-20T23:59:59Z"
    },
    "statistics": {
      "min": 18.5,
      "max": 32.4,
      "avg": 24.8,
      "median": 24.5,
      "stdDev": 2.3
    },
    "readings": 1440,
    "dataPoints": [
      {
        "timestamp": "2024-01-20T00:00:00Z",
        "value": 22.1
      }
    ]
  }
}
```

---

## Export

### GET /export/devices
Export devices to CSV.

**Query Parameters:**
- `format` (optional): Export format (csv, json) - default: csv

**Response:**
```
Device ID,Serial Number,MAC ID,Status,Location,Last Seen
DVC-2024-001,SN-ABC123,00:1B:44:11:3A:B7,active,Production Floor - Sector A1,2024-01-20T18:45:00Z
```

### GET /export/sensors
Export sensors to CSV.

**Response:**
```
Sensor ID,Type,Device ID,Channel,Status,Location,Last Reading
SENS-2024-001,temperature,DVC-2024-001,1,active,Production Floor - Sector A1,23.5°C
```

---

## Error Responses

All endpoints may return the following error responses:

### 400 Bad Request
```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Invalid request parameters",
    "details": {
      "field": "email",
      "issue": "Invalid email format"
    }
  }
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required"
  }
}
```

### 403 Forbidden
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Insufficient permissions to access this resource"
  }
}
```

### 404 Not Found
```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Resource not found"
  }
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred"
  }
}
```
