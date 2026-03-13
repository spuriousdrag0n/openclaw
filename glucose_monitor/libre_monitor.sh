#!/bin/bash
# LibreView Glucose Monitor for Simon Tadros
# Polling interval: 4 hours

LOG_FILE="/root/.openclaw/workspace/glucose_monitor/glucose_log.json"
ALERT_LOW=70
ALERT_HIGH=250
TARGET_LOW=70
TARGET_HIGH=180

# API endpoint
API_URL="https://api-c-lb.libreview.io/lsl/api/measurements"

# Payload with authentication
PAYLOAD='{
  "GatewayType": "FSLibreLink.iOS",
  "DeviceData": {
    "measurementLog": {
      "bloodGlucoseEntries": [],
      "capabilities": [
        "scheduledContinuousGlucose",
        "unscheduledContinuousGlucose",
        "bloodGlucose"
      ],
      "currentGlucoseEntries": [],
      "genericEntries": [],
      "scheduledContinuousGlucoseEntries": [],
      "foodEntries": [],
      "insulinEntries": [],
      "unscheduledContinuousGlucoseEntries": []
    },
    "header": {
      "device": {
        "osType": "iOS",
        "osVersion": "26.3",
        "hardwareDescriptor": "iPhone15,2",
        "uniqueIdentifier": "171A9B8E-E1F8-428B-BA46-2AF520BF969F",
        "modelName": "com.abbott.librelink.lb"
      }
    },
    "connectedDevices": {
      "insulinDevices": []
    },
    "deviceSettings": {
      "miscellaneous": {
        "valueGlucoseTargetRangeHighInMgPerDl": 180,
        "valueGlucoseTargetRangeLowInMgPerDl": 70,
        "isStreaming": true
      },
      "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.000+00:00)'",
      "firmwareVersion": "2.13.0.9122",
      "factoryConfig": {
        "UOM": "mg/dL"
      }
    }
  },
  "UserToken": "Ztu2/3qqaim/NmhN/wzMRlLuHCvDAb18E3htHXqB7arJCP2Da8wVkJfqsvQdVSXUooeZLEMG/m2UyjBdukOw2DP0nyJDSsVugbpgyV/z6UH7aFChN1KC7MMDGQ63bPmC1huQSMraa4DUuQHmOtItpJ3VW5t/ogH7PXdjRszzre7Ao852F47JwQKfCgyllUcQVa8mZcUa68YybwBIyaPE1s1BRTjx6KeUiOA018MMqS18moaobsNmV6yPuScKdgxL0KtN0Xtp5t/a2bdMdBruobzNO4LhozRc8SKg6il9egDp7Y1DcPdyOWJ/jgH6fat73Obq3fzpPhOjJ95LYwlZUNZdLx+RYcq4YWmG2nkF7U3+x33pJu+cb0Pr1iMLkbFAvYdcL2/Zgz8b4ZZsQWMrSgm7LR/ZOD4pNNhEmhC6CFLg/jIA5kmKwfW/vgdTub2ugTUtTwN1Kl5JfE7AFIZs3XhYSJaT/4ReQOqz7ab6CV5fKGDQIce9eXxX1C94kpGq",
  "Domain": "Libreview"
}'

# Make request
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "User-Agent: LibreLink/9122 CFNetwork/3860.400.51 Darwin/25.3.0" \
  -H "Abbott-ADC-App-Platform: iOS/26.3/FSLL/2.13.0.9122" \
  -H "Accept-Language: en-GB, en;q=0.8" \
  --compressed \
  -d "$PAYLOAD")

echo "$(date -Iseconds) - Response: $RESPONSE" >> "$LOG_FILE"
echo "$RESPONSE"
