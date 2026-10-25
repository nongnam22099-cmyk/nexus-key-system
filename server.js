const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const db = require('./db');

const configPath = path.join(__dirname, 'config.json');
let config = {
  port: 3000,
  adminPassword: 'admin',
  secretKey: 'nexus-secret-key',
  keyPrefix: 'NEXUS-',
  scriptPath: 'C:/Users/nongn/AppData/Local/Real/workspace/NexusHub.lua',
  discordWebhookUrl: '',
  webhookEnabled: false,
  notifyOnSuccess: true,
  notifyOnFailed: true
};

if (fs.existsSync(configPath)) {
  try {
    config = { ...config, ...JSON.parse(fs.readFileSync(configPath, 'utf8')) };
  } catch (e) {
    console.error('Error reading config.json:', e);
  }
}

function saveConfig() {
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2), 'utf8');
}

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public'), { dotfiles: 'allow' }));

// Simple Token Storage
const activeSessions = new Set();

// Active In-Game Players Tracker
const activePlayers = new Map();

function cleanInactivePlayers() {
  const now = Date.now();
  for (const [key, player] of activePlayers.entries()) {
    if (now - player.lastSeen > 60000) {
      activePlayers.delete(key);
    }
  }
}
setInterval(cleanInactivePlayers, 20000);

function generateSessionToken() {
  const token = crypto.randomBytes(32).toString('hex');
  activeSessions.add(token);
  return token;
}

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Unauthorized' });
  }
  const token = authHeader.split(' ')[1];
  if (!activeSessions.has(token)) {
    return res.status(401).json({ success: false, message: 'Session expired or invalid' });
  }
  next();
}

// ----------------------------------------------------
// Public APIs for Roblox Client / User
// ----------------------------------------------------

