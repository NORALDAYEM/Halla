import { AuditService } from './modules/audit/audit.service.mjs';
import { AccessControlService, INITIAL_ROLES, INITIAL_PERMISSIONS } from './modules/access-control/access-control.service.mjs';
import { AdminAuthService } from './modules/admin-authentication/admin-auth.service.mjs';
import { ApprovalService } from './modules/approvals/approval.service.mjs';
import { FinancialLedgerService } from './modules/finance/ledger.service.mjs';
import { CentralControlSyncService } from './modules/remote-config/config-theme-sync.service.mjs';

function sendJson(res, statusCode, body) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
  });
  res.end(JSON.stringify(body));
}

async function readJsonBody(req, maxBytes = 256 * 1024) {
  let total = 0;
  const chunks = [];
  for await (const chunk of req) {
    total += chunk.length;
    if (total > maxBytes) {
      const err = new Error('PAYLOAD_TOO_LARGE');
      err.statusCode = 413;
      throw err;
    }
    chunks.push(chunk);
  }
  const raw = Buffer.concat(chunks).toString('utf8').trim();
  if (!raw) return {};
  try {
    return JSON.parse(raw);
  } catch {
    const err = new Error('BAD_REQUEST: Invalid JSON body');
    err.statusCode = 400;
    throw err;
  }
}

/**
 * Factory creating the complete Halaa Central Administration & Security System
 * plus a drop-in HTTP request handler for Node.js http.Server (server/app.mjs).
 */
