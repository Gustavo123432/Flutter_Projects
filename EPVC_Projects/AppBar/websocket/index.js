const WebSocket = require('ws');
const crypto = require('crypto');

// WebSocket Server Setup (Listening on port 2536)
const wss = new WebSocket.Server({ port: 2536 });
const clients = new Set();

// WebSocket Client Setup (Connecting to another WebSocket server)
const socket = new WebSocket('ws://websocket.appbar.epvc.pt:80');

// Track recent messages to avoid duplicates
const recentMessages = new Set();
const MESSAGE_TTL = 5000; // 5 seconds

// Função para gerar um hash único com base no conteúdo da mensagem
function generateHashId(data) {
  return crypto.createHash('sha256').update(data).digest('hex');
}

// Handle incoming WebSocket server connections
wss.on('connection', function connection(ws) {
  console.log('Client connected!');
  clients.add(ws);

  // Handle incoming messages from clients
  ws.on('message', function message(data) {
    try {
      const messageStr = data.toString();
      console.log(`Received message from client: ${messageStr}`);

      const value = JSON.parse(messageStr);
      const messageId = value.NPedido
        ? `client-${value.NPedido}`
        : `client-${generateHashId(messageStr)}`;

      if (!recentMessages.has(messageId)) {
        recentMessages.add(messageId);
        setTimeout(() => recentMessages.delete(messageId), MESSAGE_TTL);

        // Broadcast to other clients
        clients.forEach((client) => {
          if (client !== ws && client.readyState === WebSocket.OPEN) {
            client.send(messageStr);
          }
        });

        // Send to external server if needed
        if (socket.readyState === WebSocket.OPEN) {
          socket.send(messageStr);
        }
      } else {
        console.log('Ignoring duplicate message from client');
      }
    } catch (error) {
      console.error('Error handling client message:', error);
    }
  });

  ws.on('close', () => {
    clients.delete(ws);
    console.log('Client disconnected');
  });
});

// Handle external WebSocket connection
socket.on('open', () => {
  console.log('Connected to external WebSocket server');
});

socket.on('message', (data) => {
  try {
    const messageStr = data.toString();
    console.log(`Received message from external server: ${messageStr}`);

    const value = JSON.parse(messageStr);
    const messageId = value.NPedido
      ? `external-${value.NPedido}`
      : `external-${generateHashId(messageStr)}`;

    if (!recentMessages.has(messageId)) {
      recentMessages.add(messageId);
      setTimeout(() => recentMessages.delete(messageId), MESSAGE_TTL);

      // Broadcast to all clients
      clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
          client.send(messageStr);
        }
      });
    } else {
      console.log('Ignoring duplicate message from external server');
    }
  } catch (error) {
    console.error('Error handling external message:', error);
  }
});

socket.on('error', (err) => {
  console.error('External WebSocket error:', err);
});

socket.on('close', () => {
  console.log('Disconnected from external WebSocket server');
});

// Ping external server periodically
setInterval(() => {
  if (socket.readyState === WebSocket.OPEN) {
    socket.ping();
  }
}, 60000);

console.log('WebSocket server running on ws://localhost:2536');
