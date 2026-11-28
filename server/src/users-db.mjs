import { DatabaseSync } from 'node:sqlite';
import crypto from 'node:crypto';

const DEFAULT_LEVELS = [
  { level_number: 1, title_ar: 'مبتدئ', min_xp: 0, max_rooms: 1, max_mics: 6, badge_color: '#94A3B8' },
  { level_number: 2, title_ar: 'متفاعل', min_xp: 100, max_rooms: 2, max_mics: 8, badge_color: '#60A5FA' },
  { level_number: 3, title_ar: 'نشيط', min_xp: 350, max_rooms: 3, max_mics: 8, badge_color: '#34D399' },
  { level_number: 4, title_ar: 'متألق', min_xp: 800, max_rooms: 4, max_mics: 10, badge_color: '#A78BFA' },
  { level_number: 5, title_ar: 'نجم الغرفة', min_xp: 1500, max_rooms: 5, max_mics: 12, badge_color: '#FBBF24' },
  { level_number: 6, title_ar: 'مضيف محترف', min_xp: 3000, max_rooms: 7, max_mics: 12, badge_color: '#F97316' },
  { level_number: 7, title_ar: 'سفير هلا', min_xp: 6000, max_rooms: 10, max_mics: 16, badge_color: '#EC4899' },
  { level_number: 8, title_ar: 'قائد مجتمع', min_xp: 12000, max_rooms: 15, max_mics: 16, badge_color: '#8B5CF6' },
  { level_number: 9, title_ar: 'نخبة هلا', min_xp: 25000, max_rooms: 20, max_mics: 20, badge_color: '#EF4444' },
  { level_number: 10, title_ar: 'أسطورة هلا', min_xp: 50000, max_rooms: 30, max_mics: 24, badge_color: '#EAB308' }
];

const DEFAULT_PERMISSIONS = [
  { code: 'room.create', label_ar: 'إنشاء غرفة صوتية', category: 'rooms' },
  { code: 'room.manage', label_ar: 'إدارة إعدادات الغرفة', category: 'rooms' },
  { code: 'room.mic_control', label_ar: 'التحكم بالمايكات', category: 'rooms' },
  { code: 'room.kick_user', label_ar: 'طرد مستخدم من الغرفة', category: 'moderation' },
  { code: 'room.mute_user', label_ar: 'كتم مستخدم', category: 'moderation' },
  { code: 'gift.send', label_ar: 'إرسال الهدايا', category: 'gifts' },
  { code: 'user.view_profiles', label_ar: 'عرض ملفات المستخدمين', category: 'users' },
  { code: 'user.ban', label_ar: 'حظر المستخدمين', category: 'admin' },
  { code: 'user.manage_roles', label_ar: 'إدارة الأدوار والصلاحيات', category: 'admin' },
  { code: 'admin.dashboard', label_ar: 'الوصول للوحة التحكم', category: 'admin' }
];

const DEFAULT_ROLE_PERMISSIONS = [
  ['user', 'room.create'],
  ['user', 'gift.send'],
  ['user', 'user.view_profiles'],
  ['vip', 'room.create'],
  ['vip', 'room.manage'],
  ['vip', 'gift.send'],
  ['vip', 'user.view_profiles'],
  ['moderator', 'room.create'],
  ['moderator', 'room.manage'],
  ['moderator', 'room.mic_control'],
  ['moderator', 'room.kick_user'],
  ['moderator', 'room.mute_user'],
  ['moderator', 'gift.send'],
  ['moderator', 'user.view_profiles'],
  ['admin', 'room.create'],
  ['admin', 'room.manage'],
  ['admin', 'room.mic_control'],
  ['admin', 'room.kick_user'],
  ['admin', 'room.mute_user'],
  ['admin', 'gift.send'],
  ['admin', 'user.view_profiles'],
  ['admin', 'user.ban'],
  ['admin', 'admin.dashboard'],
  ['super_admin', 'room.create'],
  ['super_admin', 'room.manage'],
  ['super_admin', 'room.mic_control'],
  ['super_admin', 'room.kick_user'],
  ['super_admin', 'room.mute_user'],
  ['super_admin', 'gift.send'],
  ['super_admin', 'user.view_profiles'],
  ['super_admin', 'user.ban'],
  ['super_admin', 'user.manage_roles'],
  ['super_admin', 'admin.dashboard']
];

