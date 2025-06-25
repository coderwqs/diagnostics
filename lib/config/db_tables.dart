const List<String> TABLES_SCHEMA = [
  '''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''',
  '''
      CREATE TABLE IF NOT EXISTS devices (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        identity TEXT NOT NULL UNIQUE,
        secret TEXT NOT NULL,
        status TEXT CHECK (status IN ('online', 'offline', 'warning')) DEFAULT 'offline',
        lastActive INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        image BLOB NOT NULL
      )
    ''',
  '''
      CREATE TABLE IF NOT EXISTS history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deviceId TEXT NOT NULL,
        dataTime INTEGER NOT NULL,
        samplingRate REAL NOT NULL,
        rotationSpeed INTEGER,
        data BLOB NOT NULL,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (deviceId) REFERENCES devices(id)
      )
    ''',
  '''
      CREATE TABLE IF NOT EXISTS features (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deviceId TEXT NOT NULL,
        dataTime INTEGER NOT NULL,
        rms REAL,
        vpp REAL,
        max REAL,
        min REAL,
        mean REAL,
        arv REAL,
        peak REAL,
        variance REAL,
        stdDev REAL,
        msa REAL,
        crestFactor REAL,
        kurtosis REAL,
        formFactor REAL,
        skewness REAL,
        pulseFactor REAL,
        clearanceFactor REAL,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (deviceId) REFERENCES devices(id) ON DELETE CASCADE
      )
    ''',
  '''
      CREATE INDEX IF NOT EXISTS idx_features_device ON features(deviceId)
  ''',
];
