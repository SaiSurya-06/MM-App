const express = require('express');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const app = express();
const PORT = process.env.PORT || 3000;
const DATA_FILE = path.join(__dirname, 'db.json');
const VERSION_FILE = path.join(__dirname, 'versions.json');

// Rate limiting: Track request counts per IP
const rateLimitStore = {};
const RATE_LIMIT_WINDOW_MS = 60000; // 1 minute window
const MAX_REQUESTS_PER_WINDOW = 60; // Max 60 requests per minute per IP

function cleanupRateLimitStore() {
  const now = Date.now();
  for (const ip in rateLimitStore) {
    if (now - rateLimitStore[ip].windowStart > RATE_LIMIT_WINDOW_MS) {
      delete rateLimitStore[ip];
    }
  }
}

// Run cleanup every 5 minutes
setInterval(cleanupRateLimitStore, 5 * 60 * 1000);

function checkRateLimit(ip) {
  const now = Date.now();
  if (!rateLimitStore[ip]) {
    rateLimitStore[ip] = { count: 1, windowStart: now };
    return true;
  }
  
  if (now - rateLimitStore[ip].windowStart > RATE_LIMIT_WINDOW_MS) {
    // Reset window
    rateLimitStore[ip] = { count: 1, windowStart: now };
    return true;
  }
  
  rateLimitStore[ip].count++;
  if (rateLimitStore[ip].count > MAX_REQUESTS_PER_WINDOW) {
    return false; // Rate limit exceeded
  }
  return true;
}

// Apply rate limiting middleware
app.use((req, res, next) => {
  const ip = req.ip || req.connection.remoteAddress || 'unknown';
  if (!checkRateLimit(ip)) {
    console.log(`Rate limit exceeded for IP: ${ip}`);
    return res.status(429).send('Too many requests. Please try again later.');
  }
  next();
});

function readDb() {
  try {
    if (fs.existsSync(DATA_FILE)) {
      const data = fs.readFileSync(DATA_FILE, 'utf8');
      return JSON.parse(data);
    }
  } catch (e) {
    console.error('Error reading DB file:', e);
  }
  return {};
}

function writeDb(db) {
  try {
    fs.writeFileSync(DATA_FILE, JSON.stringify(db, null, 2), 'utf8');
  } catch (e) {
    console.error('Error writing DB file:', e);
  }
}

function readVersions() {
  try {
    if (fs.existsSync(VERSION_FILE)) {
      return JSON.parse(fs.readFileSync(VERSION_FILE, 'utf8'));
    }
  } catch (e) {}
  return {};
}

function writeVersions(v) {
  try {
    fs.writeFileSync(VERSION_FILE, JSON.stringify(v, null, 2), 'utf8');
  } catch (e) {}
}

app.use(express.text({ limit: '10mb' }));

// Health check
// In-memory store for auth tokens: { roomCode: { token: string, createdAt: number } }
const authTokens = {};
const TOKEN_EXPIRY_MS = 24 * 60 * 60 * 1000; // 24 hours

// Generate a secure random token
function generateAuthToken() {
  return crypto.randomBytes(32).toString('hex');
}

// Clean up expired tokens
setInterval(() => {
  const now = Date.now();
  for (const roomCode in authTokens) {
    if (now - authTokens[roomCode].createdAt > TOKEN_EXPIRY_MS) {
      delete authTokens[roomCode];
    }
  }
}, 60 * 60 * 1000); // Run every hour

app.get('/', (req, res) => {
  res.send('ok');
});

// Test connection
app.get('/?action=test', (req, res) => {
  res.send('ok');
});

// Request auth token for a room
app.post('/auth', (req, res) => {
  const { roomCode } = req.body;
  if (!roomCode || typeof roomCode !== 'string' || roomCode.length !== 6) {
    return res.status(400).send('Error: Invalid room code');
  }
  
  // Generate a new token for this room
  const token = generateAuthToken();
  authTokens[roomCode.toUpperCase()] = {
    token: token,
    createdAt: Date.now()
  };
  
  console.log(`Auth token generated for room: ${roomCode}`);
  res.send(JSON.stringify({ token: token }));
});

