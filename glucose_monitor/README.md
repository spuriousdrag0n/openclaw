# Glucose Monitoring System - Simon Tadros

## Current Setup
- **Monitoring Type:** LibreLink upload polling
- **Frequency:** Every 4 hours via cron
- **Alert Thresholds:** <70 mg/dL (LOW), >250 mg/dL (URGENT)
- **Target Range:** 70-180 mg/dL

## Current Reading
- **Value:** 137 mg/dL
- **Trend:** Stable (→)
- **Status:** In Range ✓
- **Time:** 2026-03-13 04:54 AM (Lebanon)

## File Structure
- `libre_monitor.sh` - API polling script
- `analyze_glucose.py` - Glucose data parser
- `check_glucose.sh` - Main monitoring script
- `notify.sh` - Alert notification script
- `glucose_history.jsonl` - Historical data log
- `alerts.log` - Alert history
- `latest_reading.json` - Most recent reading

## Alert Recipients
- **Primary:** Simon (Telegram/WhatsApp)
- **Secondary:** Chantal +9613961764 (WhatsApp - pending channel setup)

## Token Expiry
- **Sharing Token:** GLY9-QH-LB
- **Expires:** 2026-03-14 (72 hours from creation)
- **Renewal URL:** https://www.libreview.com/sharing

## TODO
- [ ] Configure WhatsApp channel for Chantal alerts
- [ ] Set up Telegram bot for notifications
- [ ] Create weekly summary report
- [ ] Implement pattern tracking (afternoon crashes, night spikes)