export function createCentralAdminSystem(options = {}) {
  const auditService = new AuditService();
  const accessControl = new AccessControlService({ auditService });
  const adminAuth = new AdminAuthService({ tokenSecret: options.tokenSecret, auditService });
  const approvalService = new ApprovalService({ auditService });
  const ledgerService = new FinancialLedgerService({ accessControl, approvalService, auditService, storage: options.ledgerStorage });
  const controlSync = new CentralControlSyncService({ accessControl, auditService });

  // Bootstrap SUPER_OWNER from environment variables only (never hardcoded)
  const ownerUser = options.superOwnerUser || process.env.HALAA_SUPER_OWNER_USER;
  const ownerPass = options.superOwnerPass || process.env.HALAA_SUPER_OWNER_PASS;
  let superOwner = null;
  if (ownerUser && ownerPass) {
    superOwner = adminAuth.registerAdmin({
      id: 'super_owner_root',
      username: ownerUser,
      password: ownerPass,
      isSuperOwner: true,
      mfaSecret: options.superOwnerMfaSecret || process.env.HALAA_SUPER_OWNER_MFA_SECRET || undefined,
    });
  }

  // Simple sliding-window rate limiter per IP for /api/v1/admin/* & /api/v1/auth/admin/*
  const rateBuckets = new Map();
  function checkRateLimit(ip, limit = 120, windowMs = 60_000) {
    const now = Date.now();
    const bucket = rateBuckets.get(ip) || [];
    const recent = bucket.filter((t) => now - t < windowMs);
    if (recent.length >= limit) {
      const err = new Error('TOO_MANY_REQUESTS: Rate limit exceeded');
      err.statusCode = 429;
      throw err;
    }
    recent.push(now);
    rateBuckets.set(ip, recent);
  }

  function authenticateAdminRequest(req) {
    const authHeader = String(req.headers.authorization || '');
    if (!authHeader.startsWith('Bearer ')) {
      const err = new Error('UNAUTHORIZED: Missing Bearer admin token');
      err.statusCode = 401;
      throw err;
    }
    const token = authHeader.slice(7).trim();
    return adminAuth.validateAccessToken(token);
  }

  /**
   * Drop-in HTTP handler: returns true if the route was handled, false otherwise
   * so existing routes in server/app.mjs continue working untouched.
   */
  async function handleRequest(req, res) {
    const url = new URL(req.url || '/', 'http://localhost');
    const pathname = url.pathname;
    const method = (req.method || 'GET').toUpperCase();

    if (
      !pathname.startsWith('/api/v1/admin/') &&
      !pathname.startsWith('/api/v1/app/') &&
      !pathname.startsWith('/api/v1/auth/admin/') &&
      !pathname.startsWith('/api/v1/sync/') &&
      !pathname.startsWith('/api/v1/security/')
    ) {
      return false;
    }

    const ip = req.socket?.remoteAddress || 'unknown';
    try {
      checkRateLimit(ip);

      // -------------------- Public / User App Read Endpoints --------------------
      if (method === 'GET' && pathname === '/api/v1/app/bootstrap') {
        const config = controlSync.getCurrentConfig();
        const theme = controlSync.getPublishedTheme('halaa_default');
        sendJson(res, 200, {
          ok: true,
          globalVersion: controlSync.globalVersion,
          config,
          theme,
        });
        return true;
      }

      if (method === 'GET' && pathname === '/api/v1/sync/events') {
        const since = Number(url.searchParams.get('sinceVersion') || 0);
        sendJson(res, 200, {
          ok: true,
          globalVersion: controlSync.globalVersion,
          events: controlSync.getMissedEvents(since),
        });
        return true;
      }

      if (method === 'POST' && pathname === '/api/v1/sync/ack') {
        const body = await readJsonBody(req);
        const ack = controlSync.acknowledgeSync(body);
        sendJson(res, 200, { ok: true, ack });
        return true;
      }

      if (method === 'GET' && pathname === '/api/v1/sync/stream') {
        res.writeHead(200, {
          'Content-Type': 'text/event-stream; charset=utf-8',
          'Cache-Control': 'no-cache',
          Connection: 'keep-alive',
        });
        res.write(`event: connected\ndata: ${JSON.stringify({ globalVersion: controlSync.globalVersion })}\n\n`);
        const unsubscribe = controlSync.subscribe((evt) => {
          res.write(`event: ${evt.event}\ndata: ${JSON.stringify(evt)}\n\n`);
        });
        req.on('close', () => unsubscribe());
        return true;
      }

      // -------------------- Admin Auth Endpoints --------------------
      if (method === 'POST' && pathname === '/api/v1/auth/admin/login') {
        const body = await readJsonBody(req);
        const result = adminAuth.login({
          username: body.username,
          password: body.password,
          totpCode: body.totpCode,
          ipAddress: ip,
          deviceName: body.deviceName || 'Halaa Admin',
        });
        sendJson(res, 200, { ok: true, ...result });
        return true;
      }

      if (method === 'POST' && pathname === '/api/v1/auth/admin/refresh') {
        const body = await readJsonBody(req);
        const rotated = adminAuth.rotateRefreshToken(body.sessionId, body.refreshToken);
        sendJson(res, 200, { ok: true, ...rotated });
        return true;
      }

      // -------------------- Protected /api/v1/admin/* & /api/v1/security/* --------------------
      const { actor, session } = authenticateAdminRequest(req);

      if (method === 'POST' && pathname === '/api/v1/admin/voice/rooms') {
        const data = await readJsonBody(req);
        accessControl.authorize({actor,session,action:'rooms.manage',scope:{type:'ROOM',resourceId:data.room}});
        if (!options.manageVoiceRoom) { sendJson(res,503,{error:'Voice room manager unavailable'}); return true; }
        const result = options.manageVoiceRoom(data);
        auditService.record({actorId:actor.id,sessionId:session.id,action:'rooms.manage',resourceType:'ROOM',targetId:data.room,afterValue:data,result:'SUCCESS'});
        sendJson(res,200,{ok:true,...result}); return true;
      }

      if (method === 'GET' && pathname === '/api/v1/admin/roles') {
        accessControl.authorize({ actor, session, action: 'dashboard.read' });
        sendJson(res, 200, { ok: true, roles: INITIAL_ROLES });
        return true;
      }

      if (method === 'GET' && pathname === '/api/v1/admin/permissions') {
        accessControl.authorize({ actor, session, action: 'dashboard.read' });
        sendJson(res, 200, { ok: true, permissions: Object.values(INITIAL_PERMISSIONS) });
        return true;
      }

      if (method === 'GET' && pathname === '/api/v1/admin/config') {
        accessControl.authorize({ actor, session, action: 'dashboard.read' });
        sendJson(res, 200, { ok: true, config: controlSync.getCurrentConfig() });
        return true;
      }

      if (method === 'PATCH' && pathname === '/api/v1/admin/config') {
        const body = await readJsonBody(req);
        const updated = controlSync.updateConfig({
          actor,
          session,
          patch: body.patch || {},
          reason: body.reason,
        });
        sendJson(res, 200, { ok: true, ...updated });
        return true;
      }

      if (method === 'POST' && pathname === '/api/v1/admin/config/rollback') {
        const body = await readJsonBody(req);
        const rolled = controlSync.rollbackConfig({
          actor,
          session,
          targetVersion: body.targetVersion,
          reason: body.reason,
        });
        sendJson(res, 200, { ok: true, ...rolled });
        return true;
      }

      if (method === 'GET' && pathname === '/api/v1/admin/themes') {
        accessControl.authorize({ actor, session, action: 'dashboard.read' });
        sendJson(res, 200, { ok: true, activeTheme: controlSync.getPublishedTheme('halaa_default') });
        return true;
      }

      if (method === 'POST' && pathname === '/api/v1/admin/themes') {
        const body = await readJsonBody(req);
        const draft = controlSync.saveThemeDraft({
          actor,
          session,
          themeId: body.themeId || 'halaa_default',
          payload: body.payload,
          reason: body.reason,
        });
        sendJson(res, 201, { ok: true, draft });
        return true;
      }

      if (method === 'POST' && /^\/api\/v1\/admin\/themes\/[^/]+\/publish$/.test(pathname)) {
        const themeId = decodeURIComponent(pathname.split('/')[5]);
        const body = await readJsonBody(req);
        const published = controlSync.publishTheme({
          actor,
          session,
          themeId,
          version: body.version,
          reason: body.reason,
        });
        sendJson(res, 200, { ok: true, ...published });
        return true;
      }

      if (method === 'POST' && pathname === '/api/v1/admin/finance/adjustments') {
        const body = await readJsonBody(req);
        const result = ledgerService.applyAdjustment({
          actor,
          session,
          targetUserId: body.targetUserId,
          currency: body.currency || 'COINS',
          operation: body.operation || 'CREDIT',
          amount: body.amount,
          reason: body.reason,
          idempotencyKey: body.idempotencyKey,
          approvalId: body.approvalId,
          scope: body.scope || { type: 'GLOBAL' },
        });
        sendJson(res, 200, { ok: true, result });
        return true;
      }

      if (method === 'POST' && pathname === '/api/v1/admin/approvals') {
        const body = await readJsonBody(req);
        const request = approvalService.createRequest({
          requesterId: actor.id,
          actionCode: body.actionCode,
          resourceType: body.resourceType || 'GLOBAL',
          resourceId: body.resourceId || null,
          payload: body.payload || {},
          reason: body.reason,
          requiredApprovers: body.requiredApprovers || 1,
        });
        sendJson(res, 201, { ok: true, request });
        return true;
      }

      if (method === 'POST' && /^\/api\/v1\/admin\/approvals\/[^/]+\/approve$/.test(pathname)) {
        const requestId = decodeURIComponent(pathname.split('/')[5]);
        const body = await readJsonBody(req);
        const updated = approvalService.decide({
          requestId,
          approverId: actor.id,
          decision: body.decision || 'APPROVE',
          comment: body.comment || '',
          mfaVerified: session.mfaVerified,
        });
        sendJson(res, 200, { ok: true, request: updated });
        return true;
      }

      if (method === 'GET' && pathname === '/api/v1/admin/audit/logs') {
        accessControl.authorize({ actor, session, action: 'dashboard.read' });
        sendJson(res, 200, { ok: true, logs: auditService.listLogs(), chainValid: auditService.verifyChainIntegrity() });
        return true;
      }

      if (method === 'DELETE' && pathname.startsWith('/api/v1/admin/audit/logs')) {
        auditService.deleteLog();
        return true;
      }

      if (method === 'GET' && pathname === '/api/v1/admin/security/events') {
        accessControl.authorize({ actor, session, action: 'dashboard.read' });
        sendJson(res, 200, { ok: true, events: auditService.listSecurityEvents() });
        return true;
      }

      if (method === 'GET' && pathname === '/api/v1/admin/sync/status') {
        accessControl.authorize({ actor, session, action: 'dashboard.read' });
        sendJson(res, 200, { ok: true, status: controlSync.getSyncStatus() });
        return true;
      }

      if (method === 'POST' && pathname === '/api/v1/security/emergency') {
        const body = await readJsonBody(req);
        const resObj = controlSync.setEmergencyAction({
          actor,
          session,
          actionKey: body.actionKey,
          active: body.active,
          reason: body.reason,
          scope: body.scope || 'GLOBAL',
        });
        sendJson(res, 200, { ok: true, ...resObj });
        return true;
      }

      sendJson(res, 404, { ok: false, error: 'Admin API endpoint not found' });
      return true;
    } catch (err) {
      const code = err?.statusCode || err?.status || 500;
      sendJson(res, code, { ok: false, error: err?.message || 'Internal Server Error' });
      return true;
    }
  }

  return {
    auditService,
    accessControl,
    adminAuth,
    approvalService,
    ledgerService,
    controlSync,
    superOwner,
    handleRequest,
  };
}
