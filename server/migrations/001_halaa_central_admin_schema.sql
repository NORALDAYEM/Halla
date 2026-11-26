-- ============================================================================
-- Halaa Central Administration & Security System — Stage 2 Database Schema
-- Compatible with PostgreSQL 15+ (Supabase / Render Postgres)
-- Covers all 27 tables specified in Section 28 of the Engineering Specification
-- Non-destructive: uses CREATE TABLE IF NOT EXISTS to preserve existing tables
-- ============================================================================

BEGIN;

-- 1. users (core user accounts — preserves existing structure if already present)
CREATE TABLE IF NOT EXISTS users (
  id                TEXT PRIMARY KEY,
  username          TEXT UNIQUE,
  email             TEXT UNIQUE,
  phone             TEXT,
  country_code      TEXT,
  level             INTEGER NOT NULL DEFAULT 1,
  vip_tier          TEXT NOT NULL DEFAULT 'NONE',
  agency_id         TEXT,
  status            TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','BANNED','FROZEN')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. admin_accounts (strictly separated from normal user accounts)
CREATE TABLE IF NOT EXISTS admin_accounts (
  id                TEXT PRIMARY KEY,
  user_id           TEXT UNIQUE REFERENCES users(id) ON DELETE RESTRICT,
  admin_username    TEXT NOT NULL UNIQUE,
  password_hash     TEXT NOT NULL,
  is_super_owner    BOOLEAN NOT NULL DEFAULT FALSE,
  mfa_enabled       BOOLEAN NOT NULL DEFAULT TRUE,
  mfa_totp_secret   TEXT,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  permission_epoch  BIGINT NOT NULL DEFAULT 1,
  failed_attempts   INTEGER NOT NULL DEFAULT 0,
  locked_until      TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enforce single SUPER_OWNER protection at DB level
CREATE UNIQUE INDEX IF NOT EXISTS idx_single_super_owner
  ON admin_accounts (is_super_owner) WHERE is_super_owner = TRUE;

-- 3. roles
CREATE TABLE IF NOT EXISTS roles (
  id                TEXT PRIMARY KEY,
  code              TEXT NOT NULL UNIQUE,
  name_ar           TEXT NOT NULL,
  name_en           TEXT NOT NULL,
  category          TEXT NOT NULL CHECK (category IN ('ADMIN','AGENCY','ROOM','USER')),
  priority          INTEGER NOT NULL DEFAULT 100,
  is_system         BOOLEAN NOT NULL DEFAULT FALSE,
  is_protected      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. permissions
CREATE TABLE IF NOT EXISTS permissions (
  id                TEXT PRIMARY KEY,
  code              TEXT NOT NULL UNIQUE,
  name_ar           TEXT NOT NULL,
  description_ar    TEXT NOT NULL,
  module            TEXT NOT NULL,
  risk_level        INTEGER NOT NULL CHECK (risk_level BETWEEN 1 AND 5),
  requires_mfa      BOOLEAN NOT NULL DEFAULT FALSE,
  requires_approval BOOLEAN NOT NULL DEFAULT FALSE,
  requires_reason   BOOLEAN NOT NULL DEFAULT FALSE,
  mobile_executable BOOLEAN NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. role_permissions
CREATE TABLE IF NOT EXISTS role_permissions (
  id                TEXT PRIMARY KEY,
  role_id           TEXT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_code   TEXT NOT NULL REFERENCES permissions(code) ON DELETE CASCADE,
  effect            TEXT NOT NULL DEFAULT 'ALLOW' CHECK (effect IN ('ALLOW','DENY')),
  can_delegate      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (role_id, permission_code)
);

-- 6. user_roles
CREATE TABLE IF NOT EXISTS user_roles (
  id                TEXT PRIMARY KEY,
  user_id           TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id           TEXT NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
  scope_type        TEXT NOT NULL DEFAULT 'GLOBAL' CHECK (scope_type IN ('GLOBAL','COUNTRY','AGENCY','ROOM','USER')),
  scope_resource_id TEXT,
  granted_by        TEXT REFERENCES admin_accounts(id),
  starts_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at        TIMESTAMPTZ,
  revoked_at        TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_user_roles_user ON user_roles (user_id) WHERE revoked_at IS NULL;

-- 7. user_permissions (direct overrides — DENY overrides ALLOW)
CREATE TABLE IF NOT EXISTS user_permissions (
  id                TEXT PRIMARY KEY,
  user_id           TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission_code   TEXT NOT NULL REFERENCES permissions(code) ON DELETE CASCADE,
  effect            TEXT NOT NULL CHECK (effect IN ('ALLOW','DENY')),
  scope_type        TEXT NOT NULL DEFAULT 'GLOBAL' CHECK (scope_type IN ('GLOBAL','COUNTRY','AGENCY','ROOM','USER')),
  scope_resource_id TEXT,
  starts_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at        TIMESTAMPTZ,
  granted_by        TEXT REFERENCES admin_accounts(id),
  reason            TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_user_permissions_user ON user_permissions (user_id, permission_code);

-- 8. permission_scopes
CREATE TABLE IF NOT EXISTS permission_scopes (
  id                TEXT PRIMARY KEY,
  grant_type        TEXT NOT NULL CHECK (grant_type IN ('ROLE','USER','DELEGATION')),
  grant_id          TEXT NOT NULL,
  scope_type        TEXT NOT NULL CHECK (scope_type IN ('GLOBAL','COUNTRY','AGENCY','ROOM','USER','GAME')),
  resource_id       TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. permission_conditions (ABAC constraints: financial limits, op limits, MFA, reason)
CREATE TABLE IF NOT EXISTS permission_conditions (
  id                       TEXT PRIMARY KEY,
  grant_type               TEXT NOT NULL CHECK (grant_type IN ('ROLE','USER','DELEGATION')),
  grant_id                 TEXT NOT NULL,
  max_amount_per_operation NUMERIC(18,2),
  max_amount_per_day       NUMERIC(18,2),
  max_ops_per_day          INTEGER,
  require_reason           BOOLEAN NOT NULL DEFAULT FALSE,
  require_mfa              BOOLEAN NOT NULL DEFAULT FALSE,
  require_approval         BOOLEAN NOT NULL DEFAULT FALSE,
  min_approvers            INTEGER NOT NULL DEFAULT 1,
  prevent_self_approval    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. permission_delegations (temporary delegated authority)
CREATE TABLE IF NOT EXISTS permission_delegations (
  id                TEXT PRIMARY KEY,
  delegator_id      TEXT NOT NULL REFERENCES admin_accounts(id),
  delegatee_id      TEXT NOT NULL REFERENCES admin_accounts(id),
  permission_code   TEXT NOT NULL REFERENCES permissions(code),
  scope_type        TEXT NOT NULL DEFAULT 'GLOBAL',
  scope_resource_id TEXT,
  starts_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at        TIMESTAMPTZ NOT NULL,
  revoked_at        TIMESTAMPTZ,
  reason            TEXT NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. security_policies
CREATE TABLE IF NOT EXISTS security_policies (
  id                TEXT PRIMARY KEY,
  policy_key        TEXT NOT NULL UNIQUE,
  policy_value      JSONB NOT NULL,
  is_immutable      BOOLEAN NOT NULL DEFAULT FALSE,
  version           INTEGER NOT NULL DEFAULT 1,
  updated_by        TEXT REFERENCES admin_accounts(id),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. trusted_devices
CREATE TABLE IF NOT EXISTS trusted_devices (
  id                TEXT PRIMARY KEY,
  admin_account_id  TEXT NOT NULL REFERENCES admin_accounts(id) ON DELETE CASCADE,
  device_fingerprint TEXT NOT NULL,
  device_name       TEXT,
  platform          TEXT,
  is_trusted        BOOLEAN NOT NULL DEFAULT TRUE,
  revoked_at        TIMESTAMPTZ,
  last_seen_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (admin_account_id, device_fingerprint)
);

-- 13. admin_sessions (independent from user sessions; instant revocation)
CREATE TABLE IF NOT EXISTS admin_sessions (
  id                TEXT PRIMARY KEY,
  admin_account_id  TEXT NOT NULL REFERENCES admin_accounts(id) ON DELETE CASCADE,
  device_id         TEXT REFERENCES trusted_devices(id),
  refresh_token_hash TEXT NOT NULL,
  permission_epoch  BIGINT NOT NULL,
  mfa_verified_at   TIMESTAMPTZ,
  ip_address        TEXT,
  user_agent        TEXT,
  expires_at        TIMESTAMPTZ NOT NULL,
  revoked_at        TIMESTAMPTZ,
  revoke_reason     TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_active ON admin_sessions (admin_account_id) WHERE revoked_at IS NULL;

-- 14. approval_requests
CREATE TABLE IF NOT EXISTS approval_requests (
  id                TEXT PRIMARY KEY,
  requester_id      TEXT NOT NULL REFERENCES admin_accounts(id),
  action_code       TEXT NOT NULL,
  resource_type     TEXT NOT NULL,
  resource_id       TEXT,
  payload           JSONB NOT NULL,
  payload_hash      TEXT NOT NULL,
  reason            TEXT NOT NULL,
  status            TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','APPROVED','REJECTED','EXPIRED','EXECUTED','CANCELLED')),
  required_approvers INTEGER NOT NULL DEFAULT 1,
  expires_at        TIMESTAMPTZ NOT NULL,
  executed_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 15. approval_actions
CREATE TABLE IF NOT EXISTS approval_actions (
  id                TEXT PRIMARY KEY,
  request_id        TEXT NOT NULL REFERENCES approval_requests(id) ON DELETE CASCADE,
  approver_id       TEXT NOT NULL REFERENCES admin_accounts(id),
  decision          TEXT NOT NULL CHECK (decision IN ('APPROVE','REJECT')),
  comment           TEXT,
  mfa_verified      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (request_id, approver_id)
);

-- 16. app_configurations
CREATE TABLE IF NOT EXISTS app_configurations (
  config_key        TEXT PRIMARY KEY,
  current_version   BIGINT NOT NULL DEFAULT 1,
  config_value      JSONB NOT NULL,
  updated_by        TEXT REFERENCES admin_accounts(id),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 17. configuration_versions
CREATE TABLE IF NOT EXISTS configuration_versions (
  id                TEXT PRIMARY KEY,
  config_key        TEXT NOT NULL REFERENCES app_configurations(config_key) ON DELETE CASCADE,
  version           BIGINT NOT NULL,
  config_value      JSONB NOT NULL,
  change_reason     TEXT,
  rolled_back_from  BIGINT,
  created_by        TEXT REFERENCES admin_accounts(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (config_key, version)
);

-- 18. themes
CREATE TABLE IF NOT EXISTS themes (
  id                TEXT PRIMARY KEY,
  name              TEXT NOT NULL,
  status            TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','PREVIEW','SCHEDULED','PUBLISHED','ARCHIVED','ROLLED_BACK')),
  current_version   BIGINT NOT NULL DEFAULT 1,
  scheduled_at      TIMESTAMPTZ,
  target_scope      JSONB NOT NULL DEFAULT '{"type":"GLOBAL"}'::jsonb,
  created_by        TEXT REFERENCES admin_accounts(id),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 19. theme_versions
CREATE TABLE IF NOT EXISTS theme_versions (
  id                TEXT PRIMARY KEY,
  theme_id          TEXT NOT NULL REFERENCES themes(id) ON DELETE CASCADE,
  version           BIGINT NOT NULL,
  theme_payload     JSONB NOT NULL,
  status            TEXT NOT NULL CHECK (status IN ('DRAFT','PREVIEW','SCHEDULED','PUBLISHED','ARCHIVED','ROLLED_BACK')),
  rolled_back_from  BIGINT,
  created_by        TEXT REFERENCES admin_accounts(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (theme_id, version)
);

-- 20. feature_flags
CREATE TABLE IF NOT EXISTS feature_flags (
  feature_key       TEXT PRIMARY KEY,
  enabled           BOOLEAN NOT NULL DEFAULT TRUE,
  targeting_rules   JSONB NOT NULL DEFAULT '{"scope":"GLOBAL"}'::jsonb,
  version           BIGINT NOT NULL DEFAULT 1,
  updated_by        TEXT REFERENCES admin_accounts(id),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 21. sync_events
CREATE TABLE IF NOT EXISTS sync_events (
  event_id          TEXT PRIMARY KEY,
  event_type        TEXT NOT NULL,
  resource_id       TEXT,
  version           BIGINT NOT NULL,
  scope             TEXT NOT NULL DEFAULT 'GLOBAL',
  target_id         TEXT,
  refresh_required  BOOLEAN NOT NULL DEFAULT TRUE,
  payload           JSONB,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sync_events_version ON sync_events (version DESC);

-- 22. sync_acknowledgments
CREATE TABLE IF NOT EXISTS sync_acknowledgments (
  id                TEXT PRIMARY KEY,
  event_id          TEXT NOT NULL REFERENCES sync_events(event_id) ON DELETE CASCADE,
  device_id         TEXT NOT NULL,
  app_type          TEXT NOT NULL CHECK (app_type IN ('USER_APP','ADMIN_APP')),
  applied_version   BIGINT NOT NULL,
  status            TEXT NOT NULL CHECK (status IN ('ACK','FAILED')),
  error_message     TEXT,
  acknowledged_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (event_id, device_id)
);

-- 23. event_outbox (transactional outbox for guaranteed delivery)
CREATE TABLE IF NOT EXISTS event_outbox (
  id                TEXT PRIMARY KEY,
  event_id          TEXT NOT NULL REFERENCES sync_events(event_id) ON DELETE CASCADE,
  published         BOOLEAN NOT NULL DEFAULT FALSE,
  attempts          INTEGER NOT NULL DEFAULT 0,
  last_error        TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  published_at      TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_event_outbox_pending ON event_outbox (created_at) WHERE published = FALSE;

-- 24. financial_ledger (Double-Entry immutable ledger with idempotency)
CREATE TABLE IF NOT EXISTS financial_ledger (
  id                TEXT PRIMARY KEY,
  transaction_group TEXT NOT NULL,
  idempotency_key   TEXT NOT NULL,
  account_id        TEXT NOT NULL,
  currency          TEXT NOT NULL CHECK (currency IN ('COINS','CRYSTALS','USD')),
  entry_type        TEXT NOT NULL CHECK (entry_type IN ('DEBIT','CREDIT')),
  amount            NUMERIC(18,2) NOT NULL CHECK (amount > 0),
  reason            TEXT NOT NULL,
  actor_admin_id    TEXT REFERENCES admin_accounts(id),
  approval_id       TEXT REFERENCES approval_requests(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (idempotency_key, entry_type, account_id)
);
CREATE INDEX IF NOT EXISTS idx_ledger_account_currency ON financial_ledger (account_id, currency);

-- 25. audit_logs (append-only tamper-evident log)
CREATE TABLE IF NOT EXISTS audit_logs (
  event_id          TEXT PRIMARY KEY,
  actor_id          TEXT,
  actor_role        TEXT,
  action            TEXT NOT NULL,
  permission_used   TEXT,
  resource_type     TEXT,
  target_id         TEXT,
  before_value      JSONB,
  after_value       JSONB,
  before_version    BIGINT,
  after_version     BIGINT,
  reason            TEXT,
  session_id        TEXT,
  request_id        TEXT,
  approval_id       TEXT,
  result            TEXT NOT NULL CHECK (result IN ('SUCCESS','DENIED','FAILED')),
  prev_hash         TEXT NOT NULL,
  entry_hash        TEXT NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs (created_at DESC);

-- 26. security_events
CREATE TABLE IF NOT EXISTS security_events (
  id                TEXT PRIMARY KEY,
  severity          TEXT NOT NULL CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
  event_type        TEXT NOT NULL,
  actor_id          TEXT,
  ip_address        TEXT,
  details           JSONB NOT NULL,
  resolved          BOOLEAN NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 27. emergency_actions
CREATE TABLE IF NOT EXISTS emergency_actions (
  id                TEXT PRIMARY KEY,
  action_key        TEXT NOT NULL,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  scope             TEXT NOT NULL DEFAULT 'GLOBAL',
  reason            TEXT NOT NULL,
  activated_by      TEXT NOT NULL REFERENCES admin_accounts(id),
  expires_at        TIMESTAMPTZ,
  deactivated_by    TEXT REFERENCES admin_accounts(id),
  deactivated_at    TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- IMMUTABILITY TRIGGERS (Audit Logs & SUPER_OWNER Protection)
-- ============================================================================

CREATE OR REPLACE FUNCTION prevent_audit_log_mutation()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'audit_logs is append-only and cannot be modified or deleted';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_logs_no_update ON audit_logs;
CREATE TRIGGER trg_audit_logs_no_update
  BEFORE UPDATE OR DELETE ON audit_logs
  FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_mutation();

CREATE OR REPLACE FUNCTION prevent_super_owner_deletion()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.is_super_owner = TRUE THEN
    RAISE EXCEPTION 'SUPER_OWNER account cannot be deleted';
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_super_owner_no_delete ON admin_accounts;
CREATE TRIGGER trg_super_owner_no_delete
  BEFORE DELETE ON admin_accounts
  FOR EACH ROW EXECUTE FUNCTION prevent_super_owner_deletion();

COMMIT;