export function initUsersDb(dbOrPath) {
  const db = typeof dbOrPath === 'string' ? new DatabaseSync(dbOrPath) : dbOrPath;
  if (!db) {
    throw new Error('A DatabaseSync instance or database file path is required');
  }

  db.exec(`
    PRAGMA foreign_keys = ON;

    CREATE TABLE IF NOT EXISTS user_levels (
      level_number INTEGER PRIMARY KEY,
      title_ar TEXT NOT NULL,
      min_xp INTEGER NOT NULL DEFAULT 0,
      max_rooms INTEGER NOT NULL DEFAULT 1,
      max_mics INTEGER NOT NULL DEFAULT 6,
      badge_color TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS permissions (
      code TEXT PRIMARY KEY,
      label_ar TEXT NOT NULL,
      category TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS role_permissions (
      role TEXT NOT NULL,
      permission_code TEXT NOT NULL,
      PRIMARY KEY (role, permission_code),
      FOREIGN KEY (permission_code) REFERENCES permissions(code) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT UNIQUE,
      display_name TEXT,
      email TEXT UNIQUE,
      phone TEXT UNIQUE,
      facebook_id TEXT UNIQUE,
      google_id TEXT UNIQUE,
      gmail_email TEXT,
      gender TEXT DEFAULT 'unspecified',
      country_code TEXT,
      country_name TEXT,
      level INTEGER NOT NULL DEFAULT 1,
      xp INTEGER NOT NULL DEFAULT 0,
      role TEXT NOT NULL DEFAULT 'user',
      status TEXT NOT NULL DEFAULT 'active',
      last_ip TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now')),
      last_login_at TEXT,
      FOREIGN KEY (level) REFERENCES user_levels(level_number) ON UPDATE CASCADE
    );

    CREATE TABLE IF NOT EXISTS user_permissions (
      user_id TEXT NOT NULL,
      permission_code TEXT NOT NULL,
      granted INTEGER NOT NULL DEFAULT 1,
      granted_by TEXT,
      updated_at TEXT NOT NULL DEFAULT (datetime('now')),
      PRIMARY KEY (user_id, permission_code),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (permission_code) REFERENCES permissions(code) ON DELETE CASCADE,
      FOREIGN KEY (granted_by) REFERENCES users(id) ON DELETE SET NULL
    );

    CREATE TABLE IF NOT EXISTS user_auth_providers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL,
      provider TEXT NOT NULL,
      provider_uid TEXT NOT NULL,
      provider_email TEXT,
      linked_at TEXT NOT NULL DEFAULT (datetime('now')),
      UNIQUE (provider, provider_uid),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS user_ip_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL,
      ip_address TEXT NOT NULL,
      country TEXT,
      user_agent TEXT,
      action TEXT NOT NULL DEFAULT 'login',
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS user_rooms (
      room_id TEXT PRIMARY KEY,
      owner_user_id TEXT NOT NULL,
      title_ar TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'general',
      room_level INTEGER NOT NULL DEFAULT 1,
      mic_count INTEGER NOT NULL DEFAULT 8,
      status TEXT NOT NULL DEFAULT 'active',
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
    CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
    CREATE INDEX IF NOT EXISTS idx_users_level ON users(level);
    CREATE INDEX IF NOT EXISTS idx_users_country ON users(country_code);
    CREATE INDEX IF NOT EXISTS idx_users_last_login ON users(last_login_at);
    CREATE INDEX IF NOT EXISTS idx_role_permissions_role ON role_permissions(role);
    CREATE INDEX IF NOT EXISTS idx_user_permissions_user_id ON user_permissions(user_id);
    CREATE INDEX IF NOT EXISTS idx_user_auth_providers_user_id ON user_auth_providers(user_id);
    CREATE INDEX IF NOT EXISTS idx_user_ip_logs_user_id ON user_ip_logs(user_id);
    CREATE INDEX IF NOT EXISTS idx_user_ip_logs_ip ON user_ip_logs(ip_address);
    CREATE INDEX IF NOT EXISTS idx_user_ip_logs_created_at ON user_ip_logs(created_at);
    CREATE INDEX IF NOT EXISTS idx_user_rooms_owner ON user_rooms(owner_user_id);
    CREATE INDEX IF NOT EXISTS idx_user_rooms_status ON user_rooms(status);
    CREATE INDEX IF NOT EXISTS idx_user_rooms_category ON user_rooms(category);
  `);

  const insertLevel = db.prepare(`
    INSERT INTO user_levels (level_number, title_ar, min_xp, max_rooms, max_mics, badge_color)
    VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(level_number) DO UPDATE SET
      title_ar = excluded.title_ar,
      min_xp = excluded.min_xp,
      max_rooms = excluded.max_rooms,
      max_mics = excluded.max_mics,
      badge_color = excluded.badge_color
  `);
  for (const lvl of DEFAULT_LEVELS) {
    insertLevel.run(lvl.level_number, lvl.title_ar, lvl.min_xp, lvl.max_rooms, lvl.max_mics, lvl.badge_color);
  }

  const insertPerm = db.prepare(`
    INSERT INTO permissions (code, label_ar, category)
    VALUES (?, ?, ?)
    ON CONFLICT(code) DO UPDATE SET
      label_ar = excluded.label_ar,
      category = excluded.category
  `);
  for (const perm of DEFAULT_PERMISSIONS) {
    insertPerm.run(perm.code, perm.label_ar, perm.category);
  }

  const insertRolePerm = db.prepare(`
    INSERT OR IGNORE INTO role_permissions (role, permission_code)
    VALUES (?, ?)
  `);
  for (const [role, permCode] of DEFAULT_ROLE_PERMISSIONS) {
    insertRolePerm.run(role, permCode);
  }

  return db;
}

