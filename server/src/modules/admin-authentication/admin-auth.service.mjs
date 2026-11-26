import crypto from 'node:crypto';

function createError(message, statusCode) {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
}

/**
 * Pure node:crypto RFC 6238 TOTP generator/verifier (30s window, 6 digits).
 */
export function generateTotpCode(secretHex, timestampMs = Date.now()) {
  const step = Math.floor(timestampMs / 30000);
  const buf = Buffer.alloc(8);
  buf.writeBigUInt64BE(BigInt(step));
  const hmac = crypto.createHmac('sha1', Buffer.from(secretHex, 'hex')).update(buf).digest();
  const offset = hmac[hmac.length - 1] & 0x0f;
  const code = ((hmac.readUInt32BE(offset) & 0x7fffffff) % 1000000).toString().padStart(6, '0');
  return code;
}

export function verifyTotpCode(secretHex, inputCode, timestampMs = Date.now()) {
  const clean = String(inputCode || '').trim();
  if (!/^\d{6}$/.test(clean)) return false;
  for (const drift of [-30000, 0, 30000]) {
    const expected = generateTotpCode(secretHex, timestampMs + drift);
    if (crypto.timingSafeEqual(Buffer.from(clean), Buffer.from(expected))) {
      return true;
    }
  }
  return false;
}

export function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const derived = crypto.scryptSync(String(password), salt, 64).toString('hex');
  return `scrypt$${salt}$${derived}`;
}

export function verifyPassword(password, storedHash) {
  const parts = String(storedHash || '').split('$');
  if (parts.length !== 3 || parts[0] !== 'scrypt') return false;
  const [, salt, expectedHex] = parts;
  const derived = crypto.scryptSync(String(password), salt, 64);
  const expected = Buffer.from(expectedHex, 'hex');
  if (derived.length !== expected.length) return false;
  return crypto.timingSafeEqual(derived, expected);
}

/**
 * Independent Admin Authentication & Session Service (Sections 3, 26, 27)
 * - Strictly separate from normal user sessions
 * - Short-lived access tokens + refresh token rotation
 * - Instant server-side session revocation & permission epoch invalidation
 * - Brute-force lockout & TOTP MFA verification
 */
export class AdminAuthService {
  constructor({ tokenSecret, auditService }) {
    this.tokenSecret = tokenSecret || process.env.HALAA_ADMIN_TOKEN_SECRET || crypto.randomBytes(32).toString('hex');
    this.auditService = auditService;
    this.admins = new Map();       // adminId -> adminAccount
    this.byUsername = new Map();   // lowercase username -> adminId
    this.sessions = new Map();     // sessionId -> sessionRecord
    this.accessTtlMs = 15 * 60 * 1000;
    this.refreshTtlMs = 7 * 24 * 60 * 60 * 1000;
    this.maxFailedAttempts = 5;
    this.lockoutMs = 15 * 60 * 1000;
  }

  registerAdmin({ id, username, password, isSuperOwner = false, mfaSecret = null }) {
    const key = String(username).trim().toLowerCase();
    if (this.byUsername.has(key)) {
      throw createError('Admin username already exists', 409);
    }
    const admin = {
      id: id || `admin_${crypto.randomUUID()}`,
      username: String(username).trim(),
      passwordHash: hashPassword(password),
      isAdmin: true,
      isSuperOwner: Boolean(isSuperOwner),
      isActive: true,
      permissionEpoch: 1,
      mfaEnabled: true,
      mfaSecret: mfaSecret || crypto.randomBytes(20).toString('hex'),
      failedAttempts: 0,
      lockedUntil: null,
      createdAt: new Date().toISOString(),
    };
    this.admins.set(admin.id, admin);
    this.byUsername.set(key, admin.id);
    return admin;
  }

  _signToken(payload) {
    const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
    const sig = crypto.createHmac('sha256', this.tokenSecret).update(body).digest('base64url');
    return `${body}.${sig}`;
  }

