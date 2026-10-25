const { DatabaseSync } = require('node:sqlite');
const path = require('path');
const crypto = require('crypto');

const dbPath = path.join(__dirname, 'database.sqlite');
const db = new DatabaseSync(dbPath);

// Initialize Tables
function initDb() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS keys (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key_code TEXT UNIQUE NOT NULL,
      duration_hours INTEGER NOT NULL DEFAULT 24,
      created_at INTEGER NOT NULL,
      activated_at INTEGER DEFAULT NULL,
      expires_at INTEGER DEFAULT NULL,
      hwid TEXT DEFAULT NULL,
      status TEXT DEFAULT 'active',
      note TEXT DEFAULT '',
      usage_count INTEGER DEFAULT 0,
      last_used_at INTEGER DEFAULT NULL
    );

    CREATE TABLE IF NOT EXISTS access_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key_code TEXT,
      hwid TEXT,
      ip TEXT,
      status TEXT,
      message TEXT,
      timestamp INTEGER NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_key_code ON keys(key_code);
    CREATE INDEX IF NOT EXISTS idx_log_time ON access_logs(timestamp);
  `);

  // Safely add columns if not present
  try { db.exec('ALTER TABLE keys ADD COLUMN roblox_username TEXT DEFAULT NULL;'); } catch (e) {}
  try { db.exec('ALTER TABLE keys ADD COLUMN roblox_user_id TEXT DEFAULT NULL;'); } catch (e) {}
  try { db.exec('ALTER TABLE keys ADD COLUMN tier TEXT DEFAULT "VIP";'); } catch (e) {}
  try { db.exec('ALTER TABLE keys ADD COLUMN max_screens INTEGER DEFAULT 1;'); } catch (e) {}
  try { db.exec('ALTER TABLE access_logs ADD COLUMN roblox_username TEXT DEFAULT NULL;'); } catch (e) {}

  db.exec(`
    CREATE TABLE IF NOT EXISTS free_key_claims (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ip TEXT NOT NULL,
      key_code TEXT NOT NULL,
      claimed_at INTEGER NOT NULL
    );
    CREATE INDEX IF NOT EXISTS idx_claim_ip ON free_key_claims(ip);

    CREATE TABLE IF NOT EXISTS blacklist (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      target TEXT UNIQUE NOT NULL,
      reason TEXT DEFAULT '',
      created_at INTEGER NOT NULL
    );
    CREATE INDEX IF NOT EXISTS idx_bl_target ON blacklist(target);
  `);
}


function seedDefaultKeys() {
  const seeds = [
    { key: 'NEXUS-QDQ4-K7XU-Z6AP', tier: 'VIP', duration: 0, note: 'Admin Lifetime VIP Key', maxScreens: 5 },
    { key: 'NEXUS-QV4M-UM2L-LPWG', tier: 'VIP', duration: 0, note: 'Default Lifetime VIP Key', maxScreens: 3 },
    { key: 'NEXUS-EPTU-9UUM-2PQF', tier: 'VIP', duration: 720, note: '30-Day VIP Key', maxScreens: 2 },
    { key: 'FREE-D59R-QK6V-C843', tier: 'FREE', duration: 24, note: 'Daily Free Key', maxScreens: 1 },
    { key: 'FREE-82UL-XPRA-6CM3', tier: 'FREE', duration: 24, note: 'Daily Free Key', maxScreens: 1 }
  ];

  for (const s of seeds) {
    try {
      const exists = db.prepare('SELECT id FROM keys WHERE key_code = ?').get(s.key);
      if (!exists) {
        db.prepare(`
          INSERT INTO keys (key_code, duration_hours, created_at, status, note, tier, max_screens)
          VALUES (?, ?, ?, 'active', ?, ?, ?)
        `).run(s.key, s.duration, Date.now(), s.note, s.tier, s.maxScreens);
      }
    } catch (e) {}
  }
}

initDb();
seedDefaultKeys();

function randomString(length = 4) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let result = '';
  const bytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i++) {
    result += chars[bytes[i] % chars.length];
  }
  return result;
}

function generateKeyCode(prefix = 'NEXUS-') {
  return `${prefix}${randomString(4)}-${randomString(4)}-${randomString(4)}`;
}

const dbManager = {
  createKey({ prefix = 'NEXUS-', durationHours = 24, note = '', customKey = null, tier = 'VIP', maxScreens = 1 }) {
    let keyCode = customKey ? customKey.trim().toUpperCase() : generateKeyCode(prefix);
    const now = Date.now();
    const duration = parseInt(durationHours, 10);
    const safeTier = (tier || 'VIP').toUpperCase();
    const safeScreens = parseInt(maxScreens, 10) >= 0 ? parseInt(maxScreens, 10) : 1;

    const stmt = db.prepare(`
      INSERT INTO keys (key_code, duration_hours, created_at, status, note, tier, max_screens)
      VALUES (?, ?, ?, 'active', ?, ?, ?)
    `);

    try {
      stmt.run(keyCode, duration, now, note || '', safeTier, safeScreens);
      return { success: true, key: keyCode, durationHours: duration, note, tier: safeTier, maxScreens: safeScreens };
    } catch (err) {
      if (err.message && err.message.includes('UNIQUE')) {
        // Retry once with new random key
        keyCode = generateKeyCode(prefix);
        stmt.run(keyCode, duration, now, note || '', safeTier, safeScreens);
        return { success: true, key: keyCode, durationHours: duration, note, tier: safeTier };
      }
      throw err;
    }
  },

  createBulkKeys({ prefix = 'NEXUS-', durationHours = 24, note = '', count = 1, tier = 'VIP', maxScreens = 1 }) {
    const total = Math.min(Math.max(parseInt(count, 10) || 1, 1), 100);
    const keys = [];
    for (let i = 0; i < total; i++) {
      const res = this.createKey({ prefix, durationHours, note: note ? `${note} (#${i + 1})` : '', tier, maxScreens });
      keys.push(res.key);
    }
    return keys;
  },

  verifyKey(keyCode, hwid = null, ip = '127.0.0.1', robloxUsername = null, robloxUserId = null) {
    if (!keyCode || typeof keyCode !== 'string') {
      return { success: false, reason: 'empty_key', message: 'กรุณากรอกคีย์ (Please provide a key)' };
    }

    const cleanKey = keyCode.trim().toUpperCase();
    const cleanHwid = hwid ? hwid.trim() : null;
    const now = Date.now();

    const stmt = db.prepare('SELECT * FROM keys WHERE key_code = ?');
    const keyData = stmt.get(cleanKey);

    const logStmt = db.prepare(`
      INSERT INTO access_logs (key_code, hwid, ip, status, message, timestamp, roblox_username)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);

    // Check Blacklist
    const bl = this.isBlacklisted({ username: robloxUsername, userId: robloxUserId, hwid: cleanHwid, ip });
    if (bl) {
      logStmt.run(cleanKey, cleanHwid, ip, 'failed', `Blacklisted: ${bl.reason}`, now, robloxUsername);
      return {
        success: false,
        reason: 'blacklisted',
        message: `คุณถูกระงับสิทธิ์การใช้งานถาวร (Blacklisted): ${bl.reason || 'ละเมิดข้อตกลง'}`
      };
    }

    if (!keyData) {
      logStmt.run(cleanKey, cleanHwid, ip, 'failed', 'Invalid key', now, robloxUsername);
      return { success: false, reason: 'not_found', message: 'คีย์ไม่ถูกต้องหรือไม่มีในระบบ (Invalid key)' };
    }

    if (keyData.status === 'banned') {
      logStmt.run(cleanKey, cleanHwid, ip, 'failed', 'Key is banned', now, robloxUsername);
      return { success: false, reason: 'banned', message: 'คีย์นี้ถูกระงับการใช้งาน (Key is banned)' };
    }

    // Check expiration if activated
    if (keyData.activated_at) {
      if (keyData.expires_at && now > keyData.expires_at) {
        db.prepare('UPDATE keys SET status = ? WHERE id = ?').run('expired', keyData.id);
        logStmt.run(cleanKey, cleanHwid, ip, 'failed', 'Key expired', now, robloxUsername);
        return { success: false, reason: 'expired', message: 'คีย์นี้หมดอายุแล้ว (Key has expired)' };
      }

      // HWID Lock check
      if (keyData.hwid && cleanHwid && keyData.hwid !== cleanHwid) {
        logStmt.run(cleanKey, cleanHwid, ip, 'failed', 'HWID mismatch', now, robloxUsername);
        return {
          success: false,
          reason: 'hwid_mismatch',
          message: 'คีย์นี้ถูกล็อคกับอุปกรณ์อื่นแล้ว กรุณาแจ้งแอดมินเพื่อรีเซ็ต HWID (Key is locked to another device)'
        };
      }
    }

    // Activate key if first time
    let activatedAt = keyData.activated_at || now;
    let expiresAt = keyData.expires_at;
    let boundHwid = keyData.hwid || cleanHwid;
    let boundRobloxUser = keyData.roblox_username || robloxUsername;
    let boundRobloxId = keyData.roblox_user_id || robloxUserId;

    if (!keyData.activated_at) {
      if (keyData.duration_hours === 0) {
        expiresAt = null; // Lifetime
      } else {
        expiresAt = now + (keyData.duration_hours * 3600 * 1000);
      }
    }

    // Update key usage
    db.prepare(`
      UPDATE keys 
      SET activated_at = ?,
          expires_at = ?,
          hwid = ?,
          roblox_username = ?,
          roblox_user_id = ?,
          usage_count = usage_count + 1,
          last_used_at = ?
      WHERE id = ?
    `).run(activatedAt, expiresAt, boundHwid, boundRobloxUser, boundRobloxId, now, keyData.id);

    logStmt.run(cleanKey, boundHwid, ip, 'success', 'Verified successfully', now, robloxUsername);

    return {
      success: true,
      message: 'ยืนยันคีย์สำเร็จ! (Key verified successfully)',
      key: cleanKey,
      lifetime: keyData.duration_hours === 0,
      durationHours: keyData.duration_hours,
      activatedAt,
      expiresAt,
      hwid: boundHwid,
      usageCount: keyData.usage_count + 1,
      note: keyData.note || '',
      robloxUsername: boundRobloxUser,
      robloxUserId: boundRobloxId,
      tier: keyData.tier || 'VIP',
      maxScreens: keyData.max_screens !== undefined ? keyData.max_screens : 1,
      maxScreens: keyData.max_screens !== undefined ? keyData.max_screens : 1
    };
  },

  getAllKeys({ filter = 'all', search = '' } = {}) {
    let query = 'SELECT * FROM keys WHERE 1=1';
    const params = [];

    if (search && search.trim()) {
      query += ' AND (key_code LIKE ? OR note LIKE ? OR hwid LIKE ?)';
      const s = `%${search.trim()}%`;
      params.push(s, s, s);
    }

    const now = Date.now();
    if (filter === 'active') {
      query += " AND status = 'active' AND (expires_at IS NULL OR expires_at > ?)";
      params.push(now);
    } else if (filter === 'expired') {
      query += " AND (status = 'expired' OR (expires_at IS NOT NULL AND expires_at <= ?))";
      params.push(now);
    } else if (filter === 'banned') {
      query += " AND status = 'banned'";
    } else if (filter === 'bound') {
      query += ' AND hwid IS NOT NULL';
    }

    query += ' ORDER BY id DESC';
    const stmt = db.prepare(query);
    return stmt.all(...params);
  },

  getKeyByCode(keyCode) {
    if (!keyCode) return null;
    const cleanKey = keyCode.trim().toUpperCase();
    return db.prepare('SELECT * FROM keys WHERE key_code = ?').get(cleanKey);
  },

  updateKeyMaxScreens(keyCode, maxScreens) {
    if (!keyCode) return false;
    const cleanKey = keyCode.trim().toUpperCase();
    const screens = parseInt(maxScreens, 10) >= 0 ? parseInt(maxScreens, 10) : 1;
    db.prepare('UPDATE keys SET max_screens = ? WHERE key_code = ?').run(screens, cleanKey);
    return true;
  },

  deleteKey(keyCode) {
    const stmt = db.prepare('DELETE FROM keys WHERE key_code = ?');
    stmt.run(keyCode.trim().toUpperCase());
    return { success: true };
  },

  resetHwid(keyCode) {
    const stmt = db.prepare('UPDATE keys SET hwid = NULL WHERE key_code = ?');
    stmt.run(keyCode.trim().toUpperCase());
    return { success: true };
  },

  toggleKeyStatus(keyCode) {
    const key = db.prepare('SELECT status FROM keys WHERE key_code = ?').get(keyCode.trim().toUpperCase());
    if (!key) return { success: false, message: 'Key not found' };
    const newStatus = key.status === 'banned' ? 'active' : 'banned';
    db.prepare('UPDATE keys SET status = ? WHERE key_code = ?').run(newStatus, keyCode.trim().toUpperCase());
    return { success: true, status: newStatus };
  },

  getStats() {
    const now = Date.now();
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const totalKeys = db.prepare('SELECT COUNT(*) as count FROM keys').get().count;
    const activeKeys = db.prepare(`
      SELECT COUNT(*) as count FROM keys 
      WHERE status = 'active' AND (expires_at IS NULL OR expires_at > ?)
    `).get(now).count;
    const expiredKeys = db.prepare(`
      SELECT COUNT(*) as count FROM keys 
      WHERE status = 'expired' OR (expires_at IS NOT NULL AND expires_at <= ?)
    `).get(now).count;
    const bannedKeys = db.prepare("SELECT COUNT(*) as count FROM keys WHERE status = 'banned'").get().count;

    const verificationsToday = db.prepare(`
      SELECT COUNT(*) as count FROM access_logs 
      WHERE status = 'success' AND timestamp >= ?
    `).get(todayStart.getTime()).count;

    const totalVerifications = db.prepare(`
      SELECT COUNT(*) as count FROM access_logs WHERE status = 'success'
    `).get().count;

    return {
      totalKeys,
      activeKeys,
      expiredKeys,
      bannedKeys,
      verificationsToday,
      totalVerifications
    };
  },

  getRecentLogs(limit = 50) {
    const stmt = db.prepare('SELECT * FROM access_logs ORDER BY id DESC LIMIT ?');
    return stmt.all(limit);
  },

  claimFreeKey(ip = '127.0.0.1') {
    const now = Date.now();
    const cooldownMs = 24 * 3600 * 1000;
    const lastClaim = db.prepare('SELECT claimed_at FROM free_key_claims WHERE ip = ? ORDER BY id DESC LIMIT 1').get(ip);
    if (lastClaim && (now - lastClaim.claimed_at < cooldownMs)) {
      const waitHours = Math.ceil((cooldownMs - (now - lastClaim.claimed_at)) / (3600 * 1000));
      return {
        success: false,
        cooldown: true,
        message: `คุณได้รับคีย์ฟรีไปแล้วสำหรับวันนี้ กรุณารออีกประมาณ ${waitHours} ชั่วโมง หรือสนับสนุนคีย์ VIP`
      };
    }

    const keyResult = this.createKey({
      prefix: 'FREE-',
      durationHours: 24,
      note: `Free Daily Key (IP: ${ip})`,
      tier: 'FREE'
    });

    db.prepare('INSERT INTO free_key_claims (ip, key_code, claimed_at) VALUES (?, ?, ?)').run(ip, keyResult.key, now);

    return {
      success: true,
      key: keyResult.key,
      durationHours: 24,
      tier: 'FREE',
      message: 'รับคีย์ฟรี 24 ชม. สำเร็จแล้ว! สามารถนำไปรันในเกมได้ทันที'
    };
  },

  checkKeyStatus(keyCode) {
    if (!keyCode || typeof keyCode !== 'string') {
      return { success: false, message: 'กรุณากรอกรหัสคีย์' };
    }
    let cleanKey = keyCode.trim().toUpperCase().replace(/\s+/g, '-');
    let keyData = db.prepare('SELECT * FROM keys WHERE key_code = ?').get(cleanKey);

    // Smart fallback 1: Strip dashes and spaces
    if (!keyData) {
      const rawClean = keyCode.trim().toUpperCase().replace(/[-_\s]/g, '');
      const allKeys = db.prepare('SELECT * FROM keys').all();
      keyData = allKeys.find(k => k.key_code.replace(/[-_\s]/g, '') === rawClean);

      // Smart fallback 2: Typo tolerance (G vs 6, O vs 0)
      if (!keyData) {
        const fuzzyTarget = rawClean.replace(/G/g, '6').replace(/O/g, '0');
        keyData = allKeys.find(k => k.key_code.replace(/[-_\s]/g, '').replace(/G/g, '6').replace(/O/g, '0') === fuzzyTarget);
      }
    }

    if (!keyData) {
      return { success: false, message: 'ไม่พบคีย์นี้ในระบบ กรุณาตรวจสอบตัวอักษรอีกครั้ง' };
    }
    cleanKey = keyData.key_code;

    const now = Date.now();
    let statusText = 'พร้อมใช้งาน (Active)';
    let isExpired = false;

    if (keyData.status === 'banned') {
      statusText = 'ถูกระงับการใช้งาน (Banned)';
    } else if (keyData.activated_at && keyData.expires_at && now > keyData.expires_at) {
      statusText = 'หมดอายุแล้ว (Expired)';
      isExpired = true;
    } else if (!keyData.activated_at) {
      statusText = 'ยังไม่ได้เปิดใช้งาน (ยังไม่เริ่มนับเวลา)';
    }

    let remainingHours = null;
    if (keyData.expires_at && !isExpired) {
      remainingHours = Math.max(0, Math.ceil((keyData.expires_at - now) / (3600 * 1000)));
    }

    return {
      success: true,
      key: cleanKey,
      tier: keyData.tier || 'VIP',
      status: keyData.status,
      statusText,
      lifetime: keyData.duration_hours === 0,
      durationHours: keyData.duration_hours,
      activatedAt: keyData.activated_at,
      expiresAt: keyData.expires_at,
      remainingHours,
      hwidBound: !!keyData.hwid,
      robloxUser: keyData.roblox_username || null
    };
  },

  isBlacklisted({ username = null, userId = null, hwid = null, ip = null }) {
    const checks = [];
    if (username) checks.push({ type: 'username', val: username.toLowerCase() });
    if (userId) checks.push({ type: 'user_id', val: String(userId) });
    if (hwid) checks.push({ type: 'hwid', val: hwid.toLowerCase() });
    if (ip) checks.push({ type: 'ip', val: ip });

    for (const c of checks) {
      const match = db.prepare('SELECT * FROM blacklist WHERE type = ? AND LOWER(target) = ?').get(c.type, c.val);
      if (match) return match;
    }
    return false;
  },

  addBlacklist({ type, target, reason = '' }) {
    if (!type || !target) return { success: false, message: 'Type and Target are required' };
    const cleanTarget = target.trim();
    try {
      db.prepare('INSERT INTO blacklist (type, target, reason, created_at) VALUES (?, ?, ?, ?)').run(type, cleanTarget, reason || '', Date.now());
      return { success: true, message: `เพิ่ม ${cleanTarget} เข้า Blacklist เรียบร้อยแล้ว` };
    } catch (err) {
      return { success: false, message: 'เป้าหมายนี้อยู่ใน Blacklist อยู่แล้ว' };
    }
  },

  removeBlacklist(id) {
    db.prepare('DELETE FROM blacklist WHERE id = ?').run(id);
    return { success: true, message: 'ลบออกจาก Blacklist เรียบร้อยแล้ว' };
  },

  getBlacklist() {
    return db.prepare('SELECT * FROM blacklist ORDER BY id DESC').all();
  },

  getAnalytics() {
    const now = Date.now();
    const dayMs = 24 * 3600 * 1000;
    const days = [];

    for (let i = 6; i >= 0; i--) {
      const dayStart = new Date(now - i * dayMs);
      dayStart.setHours(0, 0, 0, 0);
      const dayEnd = new Date(dayStart.getTime() + dayMs);

      const count = db.prepare("SELECT COUNT(*) as count FROM access_logs WHERE status = 'success' AND timestamp >= ? AND timestamp < ?").get(dayStart.getTime(), dayEnd.getTime()).count;

      const label = dayStart.toLocaleDateString('th-TH', { weekday: 'short', day: 'numeric' });
      days.push({ label, count });
    }

    const vipCount = db.prepare("SELECT COUNT(*) as count FROM keys WHERE tier = 'VIP'").get().count;
    const freeCount = db.prepare("SELECT COUNT(*) as count FROM keys WHERE tier = 'FREE'").get().count;
    const premiumCount = db.prepare("SELECT COUNT(*) as count FROM keys WHERE tier = 'PREMIUM'").get().count;

    return {
      dailyTrend: days,
      tiers: { vip: vipCount, free: freeCount, premium: premiumCount }
    };
  }
};

module.exports = dbManager;