export function upsertUser(db, data = {}) {
  const id = data.id || crypto.randomUUID();
  const now = new Date().toISOString();

  const existing = db.prepare('SELECT * FROM users WHERE id = ?').get(id);
  const level = data.level ?? existing?.level ?? 1;
  const xp = data.xp ?? existing?.xp ?? 0;

  db.prepare(`
    INSERT INTO users (
      id, username, display_name, email, phone, facebook_id, google_id, gmail_email,
      gender, country_code, country_name, level, xp, role, status, last_ip,
      created_at, updated_at, last_login_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      username = COALESCE(excluded.username, users.username),
      display_name = COALESCE(excluded.display_name, users.display_name),
      email = COALESCE(excluded.email, users.email),
      phone = COALESCE(excluded.phone, users.phone),
      facebook_id = COALESCE(excluded.facebook_id, users.facebook_id),
      google_id = COALESCE(excluded.google_id, users.google_id),
      gmail_email = COALESCE(excluded.gmail_email, users.gmail_email),
      gender = COALESCE(excluded.gender, users.gender),
      country_code = COALESCE(excluded.country_code, users.country_code),
      country_name = COALESCE(excluded.country_name, users.country_name),
      level = excluded.level,
      xp = excluded.xp,
      role = COALESCE(excluded.role, users.role),
      status = COALESCE(excluded.status, users.status),
      last_ip = COALESCE(excluded.last_ip, users.last_ip),
      updated_at = excluded.updated_at,
      last_login_at = COALESCE(excluded.last_login_at, users.last_login_at)
  `).run(
    id,
    data.username ?? null,
    data.display_name ?? null,
    data.email ?? null,
    data.phone ?? null,
    data.facebook_id ?? null,
    data.google_id ?? null,
    data.gmail_email ?? null,
    data.gender ?? existing?.gender ?? 'unspecified',
    data.country_code ?? null,
    data.country_name ?? null,
    level,
    xp,
    data.role ?? existing?.role ?? 'user',
    data.status ?? existing?.status ?? 'active',
    data.last_ip ?? null,
    existing?.created_at ?? now,
    now,
    data.last_login_at ?? existing?.last_login_at ?? null
  );

  const linkProvider = db.prepare(`
    INSERT INTO user_auth_providers (user_id, provider, provider_uid, provider_email, linked_at)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(provider, provider_uid) DO UPDATE SET
      user_id = excluded.user_id,
      provider_email = COALESCE(excluded.provider_email, user_auth_providers.provider_email)
  `);

  if (data.facebook_id) {
    linkProvider.run(id, 'facebook', String(data.facebook_id), data.email ?? null, now);
  }
  if (data.google_id) {
    linkProvider.run(id, 'google', String(data.google_id), data.gmail_email ?? data.email ?? null, now);
  }
  if (data.gmail_email && !data.google_id) {
    linkProvider.run(id, 'gmail', String(data.gmail_email), data.gmail_email, now);
  }
  if (data.phone) {
    linkProvider.run(id, 'phone', String(data.phone), null, now);
  }
  if (data.email) {
    linkProvider.run(id, 'email', String(data.email), data.email, now);
  }

  return getUserFullProfile(db, id);
}

