# Heartbeat Tasks

## WhatsApp Ad Campaign (MerkleRoot)
TRIGGER="/root/.openclaw/workspace/data/whatsapp_ad_trigger.json"
AD_IMAGE="/root/.openclaw/workspace/data/merkleroot_ad.jpg"

if [ -f "$TRIGGER" ]; then
    # Extract target and caption from trigger
    TARGET=$(cat "$TRIGGER" | python3 -c "import sys,json; print(json.load(sys.stdin).get('target',''))" 2>/dev/null)
    CAPTION=$(cat "$TRIGGER" | python3 -c "import sys,json; print(json.load(sys.stdin).get('caption',''))" 2>/dev/null)
    
    if [ -n "$TARGET" ] && [ -f "$AD_IMAGE" ]; then
        # Send the ad image with caption from trigger file
        /usr/local/bin/openclaw message send --channel whatsapp --target "$TARGET" --media "$AD_IMAGE" --message "$CAPTION"
        
        # Delete trigger after successful send
        rm -f "$TRIGGER"
    fi
fi

## System Event: merkleroot.ad.send
# When this event fires, run the ad sender script
if [ "$SYSTEM_EVENT" = "merkleroot.ad.send" ]; then
    /root/.openclaw/workspace/scripts/whatsapp-ad-sender.py
fi