  _verifyToken(token) {
    const parts = String(token || '').split('.');
    if (parts.length !== 2) throw createError('UNAUTHORIZED: Malformed token', 401);
    const [body, sig] = parts;
    const expected = crypto.createHmac('sha256', this.tokenSecret).update(body).digest('base64url');
    if (sig.length !== expected.length || !crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected))) {
      throw createError('UNAUTHORIZED: Invalid token signature', 401);
    }
    const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
    if (payload.exp && Date.now() > payload.exp) {
      throw createError('UNAUTHORIZED: Token expired', 401);
    }
    return payload;
  }

  login({ username, password, totpCode = null, ipAddress = null, deviceName = 'unknown' }) {
    const key = String(username || '').trim().toLowerCase();
    const adminId = this.byUsername.get(key);
    const admin = adminId ? this.admins.get(adminId) : null;

    if (!admin || !admin.isActive) {
      this.auditService.recordSecurityEvent({
        severity: 'MEDIUM',
        eventType: 'ADMIN_LOGIN_FAILED',
        ipAddress,
        details: { username: key },
      });
      throw createError('UNAUTHORIZED: Invalid administrative credentials', 401);
    }

    if (admin.lockedUntil && Date.now() < admin.lockedUntil) {
      throw createError('TOO_MANY_REQUESTS: Admin account temporarily locked due to failed attempts', 429);
    }

    if (!verifyPassword(password, admin.passwordHash)) {
      admin.failedAttempts += 1;
      if (admin.failedAttempts >= this.maxFailedAttempts) {
        admin.lockedUntil = Date.now() + this.lockoutMs;
      }
      this.auditService.recordSecurityEvent({
        severity: 'HIGH',
        eventType: 'ADMIN_BAD_PASSWORD',
        actorId: admin.id,
        ipAddress,
        details: { failedAttempts: admin.failedAttempts },
      });
      throw createError('UNAUTHORIZED: Invalid administrative credentials', 401);
    }

    let mfaVerified = false;
    if (admin.mfaEnabled) {
      if (!totpCode || !verifyTotpCode(admin.mfaSecret, totpCode)) {
        throw createError('UNAUTHORIZED: Valid MFA TOTP code is required', 401);
      }
      mfaVerified = true;
    }

    admin.failedAttempts = 0;
    admin.lockedUntil = null;

    const sessionId = `sess_${crypto.randomUUID()}`;
    const refreshToken = crypto.randomBytes(32).toString('hex');
    const refreshTokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');

    const session = {
      id: sessionId,
      adminId: admin.id,
      permissionEpoch: admin.permissionEpoch,
      mfaVerified,
      mfaVerifiedAt: mfaVerified ? Date.now() : null,
      refreshTokenHash,
      deviceName,
      ipAddress,
      revokedAt: null,
      revokeReason: null,
      expiresAt: Date.now() + this.refreshTtlMs,
      createdAt: new Date().toISOString(),
    };
    this.sessions.set(sessionId, session);

    const accessToken = this._signToken({
      sid: sessionId,
      sub: admin.id,
      type: 'ADMIN_ACCESS',
      exp: Date.now() + this.accessTtlMs,
    });

    this.auditService.record({
      actorId: admin.id,
      actorRole: admin.isSuperOwner ? 'SUPER_OWNER' : 'ADMIN',
      action: 'admin.auth.login',
      sessionId,
      result: 'SUCCESS',
    });

    return { accessToken, refreshToken, sessionId, admin: this.toPublicAdmin(admin) };
  }

  validateAccessToken(accessToken) {
    const payload = this._verifyToken(accessToken);
    if (payload.type !== 'ADMIN_ACCESS') {
      throw createError('FORBIDDEN: Non-admin token rejected on admin endpoint', 403);
    }
    const session = this.sessions.get(payload.sid);
    if (!session || session.revokedAt || Date.now() > session.expiresAt) {
      throw createError('UNAUTHORIZED: Admin session has been revoked or expired', 401);
    }
    const admin = this.admins.get(session.adminId);
    if (!admin || !admin.isActive) {
      throw createError('FORBIDDEN: Admin account is inactive', 403);
    }
    if (session.permissionEpoch !== admin.permissionEpoch) {
      throw createError('UNAUTHORIZED: Privileges changed; re-authentication required', 401);
    }
    return {
      actor: admin,
      session: { ...session, valid: true },
    };
  }

  rotateRefreshToken(sessionId, refreshToken) {
    const session = this.sessions.get(sessionId);
    if (!session || session.revokedAt || Date.now() > session.expiresAt) {
      throw createError('UNAUTHORIZED: Session invalid or revoked', 401);
    }
    const incomingHash = crypto.createHash('sha256').update(String(refreshToken || '')).digest('hex');
    if (incomingHash !== session.refreshTokenHash) {
      // Possible replay attack -> revoke entire session immediately
      this.revokeSession(sessionId, 'REFRESH_TOKEN_REUSE_DETECTED');
      throw createError('UNAUTHORIZED: Refresh token reuse detected; session revoked', 401);
    }
    const nextRefresh = crypto.randomBytes(32).toString('hex');
    session.refreshTokenHash = crypto.createHash('sha256').update(nextRefresh).digest('hex');
    const accessToken = this._signToken({
      sid: session.id,
      sub: session.adminId,
      type: 'ADMIN_ACCESS',
      exp: Date.now() + this.accessTtlMs,
    });
    return { accessToken, refreshToken: nextRefresh };
  }

  revokeSession(sessionId, reason = 'ADMIN_REVOKED') {
    const session = this.sessions.get(sessionId);
    if (!session) return false;
    session.revokedAt = new Date().toISOString();
    session.revokeReason = reason;
    this.auditService.record({
      actorId: session.adminId,
      action: 'admin.session.revoked',
      sessionId,
      reason,
      result: 'SUCCESS',
    });
    return true;
  }

  bumpPermissionEpoch(adminId) {
    const admin = this.admins.get(adminId);
    if (!admin) return;
    admin.permissionEpoch += 1;
  }

  toPublicAdmin(admin) {
    return {
      id: admin.id,
      username: admin.username,
      isSuperOwner: admin.isSuperOwner,
      isActive: admin.isActive,
      mfaEnabled: admin.mfaEnabled,
      permissionEpoch: admin.permissionEpoch,
    };
  }
}
