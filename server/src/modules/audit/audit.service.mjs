import crypto from 'node:crypto';

const REDACTED_KEYS = new Set([
  'password',
  'passwordHash',
  'password_hash',
  'token',
  'accessToken',
  'refreshToken',
  'secret',
  'mfaSecret',
  'mfa_totp_secret',
  'authorization',
  'apiKey',
  'serverSecret',
]);

export function sanitizeAuditPayload(value) {
  if (value === null || value === undefined) return value;
  if (Array.isArray(value)) return value.map(sanitizeAuditPayload);
  if (typeof value === 'object') {
    const clean = {};
    for (const [k, v] of Object.entries(value)) {
      if (REDACTED_KEYS.has(k) || /secret|password|token|private_key/i.test(k)) {
        clean[k] = '[REDACTED]';
      } else {
        clean[k] = sanitizeAuditPayload(v);
      }
    }
    return clean;
  }
  return value;
}

/**
 * Append-only tamper-evident Audit & Security Event Logger.
 * Rejects any mutation or deletion attempt per Section 32 & 36.
 */
export class AuditService {
  constructor() {
    this._logs = [];
    this._securityEvents = [];
    this._lastHash = 'GENESIS';
  }

  record(entry) {
    const eventId = entry.eventId || `audit_${crypto.randomUUID()}`;
    const createdAt = new Date().toISOString();
    const recordBase = {
      eventId,
      actorId: entry.actorId ?? null,
      actorRole: entry.actorRole ?? null,
      action: String(entry.action || 'unknown'),
      permissionUsed: entry.permissionUsed ?? null,
      resourceType: entry.resourceType ?? null,
      targetId: entry.targetId ?? null,
      beforeValue: sanitizeAuditPayload(entry.beforeValue ?? null),
      afterValue: sanitizeAuditPayload(entry.afterValue ?? null),
      beforeVersion: entry.beforeVersion ?? null,
      afterVersion: entry.afterVersion ?? null,
      reason: entry.reason ?? null,
      sessionId: entry.sessionId ?? null,
      requestId: entry.requestId ?? crypto.randomUUID(),
      approvalId: entry.approvalId ?? null,
      result: entry.result || 'SUCCESS',
      prevHash: this._lastHash,
      createdAt,
    };
    const entryHash = crypto
      .createHash('sha256')
      .update(JSON.stringify(recordBase))
      .digest('hex');

    const frozen = Object.freeze({ ...recordBase, entryHash });
    this._logs.push(frozen);
    this._lastHash = entryHash;
    return frozen;
  }

  recordSecurityEvent({ severity = 'MEDIUM', eventType, actorId = null, ipAddress = null, details = {} }) {
    const event = Object.freeze({
      id: `sec_${crypto.randomUUID()}`,
      severity,
      eventType,
      actorId,
      ipAddress,
      details: sanitizeAuditPayload(details),
      resolved: false,
      createdAt: new Date().toISOString(),
    });
    this._securityEvents.push(event);
    return event;
  }

  listLogs({ limit = 100, offset = 0, actorId = null, action = null } = {}) {
    let items = this._logs;
    if (actorId) items = items.filter((e) => e.actorId === actorId);
    if (action) items = items.filter((e) => e.action === action);
    return items.slice().reverse().slice(offset, offset + limit);
  }

  listSecurityEvents({ limit = 100, severity = null } = {}) {
    let items = this._securityEvents;
    if (severity) items = items.filter((e) => e.severity === severity);
    return items.slice().reverse().slice(0, limit);
  }

  verifyChainIntegrity() {
    let prev = 'GENESIS';
    for (const item of this._logs) {
      if (item.prevHash !== prev) return false;
      const { entryHash, ...base } = item;
      const expected = crypto.createHash('sha256').update(JSON.stringify(base)).digest('hex');
      if (expected !== entryHash) return false;
      prev = entryHash;
    }
    return true;
  }

  deleteLog() {
    this.recordSecurityEvent({
      severity: 'CRITICAL',
      eventType: 'AUDIT_LOG_DELETE_ATTEMPT',
      details: { message: 'Blocked unauthorized attempt to delete audit logs' },
    });
    const err = new Error('AUDIT_LOG_IMMUTABLE: Audit logs cannot be modified or deleted');
    err.statusCode = 403;
    throw err;
  }

  updateLog() {
    const err = new Error('AUDIT_LOG_IMMUTABLE: Audit logs cannot be modified or deleted');
    err.statusCode = 403;
    throw err;
  }
}
