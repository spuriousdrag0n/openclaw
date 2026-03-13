#!/usr/bin/env python3
import json
import sys
from datetime import datetime

# Target ranges
ALERT_LOW = 70
ALERT_HIGH = 250
TARGET_LOW = 70
TARGET_HIGH = 180

# Trend mapping
TREND_ARROWS = {
    "DoubleDown": "↓↓ dropping fast",
    "SingleDown": "↓ dropping",
    "Stable": "→ stable",
    "SingleUp": "↑ rising",
    "DoubleUp": "↑↑ rising fast"
}

def analyze_glucose(data):
    """Analyze glucose reading and return status"""
    try:
        # Extract current glucose entry
        entries = data.get("DeviceData", {}).get("measurementLog", {}).get("currentGlucoseEntries", [])
        if not entries:
            return {"error": "No glucose data in payload"}
        
        entry = entries[0]
        value = entry.get("valueInMgPerDl", 0)
        trend = entry.get("extendedProperties", {}).get("trendArrow", "Stable")
        timestamp = entry.get("timestamp", "")
        
        # Determine status
        if value < ALERT_LOW:
            status = "URGENT LOW"
            alert = True
        elif value < TARGET_LOW:
            status = "LOW"
            alert = True
        elif value > ALERT_HIGH:
            status = "URGENT HIGH"
            alert = True
        elif value > TARGET_HIGH:
            status = "HIGH"
            alert = True
        else:
            status = "IN RANGE"
            alert = False
        
        # Recommendations
        actions = []
        if value < 70:
            actions = ["Consume 15g fast carbs immediately", "Recheck in 15 min", "Avoid exercise"]
        elif value < 100:
            actions = ["Have a small snack if trending down", "Monitor closely"]
        elif value > 250:
            actions = ["Check ketones", "Hydrate with water", "Contact healthcare provider if persists"]
        elif value > 180:
            actions = ["Take walk if safe", "Hydrate", "Review meal timing"]
        else:
            actions = ["Continue current routine", "Stay hydrated", "Monitor trends"]
        
        return {
            "value": value,
            "trend": TREND_ARROWS.get(trend, trend),
            "timestamp": timestamp,
            "status": status,
            "alert": alert,
            "actions": actions
        }
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    # Read from stdin
    data = json.load(sys.stdin)
    result = analyze_glucose(data)
    print(json.dumps(result, indent=2))