export function getUserFullProfile(db, id) {
  const user = db.prepare(`
    SELECT u.*, l.title_ar AS level_title_ar, l.min_xp AS level_min_xp,
           l.max_rooms AS level_max_rooms, l.max_mics AS level_max_mics,
           l.badge_color AS level_badge_color
    FROM users u
    LEFT JOIN user_levels l ON l.level_number = u.level
    WHERE u.id = ?
  `).get(id);

  if (!user) return null;

  const rolePerms = db.prepare(`
    SELECT p.code, p.label_ar, p.category
    FROM role_permissions rp
    JOIN permissions p ON p.code = rp.permission_code
    WHERE rp.role = ?
  `).all(user.role);

  const customPerms = db.prepare(`
    SELECT up.permission_code AS code, p.label_ar, p.category, up.granted, up.granted_by, up.updated_at
    FROM user_permissions up
    JOIN permissions p ON p.code = up.permission_code
    WHERE up.user_id = ?
  `).all(id);

  const effectiveMap = new Map();
  for (const rp of rolePerms) {
    effectiveMap.set(rp.code, { ...rp, source: 'role', granted: true });
  }
  for (const cp of customPerms) {
    if (cp.granted) {
      effectiveMap.set(cp.code, { code: cp.code, label_ar: cp.label_ar, category: cp.category, source: 'user', granted: true });
    } else {
      effectiveMap.delete(cp.code);
    }
  }

  const authProviders = db.prepare(`
    SELECT id, provider, provider_uid, provider_email, linked_at
    FROM user_auth_providers
    WHERE user_id = ?
    ORDER BY linked_at DESC
  `).all(id);

  const ipLogs = db.prepare(`
    SELECT id, ip_address, country, user_agent, action, created_at
    FROM user_ip_logs
    WHERE user_id = ?
    ORDER BY created_at DESC, id DESC
    LIMIT 20
  `).all(id);

  const rooms = db.prepare(`
    SELECT room_id, owner_user_id, title_ar, category, room_level, mic_count, status, created_at, updated_at
    FROM user_rooms
    WHERE owner_user_id = ?
    ORDER BY created_at DESC
  `).all(id);

  return {
    ...user,
    permissions: Array.from(effectiveMap.values()),
    custom_permissions: customPerms,
    auth_providers: authProviders,
    ip_logs: ipLogs,
    rooms
  };
}

export function listUsers(db, filters = {}) {
  const conditions = [];
  const params = [];

  if (filters.role) {
    conditions.push('u.role = ?');
    params.push(filters.role);
  }
  if (filters.status) {
    conditions.push('u.status = ?');
    params.push(filters.status);
  }
  if (filters.level !== undefined && filters.level !== null) {
    conditions.push('u.level = ?');
    params.push(Number(filters.level));
  }
  if (filters.country_code) {
    conditions.push('u.country_code = ?');
    params.push(filters.country_code);
  }
  if (filters.search) {
    conditions.push('(u.username LIKE ? OR u.display_name LIKE ? OR u.email LIKE ? OR u.phone LIKE ?)');
    const q = `%${filters.search}%`;
    params.push(q, q, q, q);
  }

  const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const limit = Math.min(Math.max(Number(filters.limit) || 50, 1), 200);
  const offset = Math.max(Number(filters.offset) || 0, 0);

  const rows = db.prepare(`
    SELECT u.*, l.title_ar AS level_title_ar, l.badge_color AS level_badge_color
    FROM users u
    LEFT JOIN user_levels l ON l.level_number = u.level
    ${whereClause}
    ORDER BY u.created_at DESC
    LIMIT ? OFFSET ?
  `).all(...params, limit, offset);

  const totalRow = db.prepare(`
    SELECT COUNT(*) AS total FROM users u ${whereClause}
  `).get(...params);

  return {
    users: rows,
    total: totalRow?.total ?? 0,
    limit,
    offset
  };
}

