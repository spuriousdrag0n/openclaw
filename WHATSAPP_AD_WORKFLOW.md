# WhatsApp Ad Automation - Agent-Triggered Workflow

## How It Works

1. **Cron creates trigger** (hourly): `/root/.openclaw/workspace/whatsapp_ad_trigger.sh`
   - Generates trigger file at `/root/.openclaw/workspace/data/whatsapp_ad_trigger.json`
   - Contains target number, message, image path

2. **You approve on WhatsApp**: Send message "send ad" to RedQueen on WhatsApp

3. **Agent processes**: I read trigger, send ad via WhatsApp message tool, update state

4. **State advances**: Next contact in rotation

## Commands (WhatsApp only)

- `send ad` - Process pending ad trigger
- `ad status` - Show current state (who's next, when last sent)
- `skip ad` - Skip current contact, move to next

## Files

- Trigger: `/root/.openclaw/workspace/data/whatsapp_ad_trigger.json`
- State: `/root/.openclaw/workspace/data/whatsapp_ad_state.json`
- Log: `/var/log/whatsapp_ad_cron.log`

## Cron

```
0 * * * * /root/.openclaw/workspace/whatsapp_ad_trigger.sh
```

Runs hourly, creates trigger. You approve via WhatsApp.
