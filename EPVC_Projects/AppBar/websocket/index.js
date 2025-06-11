const WebSocket = require('ws');
const http = require('http');

// Create HTTP server
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('WebSocket server is running');
});

// Create WebSocket server
const wss = new WebSocket.Server({ server });

// Store connected clients
const clients = new Set();

// Handle WebSocket connections
wss.on('connection', (ws) => {
  console.log('New client connected');
  clients.add(ws);

  // Handle incoming messages
  ws.on('message', (message) => {
    try {
      // Parse the incoming message as JSON
      const data = JSON.parse(message);
      console.log('Received message:', data);

      // Broadcast the message to all connected clients
      clients.forEach((client) => {
        if (client !== ws && client.readyState === WebSocket.OPEN) {
          client.send(JSON.stringify({
            status: 'success',
            message: 'Order received',
            data: data
          }));
        }
      });

      // Send acknowledgment back to the sender
      ws.send(JSON.stringify({
        status: 'success',
        message: 'Order received'
      }));

    } catch (error) {
      console.error('Error parsing message:', error);
      ws.send(JSON.stringify({
        status: 'error',
        message: 'Invalid message format'
      }));
    }
  });

  // Handle client disconnection
  ws.on('close', () => {
    console.log('Client disconnected');
    clients.delete(ws);
  });

  // Handle errors
  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
    clients.delete(ws);
  });
});

// Start the server
const PORT = process.env.PORT || 2536;
server.listen(PORT, () => {
  console.log(`WebSocket server is running on port ${PORT}`);
}); 