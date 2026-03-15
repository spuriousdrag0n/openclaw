#!/usr/bin/env python3
"""
Simple webhook server to receive glucose data from iPhone
Run this on your server and configure iPhone shortcut to POST to it
"""

import http.server
import socketserver
import json
import subprocess
import os
from datetime import datetime

PORT = 8080
WORK_DIR = "/root/.openclaw/workspace/glucose_monitor"

class GlucoseHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/glucose':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data)
                
                # Log the data
                log_entry = {
                    "timestamp": datetime.now().isoformat(),
                    "data": data
                }
                
                with open(f"{WORK_DIR}/glucose_history.jsonl", "a") as f:
                    f.write(json.dumps(log_entry) + "\n")
                
                # Process alerts
                value = data.get('value', 0)
                trend = data.get('trend', 'Unknown')
                
                if value < 70:
                    self.send_alert(value, trend, "URGENT LOW")
                elif value > 250:
                    self.send_alert(value, trend, "URGENT HIGH")
                
                # Send success response
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "success"}).encode())
                
            except Exception as e:
                self.send_response(400)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "error", "message": str(e)}).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def send_alert(self, value, trend, status):
        """Send WhatsApp alert"""
        messages = {
            "URGENT LOW": f"🚨 URGENT GLUCOSE ALERT - Simon\n\nValue: {value} mg/dL\nTrend: {trend}\nStatus: {status}\n\n⚠️ ACTIONS:\n• Consume 15g fast carbs\n• Recheck in 15 min",
            "URGENT HIGH": f"🚨 URGENT GLUCOSE ALERT - Simon\n\nValue: {value} mg/dL\nTrend: {trend}\nStatus: {status}\n\n⚠️ ACTIONS:\n• Check ketones\n• Hydrate\n• Contact provider"
        }
        
        message = messages.get(status, f"Glucose alert: {value} mg/dL")
        
        # Log alert
        with open(f"{WORK_DIR}/alerts.log", "a") as f:
            f.write(f"{datetime.now().isoformat()} - {status}: {value} mg/dL\n")
        
        # Send WhatsApp via CLI (async)
        for target in ["+9613961764", "+96170224984"]:
            subprocess.Popen([
                "openclaw", "message", "send",
                "--channel", "whatsapp",
                "--target", target,
                "--message", message
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    def log_message(self, format, *args):
        # Suppress default logging
        pass

if __name__ == "__main__":
    os.makedirs(WORK_DIR, exist_ok=True)
    
    with socketserver.TCPServer(("0.0.0.0", PORT), GlucoseHandler) as httpd:
        print(f"Glucose webhook server running on port {PORT}")
        print(f"Endpoint: http://YOUR_SERVER_IP:{PORT}/glucose")
        httpd.serve_forever()