// Get data (full or incremental by version) - requires auth token
app.get('/?action=get', (req, res) => {
  const { key, since_version, auth_token } = req.query;
  if (!key) return res.status(400).send('Error: Missing key parameter');
  
  // Extract room code from key (format: ROOMCODE__SLOT_data)
  const roomCode = key.split('__')[0].toUpperCase();
  const providedToken = auth_token;
  
  // Validate auth token
  if (!providedToken || !authTokens[roomCode] || authTokens[roomCode].token !== providedToken) {
    console.log(`Invalid or missing auth token for room: ${roomCode}`);
    return res.status(401).send('Error: Unauthorized - invalid or missing auth token');
  }

  const db = readDb();
  if (db[key] === undefined) return res.send('404');

  // Incremental sync: return only changes since since_version
  if (since_version && parseInt(since_version) > 0) {
    const versions = readVersions();
    const keyVersion = versions[key] || 0;
    const since = parseInt(since_version);

    if (keyVersion <= since) {
      return res.send('{"changes": []}');
    }

    const fullData = db[key];
    return res.send(JSON.stringify({
      changes: fullData,
      version: keyVersion,
      isIncremental: true
    }));
  }

  res.send(db[key]);
});

// Set data (full or incremental) - requires auth token
app.post('/', (req, res) => {
  const { key, action, auth_token } = req.query;
  const value = req.body;

  if (!key) return res.status(400).send('Error: Missing key parameter');
  if (value === undefined || value === null) return res.status(400).send('Error: Missing body content');

  // Extract room code from key (format: ROOMCODE__SLOT_data)
  const roomCode = key.split('__')[0].toUpperCase();
  
  // Validate auth token for write operations
  if (!auth_token || !authTokens[roomCode] || authTokens[roomCode].token !== auth_token) {
    console.log(`Invalid or missing auth token for room: ${roomCode} (write operation)`);
    return res.status(401).send('Error: Unauthorized - invalid or missing auth token');
  }

  const db = readDb();
  const versions = readVersions();

  // Handle chunk assembly
  if (action === 'set_chunk') {
    const { index, total, val } = req.query;
    const chunkKey = `${key}_chunks`;

    if (!db[chunkKey]) db[chunkKey] = {};
    db[chunkKey][index] = val;

    const receivedCount = Object.keys(db[chunkKey]).length;
    if (receivedCount === parseInt(total)) {
      // Assemble chunks
      let assembled = '';
      for (let i = 0; i < parseInt(total); i++) {
        assembled += db[chunkKey][i] || '';
      }
      db[key] = assembled;
      delete db[chunkKey];
      versions[key] = (versions[key] || 0) + 1;
      writeDb(db);
      writeVersions(versions);
      return res.send(`chunk_received:${index};assembled;v:${versions[key]}`);
    }

    writeDb(db);
    return res.send(`chunk_received:${index};partial:${receivedCount}/${total}`);
  }

  db[key] = value;
  versions[key] = (versions[key] || 0) + 1;
  writeDb(db);
  writeVersions(versions);

  res.send(JSON.stringify({ status: 'ok', version: versions[key] }));
});

// Conflict resolution endpoint
app.post('/resolve', (req, res) => {
  const { key, winner } = req.query;
  const value = req.body;

  if (!key) return res.status(400).send('Error: Missing key parameter');

  const db = readDb();
  const versions = readVersions();

  db[key] = value;
  versions[key] = (versions[key] || 0) + 1;
  writeDb(db);
  writeVersions(versions);

  res.send(JSON.stringify({ status: 'resolved', version: versions[key] }));
});

// Version check (for incremental sync)
app.get('/version', (req, res) => {
  const { key } = req.query;
  if (!key) return res.status(400).send('Error: Missing key parameter');

  const versions = readVersions();
  res.send(JSON.stringify({ version: versions[key] || 0 }));
});

app.listen(PORT, () => {
  console.log(`Sync server running on port ${PORT}`);
});