export function updateUser(db, id, patch = {}) {
  const allowed = [
    'username', 'display_name', 'email', 'phone', 'facebook_id', 'google_id',
    'gmail_email', 'gender', 'country_code', 'country_name', 'level', 'xp',
    'role', 'status', 'last_ip', 'last_login_at'
  ];

  const sets = [];
  const params = [];
  for (const key of allowed) {
    if (Object.prototype.hasOwnProperty.call(patch, key)) {
      sets.push(`${key} = ?`);
      params.push(patch[key]);
    }
  }

  if (sets.length === 0) {
    return getUserFullProfile(db, id);
  }

  sets.push('updated_at = ?');
  params.push(new Date().toISOString(), id);

  db.prepare(`UPDATE users SET ${sets.join(', ')} WHERE id = ?`).run(...params);
  return getUserFullProfile(db, id);
}

export function setUserPermission(db, userId, code, granted = true, by = null) {
  const now = new Date().toISOString();
  db.prepare(`
    INSERT INTO user_permissions (user_id, permission_code, granted, granted_by, updated_at)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(user_id, permission_code) DO UPDATE SET
      granted = excluded.granted,
      granted_by = excluded.granted_by,
      updated_at = excluded.updated_at
  `).run(userId, code, granted ? 1 : 0, by, now);

  return db.prepare(`
    SELECT * FROM user_permissions WHERE user_id = ? AND permission_code = ?
  `).get(userId, code);
}

export function recordUserIp(db, userId, ip, action = 'login', ua = null, country = null) {
  const now = new Date().toISOString();
  const result = db.prepare(`
    INSERT INTO user_ip_logs (user_id, ip_address, country, user_agent, action, created_at)
    VALUES (?, ?, ?, ?, ?, ?)
  `).run(userId, ip, country, ua, action, now);

  db.prepare(`
    UPDATE users
    SET last_ip = ?,
        last_login_at = CASE WHEN ? = 'login' THEN ? ELSE last_login_at END,
        updated_at = ?
    WHERE id = ?
  `).run(ip, action, now, now, userId);

  return db.prepare('SELECT * FROM user_ip_logs WHERE id = ?').get(result.lastInsertRowid);
}

export function registerUserRoom(db, room) {
  const now = new Date().toISOString();
  const roomId = room.room_id || crypto.randomUUID();
  db.prepare(`
    INSERT INTO user_rooms (
      room_id, owner_user_id, title_ar, category, room_level, mic_count, status, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(room_id) DO UPDATE SET
      title_ar = excluded.title_ar,
      category = excluded.category,
      room_level = excluded.room_level,
      mic_count = excluded.mic_count,
      status = excluded.status,
      updated_at = excluded.updated_at
  `).run(
    roomId,
    room.owner_user_id,
    room.title_ar,
    room.category ?? 'general',
    room.room_level ?? 1,
    room.mic_count ?? 8,
    room.status ?? 'active',
    now,
    now
  );

  return db.prepare('SELECT * FROM user_rooms WHERE room_id = ?').get(roomId);
}

export function getLevelsAndPermissions(db) {
  const levels = db.prepare('SELECT * FROM user_levels ORDER BY level_number ASC').all();
  const permissions = db.prepare('SELECT * FROM permissions ORDER BY category ASC, code ASC').all();
  const rolePermissions = db.prepare('SELECT role, permission_code FROM role_permissions ORDER BY role ASC, permission_code ASC').all();

  return {
    levels,
    permissions,
    role_permissions: rolePermissions
  };
}
