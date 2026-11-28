-- Halla Relational Users Database Schema (PostgreSQL / Supabase)
-- Matches server/src/users-db.mjs 100%

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
  permission_code TEXT NOT NULL REFERENCES permissions(code) ON DELETE CASCADE,
  PRIMARY KEY (role, permission_code)
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
  level INTEGER NOT NULL DEFAULT 1 REFERENCES user_levels(level_number) ON UPDATE CASCADE,
  xp INTEGER NOT NULL DEFAULT 0,
  role TEXT NOT NULL DEFAULT 'user',
  status TEXT NOT NULL DEFAULT 'active',
  last_ip TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS user_permissions (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission_code TEXT NOT NULL REFERENCES permissions(code) ON DELETE CASCADE,
  granted BOOLEAN NOT NULL DEFAULT TRUE,
  granted_by TEXT REFERENCES users(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, permission_code)
);

CREATE TABLE IF NOT EXISTS user_auth_providers (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  provider_uid TEXT NOT NULL,
  provider_email TEXT,
  linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (provider, provider_uid)
);

CREATE TABLE IF NOT EXISTS user_ip_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  ip_address TEXT NOT NULL,
  country TEXT,
  user_agent TEXT,
  action TEXT NOT NULL DEFAULT 'login',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_rooms (
  room_id TEXT PRIMARY KEY,
  owner_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title_ar TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'general',
  room_level INTEGER NOT NULL DEFAULT 1,
  mic_count INTEGER NOT NULL DEFAULT 8,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
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

-- Seed 10 Default Arabic Levels
INSERT INTO user_levels (level_number, title_ar, min_xp, max_rooms, max_mics, badge_color) VALUES
  (1, 'مبتدئ', 0, 1, 6, '#94A3B8'),
  (2, 'متفاعل', 100, 2, 8, '#60A5FA'),
  (3, 'نشيط', 350, 3, 8, '#34D399'),
  (4, 'متألق', 800, 4, 10, '#A78BFA'),
  (5, 'نجم الغرفة', 1500, 5, 12, '#FBBF24'),
  (6, 'مضيف محترف', 3000, 7, 12, '#F97316'),
  (7, 'سفير هلا', 6000, 10, 16, '#EC4899'),
  (8, 'قائد مجتمع', 12000, 15, 16, '#8B5CF6'),
  (9, 'نخبة هلا', 25000, 20, 20, '#EF4444'),
  (10, 'أسطورة هلا', 50000, 30, 24, '#EAB308')
ON CONFLICT (level_number) DO UPDATE SET
  title_ar = EXCLUDED.title_ar,
  min_xp = EXCLUDED.min_xp,
  max_rooms = EXCLUDED.max_rooms,
  max_mics = EXCLUDED.max_mics,
  badge_color = EXCLUDED.badge_color;

-- Seed Permissions
INSERT INTO permissions (code, label_ar, category) VALUES
  ('room.create', 'إنشاء غرفة صوتية', 'rooms'),
  ('room.manage', 'إدارة إعدادات الغرفة', 'rooms'),
  ('room.mic_control', 'التحكم بالمايكات', 'rooms'),
  ('room.kick_user', 'طرد مستخدم من الغرفة', 'moderation'),
  ('room.mute_user', 'كتم مستخدم', 'moderation'),
  ('gift.send', 'إرسال الهدايا', 'gifts'),
  ('user.view_profiles', 'عرض ملفات المستخدمين', 'users'),
  ('user.ban', 'حظر المستخدمين', 'admin'),
  ('user.manage_roles', 'إدارة الأدوار والصلاحيات', 'admin'),
  ('admin.dashboard', 'الوصول للوحة التحكم', 'admin')
ON CONFLICT (code) DO UPDATE SET
  label_ar = EXCLUDED.label_ar,
  category = EXCLUDED.category;

-- Seed Role Permissions
INSERT INTO role_permissions (role, permission_code) VALUES
  ('user', 'room.create'),
  ('user', 'gift.send'),
  ('user', 'user.view_profiles'),
  ('vip', 'room.create'),
  ('vip', 'room.manage'),
  ('vip', 'gift.send'),
  ('vip', 'user.view_profiles'),
  ('moderator', 'room.create'),
  ('moderator', 'room.manage'),
  ('moderator', 'room.mic_control'),
  ('moderator', 'room.kick_user'),
  ('moderator', 'room.mute_user'),
  ('moderator', 'gift.send'),
  ('moderator', 'user.view_profiles'),
  ('admin', 'room.create'),
  ('admin', 'room.manage'),
  ('admin', 'room.mic_control'),
  ('admin', 'room.kick_user'),
  ('admin', 'room.mute_user'),
  ('admin', 'gift.send'),
  ('admin', 'user.view_profiles'),
  ('admin', 'user.ban'),
  ('admin', 'admin.dashboard'),
  ('super_admin', 'room.create'),
  ('super_admin', 'room.manage'),
  ('super_admin', 'room.mic_control'),
  ('super_admin', 'room.kick_user'),
  ('super_admin', 'room.mute_user'),
  ('super_admin', 'gift.send'),
  ('super_admin', 'user.view_profiles'),
  ('super_admin', 'user.ban'),
  ('super_admin', 'user.manage_roles'),
  ('super_admin', 'admin.dashboard')
ON CONFLICT (role, permission_code) DO NOTHING;