// Discord Webhook Notification System
async function sendDiscordWebhook(type, data = {}) {
  if (!config.webhookEnabled || !config.discordWebhookUrl) return;
  if (type === 'success' && config.notifyOnSuccess === false) return;
  if (type === 'failed' && config.notifyOnFailed === false) return;

  let embed = null;

  if (type === 'test') {
    embed = {
      title: '🟢 Nexus Hub | ทดสอบการเชื่อมต่อ Webhook',
      description: 'ระบบเชื่อมต่อ Discord Webhook สำเร็จเรียบร้อยแล้ว!\nเมื่อมีคนนำคีย์ไปใช้งานในเกม จะมีการแจ้งเตือนเข้ามาที่ห้องนี้ทันที',
      color: 0x00E5FF,
      fields: [
        { name: 'สถานะระบบ', value: '✅ ออนไลน์และพร้อมส่งการแจ้งเตือน', inline: true },
        { name: 'เวลาทดสอบ', value: new Date().toLocaleString('th-TH'), inline: true }
      ],
      footer: { text: 'Nexus Hub Key Management System' },
      timestamp: new Date().toISOString()
    };
  } else if (type === 'success') {
    const isFirstTime = data.usageCount === 1;
    const playerText = (data.userId && data.userId !== '0' && data.username && data.username !== 'Unknown')
      ? `[${data.displayName || data.username} (@${data.username})](https://www.roblox.com/users/${data.userId}/profile)`
      : (data.username || 'Unknown');

    embed = {
      title: isFirstTime ? '🎉 คีย์ถูกเปิดใช้งานครั้งแรก! (Key Activated)' : '🔑 มีการเข้าสู่ระบบสำเร็จ (Login Success)',
      color: isFirstTime ? 0x00FF88 : 0x00E5FF,
      thumbnail: (data.userId && data.userId !== '0') ? {
        url: `https://www.roblox.com/headshot-thumbnail/image?userId=${data.userId}&width=420&height=420&format=png`
      } : undefined,
      fields: [
        { name: '👤 ผู้เล่น Roblox (User)', value: playerText, inline: true },
        { name: '🆔 Roblox User ID', value: `\`${data.userId || '-'}\``, inline: true },
        { name: '🔑 รหัสคีย์ (Key)', value: `\`${data.key || '-'}\``, inline: true },
        { name: '⏳ อายุการใช้งาน', value: data.lifetime ? 'ถาวร (Lifetime)' : `${data.durationHours} ชม.`, inline: true },
        { name: '📝 โน้ต / ผู้ซื้อ', value: data.note || '-', inline: true },
        { name: '📅 วันหมดอายุ', value: data.lifetime ? 'ไม่มีวันหมดอายุ (Lifetime)' : (data.expiresAt ? new Date(data.expiresAt).toLocaleString('th-TH') : '-'), inline: true },
        { name: '💻 อุปกรณ์ (HWID)', value: `\`${data.hwid || 'N/A'}\``, inline: false },
        { name: '🌐 IP Address', value: `\`${data.ip || 'Unknown'}\``, inline: true }
      ],
      footer: { text: `Nexus Hub License Monitor • ใช้งานครั้งที่ ${data.usageCount || 1}` },
      timestamp: new Date().toISOString()
    };
  } else if (type === 'failed') {
    const isHwidMismatch = data.reason === 'hwid_mismatch';
    const playerText = (data.userId && data.userId !== '0' && data.username && data.username !== 'Unknown')
      ? `[${data.displayName || data.username} (@${data.username})](https://www.roblox.com/users/${data.userId}/profile)`
      : (data.username || 'Unknown');

    embed = {
      title: isHwidMismatch ? '⚠️ ตรวจพบการพยายามแชร์คีย์! (HWID Mismatch)' : '⛔ การตรวจสอบคีย์ล้มเหลว',
      description: isHwidMismatch 
        ? 'มีคนพยายามนำคีย์ไปใช้งานบนอุปกรณ์อื่นที่ไม่ตรงกับเครื่องที่บันทึกไว้!' 
        : `ข้อความ: ${data.message || data.reason}`,
      color: isHwidMismatch ? 0xFF4757 : 0xFFB703,
      thumbnail: (data.userId && data.userId !== '0') ? {
        url: `https://www.roblox.com/headshot-thumbnail/image?userId=${data.userId}&width=420&height=420&format=png`
      } : undefined,
      fields: [
        { name: '👤 ผู้เล่น Roblox ที่กดรัน', value: playerText, inline: true },
        { name: '🆔 User ID', value: `\`${data.userId || '-'}\``, inline: true },
        { name: '🔑 รหัสคีย์ที่ใช้', value: `\`${data.key || 'N/A'}\``, inline: true },
        { name: '💻 อุปกรณ์ที่พยายามเข้า', value: `\`${data.hwid || 'Unknown'}\``, inline: false },
        { name: '🌐 IP Address', value: `\`${data.ip || 'Unknown'}\``, inline: true }
      ],
      footer: { text: 'Nexus Hub Security Alert' },
      timestamp: new Date().toISOString()
    };
  }

  if (!embed) return;

  try {
    await fetch(config.discordWebhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'Nexus Hub Monitor',
        avatar_url: 'https://cdn-icons-png.flaticon.com/512/906/906343.png',
        embeds: [embed]
      })
    });
  } catch (err) {
    console.error('[Discord Webhook Error]:', err.message);
  }
}

// Verify Key (supports both POST and GET)
function handleVerify(req, res) {
  const key = (req.body && req.body.key) || req.query.key;
  const hwid = (req.body && req.body.hwid) || req.query.hwid;
  const username = (req.body && req.body.username) || req.query.username || 'Unknown';
  const displayName = (req.body && req.body.displayName) || req.query.displayName || username;
  const userId = (req.body && req.body.userId) || req.query.userId || '0';
  const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';

  // Check Maintenance Mode
  if (config.maintenanceMode) {
    return res.json({
      success: false,
      reason: 'maintenance',
      message: config.maintenanceReason || 'ระบบปิดปรับปรุงชั่วคราวเพื่ออัปเดตความปลอดภัย กรุณารอประกาศ'
    });
  }

  const result = db.verifyKey(key, hwid, ip, username, userId);

  // Send Discord Webhook in background
  if (result.success) {
    sendDiscordWebhook('success', { ...result, ip, username, displayName, userId });
  } else {
    sendDiscordWebhook('failed', { key, hwid, ip, username, displayName, userId, reason: result.reason, message: result.message });
  }

  return res.json(result);
}

app.post('/api/verify', handleVerify);
app.get('/api/verify', handleVerify);

