const { io } = require('socket.io-client');

// Use your LM's public URL
const LM_URL = 'https://8a46-197-211-59-122.ngrok-free.app';

const lmSocket = io(`${LM_URL}/bot-server`, {
  transports: ['websocket', 'polling'],
});

lmSocket.on('connect', () => {
  console.log('[BOT] Connected to LM WebSocket');
});

lmSocket.on('disconnect', () => {
  console.log('[BOT] Disconnected from LM WebSocket');
});

// Export a function to emit QR to LM
function sendQrToLm(qrPayload) {
  lmSocket.emit('qr', qrPayload);
}

module.exports = { sendQrToLm };