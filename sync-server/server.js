const express = require('express');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const app = express();
const PORT = process.env.PORT || 3000;
const DATA_FILE = path.join(__dirname, 'db.json');
const VERSION_FILE = path.join(__dirname, 'versions.json');

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
app.get('/', (req, res) => {
  res.send('ok');
});

// Test connection
app.get('/?action=test', (req, res) => {
  res.send('ok');
});

// Get data (full or incremental by version)
app.get('/?action=get', (req, res) => {
  const { key, since_version } = req.query;
  if (!key) return res.status(400).send('Error: Missing key parameter');

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

// Set data (full or incremental)
app.post('/', (req, res) => {
  const { key, action } = req.query;
  const value = req.body;

  if (!key) return res.status(400).send('Error: Missing key parameter');
  if (value === undefined || value === null) return res.status(400).send('Error: Missing body content');

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