// In-game client Heartbeat & Notification Polling
function handleHeartbeat(req, res) {
  const key = (req.body && req.body.key) || req.query.key;
  const hwid = (req.body && req.body.hwid) || req.query.hwid;
  const username = (req.body && req.body.username) || req.query.username || 'Unknown';
  const displayName = (req.body && req.body.displayName) || req.query.displayName || username;
  const userId = (req.body && req.body.userId) || req.query.userId || '0';
  const jobId = (req.body && req.body.jobId) || req.query.jobId || 'Unknown';
  const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';

  // Check Blacklist
  const bl = db.isBlacklisted({ username, userId, hwid, ip });
  if (bl) {
    return res.json({
      success: false,
      blacklisted: true,
      reason: bl.reason || 'คุณถูกระงับสิทธิ์การใช้งานถาวร'
    });
  }

  if (userId && userId !== '0') {
    const playerKey = `${userId}_${key || 'guest'}`;
    const existing = activePlayers.get(playerKey);
    activePlayers.set(playerKey, {
      userId,
      username,
      displayName,
      key: key || '-',
      jobId,
      firstSeen: existing ? existing.firstSeen : Date.now(),
      lastSeen: Date.now()
    });
  }

  return res.json({
    success: true,
    maintenance: !!config.maintenanceMode,
    maintenanceReason: config.maintenanceReason,
    announcement: config.announcement && config.announcement.active ? config.announcement : null,
    gameSettings: config.gameSettings || {
      farmSpeedMultiplier: 1.0,
      miningDelaySeconds: 1.5,
      autoVaultEnabled: true,
      antiAfkEnabled: true
    }
  });
}

app.get('/api/heartbeat', handleHeartbeat);
app.post('/api/heartbeat', handleHeartbeat);

// Serve the loader script directly (dynamically adapts API_URL to current host)
app.get('/loader', (req, res) => {
  res.setHeader('Content-Type', 'text/plain; charset=utf-8');
  try {
    const proto = req.headers['x-forwarded-proto'] || req.protocol || 'http';
    const host = req.get('host');
    const baseUrl = `${proto}://${host}`;
    let loaderContent = fs.readFileSync(path.join(__dirname, 'roblox_loader.lua'), 'utf8');
    loaderContent = loaderContent.replace(/local API_URL = "http:\/\/localhost:3000"/g, `local API_URL = "${baseUrl}"`);
    return res.send(loaderContent);
  } catch (err) {
    return res.sendFile(path.join(__dirname, 'roblox_loader.lua'), { dotfiles: 'allow' });
  }
});

// Secure Loader endpoint: returns script content if key is valid
app.get('/api/get-script', (req, res) => {
  if (config.maintenanceMode) {
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    return res.send(`-- [Nexus Hub] Maintenance Mode\nerror("[Nexus Hub] Server Maintenance: ${config.maintenanceReason || 'ปิดปรับปรุงชั่วคราว'}", 0)`);
  }

  const key = req.query.key;
  const hwid = req.query.hwid;
  const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';

  const verify = db.verifyKey(key, hwid, ip);
  res.setHeader('Content-Type', 'text/plain; charset=utf-8');

  if (!verify.success) {
    return res.send(`-- [Nexus Hub] Access Denied\nerror("[Nexus Hub] Key Verification Failed: ${verify.message}", 0)`);
  }

  // Load script
  const localScript = path.join(__dirname, 'nexus_hub.lua');
  const targetScript = (config.scriptPath && fs.existsSync(config.scriptPath)) ? config.scriptPath : localScript;

  if (fs.existsSync(targetScript)) {
    const script = fs.readFileSync(targetScript, 'utf8');
    return res.send(script);
  } else {
    return res.send(`-- [Nexus Hub]\nprint("[Nexus Hub] Authenticated successfully, but script file was not found on server!")`);
  }
});

// ----------------------------------------------------
// Auth APIs
// ----------------------------------------------------

app.post('/api/auth/login', (req, res) => {
  const { password } = req.body;
  if (!password || password !== config.adminPassword) {
    return res.status(401).json({ success: false, message: 'รหัสผ่านไม่ถูกต้อง (Incorrect password)' });
  }
  const token = generateSessionToken();
  return res.json({ success: true, token, message: 'Login successful' });
});

