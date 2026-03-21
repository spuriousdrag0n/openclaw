#!/usr/bin/env node
/**
 * WhatsApp Voice Transcriber - Local Whisper
 * Intercepts voice messages and transcribes using local Whisper
 */

const { default: makeWASocket, useMultiFileAuthState, DisconnectReason } = require('@whiskeysockets/baileys');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const AUTH_DIR = '/root/.openclaw/workspace/data/whatsapp-voice-auth';
const TEMP_DIR = '/tmp/whatsapp-voice';

// Ensure temp directory exists
if (!fs.existsSync(TEMP_DIR)) {
    fs.mkdirSync(TEMP_DIR, { recursive: true });
}

async function transcribeAudio(audioPath) {
    try {
        const result = execSync(`/usr/local/bin/whisper "${audioPath}" --model base --output_format txt --output_dir ${TEMP_DIR} 2>&1`, {
            encoding: 'utf-8',
            timeout: 60000
        });
        
        const txtFile = path.join(TEMP_DIR, path.basename(audioPath, path.extname(audioPath)) + '.txt');
        if (fs.existsSync(txtFile)) {
            const text = fs.readFileSync(txtFile, 'utf-8').trim();
            fs.unlinkSync(txtFile);
            return text;
        }
        return null;
    } catch (e) {
        console.error('Transcription failed:', e.message);
        return null;
    }
}

async function start() {
    const { state, saveCreds } = await useMultiFileAuthState(AUTH_DIR);
    
    const sock = makeWASocket({
        auth: state,
        printQRInTerminal: true,
    });
    
    sock.ev.on('creds.update', saveCreds);
    
    sock.ev.on('connection.update', (update) => {
        const { connection, lastDisconnect } = update;
        if (connection === 'close') {
            const shouldReconnect = lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut;
            console.log('Connection closed, reconnecting:', shouldReconnect);
            if (shouldReconnect) {
                start();
            }
        } else if (connection === 'open') {
            console.log('Voice transcriber connected');
        }
    });
    
    sock.ev.on('messages.upsert', async (m) => {
        if (m.type !== 'notify') return;
        
        for (const msg of m.messages) {
            // Check if it's a voice message (PTT or audio)
            const isVoice = msg.message?.audioMessage?.ptt === true || 
                           msg.message?.ptt === true ||
                           (msg.message?.audioMessage && !msg.message?.audioMessage?.mimetype?.includes('audio'));
            
            if (!isVoice && !msg.message?.audioMessage) continue;
            
            console.log('Voice message detected from:', msg.key.remoteJid);
            
            try {
                // Download the audio
                const buffer = await sock.downloadMediaMessage(msg);
                const tempFile = path.join(TEMP_DIR, `voice_${Date.now()}.ogg`);
                fs.writeFileSync(tempFile, buffer);
                
                // Transcribe
                const text = await transcribeAudio(tempFile);
                
                // Cleanup
                fs.unlinkSync(tempFile);
                
                if (text) {
                    // Send transcription as reply
                    await sock.sendMessage(msg.key.remoteJid, {
                        text: `🎤 *Transcription:*\n${text}`,
                        quoted: msg
                    });
                    console.log('Transcription sent');
                }
            } catch (e) {
                console.error('Error processing voice:', e);
            }
        }
    });
}

start().catch(console.error);