app.post('/api/auth/logout', authMiddleware, (req, res) => {
  const token = req.headers.authorization.split(' ')[1];
  activeSessions.delete(token);
  return res.json({ success: true });
});

app.get('/api/auth/check', authMiddleware, (req, res) => {
  return res.json({ success: true, message: 'Authenticated' });
});

// ----------------------------------------------------
// Protected Admin APIs
// ----------------------------------------------------

app.get('/api/admin/stats', authMiddleware, (req, res) => {
  const stats = db.getStats();
  res.json({ success: true, stats });
});

app.get('/api/admin/keys', authMiddleware, (req, res) => {
  const { filter, search } = req.query;
  const keys = db.getAllKeys({ filter, search });
  res.json({ success: true, keys });
});

app.post('/api/admin/keys/generate', authMiddleware, (req, res) => {
  const { durationHours = 24, note = '', count = 1, prefix, customKey, tier = 'VIP' } = req.body;
  const keyPrefix = prefix || config.keyPrefix || 'NEXUS-';

  if (customKey && customKey.trim()) {
    try {
      const result = db.createKey({
        prefix: keyPrefix,
        durationHours: parseInt(durationHours, 10),
        note,
        customKey: customKey.trim(),
        tier
      });
      return res.json({ success: true, keys: [result.key] });
    } catch (err) {
      return res.status(400).json({ success: false, message: 'คีย์นี้มีอยู่ในระบบแล้ว (Key already exists)' });
    }
  }

  const generated = db.createBulkKeys({
    prefix: keyPrefix,
    durationHours: parseInt(durationHours, 10),
    note,
    count: parseInt(count, 10) || 1,
    tier
  });

  return res.json({ success: true, keys: generated });
});

app.post('/api/admin/keys/delete', authMiddleware, (req, res) => {
  const { key } = req.body;
  if (!key) return res.status(400).json({ success: false, message: 'Key is required' });
  db.deleteKey(key);
  return res.json({ success: true, message: 'Key deleted' });
});

app.post('/api/admin/keys/reset-hwid', authMiddleware, (req, res) => {
  const { key } = req.body;
  if (!key) return res.status(400).json({ success: false, message: 'Key is required' });
  db.resetHwid(key);
  return res.json({ success: true, message: 'HWID reset successful' });
});

app.post('/api/admin/keys/toggle-status', authMiddleware, (req, res) => {
  const { key } = req.body;
  if (!key) return res.status(400).json({ success: false, message: 'Key is required' });
  const result = db.toggleKeyStatus(key);
  return res.json(result);
});

app.get('/api/admin/logs', authMiddleware, (req, res) => {
  const limit = parseInt(req.query.limit, 10) || 50;
  const logs = db.getRecentLogs(limit);
  res.json({ success: true, logs });
});

app.post('/api/admin/change-password', authMiddleware, (req, res) => {
  const { currentPassword, newPassword } = req.body;
  if (currentPassword !== config.adminPassword) {
    return res.status(400).json({ success: false, message: 'รหัสผ่านปัจจุบันไม่ถูกต้อง' });
  }
  if (!newPassword || newPassword.length < 4) {
    return res.status(400).json({ success: false, message: 'รหัสผ่านใหม่ต้องมีความยาวอย่างน้อย 4 ตัวอักษร' });
  }
  config.adminPassword = newPassword;
  saveConfig();
  return res.json({ success: true, message: 'เปลี่ยนรหัสผ่านเรียบร้อยแล้ว' });
});

// Webhook APIs
app.get('/api/admin/webhook', authMiddleware, (req, res) => {
  res.json({
    success: true,
    webhookUrl: config.discordWebhookUrl || '',
    webhookEnabled: !!config.webhookEnabled,
    notifyOnSuccess: config.notifyOnSuccess !== false,
    notifyOnFailed: config.notifyOnFailed !== false
  });
});

app.post('/api/admin/webhook', authMiddleware, (req, res) => {
  const { webhookUrl, webhookEnabled, notifyOnSuccess, notifyOnFailed } = req.body;
  config.discordWebhookUrl = (webhookUrl || '').trim();
  config.webhookEnabled = !!webhookEnabled;
  config.notifyOnSuccess = !!notifyOnSuccess;
  config.notifyOnFailed = !!notifyOnFailed;
  saveConfig();
  return res.json({ success: true, message: 'บันทึกการตั้งค่า Discord Webhook สำเร็จแล้ว' });
});

app.post('/api/admin/webhook/test', authMiddleware, async (req, res) => {
  const { webhookUrl } = req.body;
  const targetUrl = (webhookUrl || config.discordWebhookUrl || '').trim();
  if (!targetUrl) {
    return res.status(400).json({ success: false, message: 'กรุณาระบุ Discord Webhook URL' });
  }

  try {
    const response = await fetch(targetUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'Nexus Hub Monitor',
        avatar_url: 'https://cdn-icons-png.flaticon.com/512/906/906343.png',
        embeds: [{
          title: '🟢 Nexus Hub | ทดสอบการเชื่อมต่อ Discord Webhook',
          description: 'ระบบเชื่อมต่อ Discord Webhook สำเร็จเรียบร้อยแล้ว!\nเมื่อมีคนนำคีย์ไปใช้งานในเกม จะมีการแจ้งเตือนเข้ามาที่ห้องนี้ทันที',
          color: 0x00E5FF,
          fields: [
            { name: 'สถานะระบบ', value: '✅ ออนไลน์และพร้อมทำงาน', inline: true },
            { name: 'เวลาทดสอบ', value: new Date().toLocaleString('th-TH'), inline: true }
          ],
          footer: { text: 'Nexus Hub License Management System' },
          timestamp: new Date().toISOString()
        }]
      })
    });

    if (response.ok) {
      return res.json({ success: true, message: 'ส่งข้อความทดสอบเข้า Discord สำเร็จแล้ว!' });
    } else {
      const errText = await response.text();
      return res.status(400).json({ success: false, message: `Discord แจ้งเตือนข้อผิดพลาด: ${errText}` });
    }
  } catch (err) {
    return res.status(500).json({ success: false, message: `ไม่สามารถส่งได้: ${err.message}` });
  }
});

// ----------------------------------------------------
// Maintenance & Broadcast APIs
// ----------------------------------------------------

app.get('/api/admin/maintenance', authMiddleware, (req, res) => {
  res.json({
    success: true,
    maintenanceMode: !!config.maintenanceMode,
    maintenanceReason: config.maintenanceReason || 'ระบบปิดปรับปรุงชั่วคราวเพื่ออัปเดตความปลอดภัย กรุณารอประกาศ'
  });
});

app.post('/api/admin/maintenance', authMiddleware, (req, res) => {
  const { maintenanceMode, maintenanceReason } = req.body;
  config.maintenanceMode = !!maintenanceMode;
  if (maintenanceReason && maintenanceReason.trim()) {
    config.maintenanceReason = maintenanceReason.trim();
  }
  saveConfig();
  return res.json({
    success: true,
    maintenanceMode: config.maintenanceMode,
    message: config.maintenanceMode ? 'เปิดโหมดปิดปรับปรุงฉุกเฉินแล้ว (สคริปต์ในเกมจะหยุดทำงาน)' : 'ปิดโหมดปรับปรุงแล้ว (ระบบกลับมาออนไลน์ปกติ)'
  });
});

app.get('/api/admin/announcement', authMiddleware, (req, res) => {
  res.json({ success: true, announcement: config.announcement });
});

app.post('/api/admin/announcement', authMiddleware, (req, res) => {
  const { title, message } = req.body;
  if (!message || !message.trim()) {
    return res.status(400).json({ success: false, message: 'กรุณากรอกข้อความประกาศ' });
  }
  config.announcement = {
    id: Date.now(),
    title: (title || 'Nexus Hub Announcement').trim(),
    message: message.trim(),
    active: true
  };
  saveConfig();
  return res.json({ success: true, message: 'ส่งประกาศเข้าเกมเรียบร้อยแล้ว!' });
});

app.post('/api/admin/announcement/clear', authMiddleware, (req, res) => {
  if (config.announcement) {
    config.announcement.active = false;
  }
  saveConfig();
  return res.json({ success: true, message: 'ลบประกาศเรียบร้อยแล้ว' });
});

// Online Players API
app.get('/api/admin/online-players', authMiddleware, (req, res) => {
  cleanInactivePlayers();
  const now = Date.now();
  const players = Array.from(activePlayers.values()).map(p => ({
    ...p,
    onlineMinutes: Math.max(1, Math.floor((now - p.firstSeen) / 60000))
  }));
  return res.json({ success: true, count: players.length, players });
});

// Blacklist APIs
app.get('/api/admin/blacklist', authMiddleware, (req, res) => {
  const list = db.getBlacklist();
  res.json({ success: true, list });
});

app.post('/api/admin/blacklist/add', authMiddleware, (req, res) => {
  const { type, target, reason } = req.body;
  const result = db.addBlacklist({ type, target, reason });
  res.json(result);
});

app.post('/api/admin/blacklist/remove', authMiddleware, (req, res) => {
  const { id } = req.body;
  const result = db.removeBlacklist(id);
  res.json(result);
});

// Remote Game Settings APIs
app.get('/api/admin/game-settings', authMiddleware, (req, res) => {
  res.json({ success: true, settings: config.gameSettings || {} });
});

app.post('/api/admin/game-settings', authMiddleware, (req, res) => {
  const { farmSpeedMultiplier, miningDelaySeconds, autoVaultEnabled, antiAfkEnabled, whiteCircleBypass } = req.body;
  config.gameSettings = {
    farmSpeedMultiplier: parseFloat(farmSpeedMultiplier) || 1.0,
    miningDelaySeconds: parseFloat(miningDelaySeconds) || 1.5,
    autoVaultEnabled: !!autoVaultEnabled,
    antiAfkEnabled: !!antiAfkEnabled,
    whiteCircleBypass: !!whiteCircleBypass
  };
  saveConfig();
  res.json({ success: true, message: 'บันทึกการตั้งค่าสคริปต์ในเกมเรียบร้อยแล้ว (จะส่งผลต่อผู้เล่นทันที)' });
});

// Analytics API
app.get('/api/admin/analytics', authMiddleware, (req, res) => {
  const analytics = db.getAnalytics();
  res.json({ success: true, analytics });
});

// Backup Download API
app.get('/api/admin/backup/download', authMiddleware, (req, res) => {
  const dbFile = path.join(__dirname, 'database.sqlite');
  if (fs.existsSync(dbFile)) {
    res.download(dbFile, `nexus_backup_${Date.now()}.sqlite`);
  } else {
    res.status(404).send('Database file not found');
  }
});

// Monetization Gateway APIs
app.get('/api/admin/monetization', authMiddleware, (req, res) => {
  res.json({ success: true, monetization: config.monetization || { enabled: false, gatewayUrl: '' } });
});

app.post('/api/admin/monetization', authMiddleware, (req, res) => {
  const { enabled, gatewayUrl } = req.body;
  config.monetization = {
    enabled: !!enabled,
    gatewayUrl: (gatewayUrl || '').trim()
  };
  saveConfig();
  res.json({ success: true, message: 'บันทึกการตั้งค่าระบบสร้างรายได้ (Monetization) แล้ว' });
});

// ----------------------------------------------------
// Public APIs for /getkey Page
// ----------------------------------------------------

app.post('/api/public/check-key', (req, res) => {
  const { key } = req.body;
  const result = db.checkKeyStatus(key);
  return res.json(result);
});

app.post('/api/public/claim-free-key', (req, res) => {
  const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';
  const result = db.claimFreeKey(ip);
  return res.json(result);
});

// Page routing fallback
app.get('/', (req, res) => {
  res.redirect('/dashboard');
});

app.get('/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'), { dotfiles: 'allow' });
});

app.get('/login', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'login.html'), { dotfiles: 'allow' });
});

app.get('/getkey', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'getkey.html'), { dotfiles: 'allow' });
});

// Start Server
const PORT = process.env.PORT || config.port || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`===============================================`);
  console.log(` Nexus Hub Key System is running!`);
  console.log(` Admin Web:  http://localhost:${PORT}`);
  console.log(` Default Password:  ${config.adminPassword}`);
  console.log(` Roblox API: http://localhost:${PORT}/api/verify`);
  console.log(`===============================================`);
});
