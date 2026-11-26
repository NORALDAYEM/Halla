import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { createCentralAdminSystem } from './central-admin-router.mjs';
import { generateTotpCode } from './modules/admin-authentication/admin-auth.service.mjs';

function setupSystem() {
  const sys = createCentralAdminSystem({
    tokenSecret: 'test-only-ephemeral-secret-for-unit-tests',
    superOwnerUser: 'owner_root',
    superOwnerPass: 'StrongOwner#2026!',
  });

  // Grant standard operational/financial roles
  sys.accessControl.grantRolePermission('FINANCE_DIRECTOR', 'finance.wallet.credit', {
    conditions: { maxAmountPerOperation: 5000, maxAmountPerDay: 20000, requireReason: true, requireMfa: true, requireApproval: true },
  });
  sys.accessControl.grantRolePermission('ROOM_MODERATOR', 'rooms.manage');
  sys.accessControl.grantRolePermission('AGENCY_OWNER', 'agencies.read');
  sys.accessControl.grantRolePermission('DESIGN_DIRECTOR', 'themes.publish');
  sys.accessControl.grantRolePermission('SECURITY_DIRECTOR', 'emergency.control');

  const financeAdmin = sys.adminAuth.registerAdmin({
    id: 'admin_finance_1',
    username: 'finance_lead',
    password: 'StrongFinance#2026!',
  });
  sys.accessControl.assignRoleToActor({
    actor: sys.superOwner,
    targetAdmin: financeAdmin,
    roleCode: 'FINANCE_DIRECTOR',
  });

  const approverAdmin = sys.adminAuth.registerAdmin({
    id: 'admin_approver_2',
    username: 'general_mgr',
    password: 'StrongManager#2026!',
  });

  const roomMod = sys.adminAuth.registerAdmin({
    id: 'admin_room_mod',
    username: 'room_mod_1',
    password: 'StrongRoomMod#2026!',
  });
  sys.accessControl.assignRoleToActor({
    actor: sys.superOwner,
    targetAdmin: roomMod,
    roleCode: 'ROOM_MODERATOR',
    scope: { type: 'ROOM', resourceId: 'room_100' },
  });

  const agencyOwner = sys.adminAuth.registerAdmin({
    id: 'admin_agency_1',
    username: 'agency_owner_1',
    password: 'StrongAgency#2026!',
  });
  sys.accessControl.assignRoleToActor({
    actor: sys.superOwner,
    targetAdmin: agencyOwner,
    roleCode: 'AGENCY_OWNER',
    scope: { type: 'AGENCY', resourceId: 'agency_A' },
  });

  return { sys, financeAdmin, approverAdmin, roomMod, agencyOwner };
}

test('1. Normal user / unauthenticated client attempting Admin API is rejected', async () => {
  const { sys } = setupSystem();
  const server = http.createServer((req, res) => {
    sys.handleRequest(req, res);
  });
  await new Promise((r) => server.listen(0, r));
  const { port } = server.address();
  try {
    const res = await fetch(`http://127.0.0.1:${port}/api/v1/admin/roles`, {
      headers: { Authorization: 'Bearer fake-normal-user-jwt' },
    });
    assert.equal(res.status, 401);
  } finally {
    server.close();
  }
});

test('2. Admin attempting to modify or target SUPER_OWNER is rejected', () => {
  const { sys, financeAdmin } = setupSystem();
  const login = sys.adminAuth.login({
    username: 'finance_lead',
    password: 'StrongFinance#2026!',
    totpCode: generateTotpCode(financeAdmin.mfaSecret),
  });
  const { actor, session } = sys.adminAuth.validateAccessToken(login.accessToken);
  assert.throws(
    () =>
      sys.accessControl.authorize({
        actor,
        session,
        action: 'users.ban',
        resource: sys.superOwner,
        reason: 'Attempted ban',
      }),
    /SUPER_OWNER/
  );
});

test('3. Admin attempting self-escalation is rejected', () => {
  const { sys, financeAdmin } = setupSystem();
  assert.throws(
    () =>
      sys.accessControl.assignRoleToActor({
        actor: financeAdmin,
        targetAdmin: financeAdmin,
        roleCode: 'SUPER_OWNER',
      }),
    /escalate/i
  );
});

test('4. Admin attempting to delegate/grant unauthorized permission is rejected', () => {
  const { sys, financeAdmin, roomMod } = setupSystem();
  assert.throws(
    () =>
      sys.accessControl.assignDirectPermission({
        actor: financeAdmin,
        targetActorId: roomMod.id,
        permissionCode: 'emergency.control',
      }),
    /not authorized to delegate/i
  );
});

test('5. Financial adjustment without approval is rejected; self-approval is rejected; approved adjustment executes once with idempotency', () => {
  const { sys, financeAdmin, approverAdmin } = setupSystem();
  const finLogin = sys.adminAuth.login({
    username: 'finance_lead',
    password: 'StrongFinance#2026!',
    totpCode: generateTotpCode(financeAdmin.mfaSecret),
  });
  const finCtx = sys.adminAuth.validateAccessToken(finLogin.accessToken);

  // Without approval -> rejected
  assert.throws(
    () =>
      sys.ledgerService.applyAdjustment({
        actor: finCtx.actor,
        session: finCtx.session,
        targetUserId: 'user_99',
        currency: 'COINS',
        operation: 'CREDIT',
        amount: 1000,
        reason: 'Tournament reward',
        idempotencyKey: 'idem-no-approval-1',
      }),
    /approval is required/i
  );

  // Create approval request
  const payload = { targetUserId: 'user_99', currency: 'COINS', operation: 'CREDIT', amount: 1000 };
  const req = sys.approvalService.createRequest({
    requesterId: financeAdmin.id,
    actionCode: 'finance.wallet.credit',
    resourceType: 'WALLET',
    resourceId: 'user_99',
    payload,
    reason: 'Tournament reward',
  });

  // Self-approval -> rejected
  assert.throws(
    () =>
      sys.approvalService.decide({
        requestId: req.id,
        approverId: financeAdmin.id,
        decision: 'APPROVE',
        mfaVerified: true,
      }),
    /cannot approve their own request/i
  );

  // Independent approver approves with MFA
  sys.approvalService.decide({
    requestId: req.id,
    approverId: approverAdmin.id,
    decision: 'APPROVE',
    mfaVerified: true,
  });

  // Execute once -> succeeds
  const first = sys.ledgerService.applyAdjustment({
    actor: finCtx.actor,
    session: finCtx.session,
    targetUserId: 'user_99',
    currency: 'COINS',
    operation: 'CREDIT',
    amount: 1000,
    reason: 'Tournament reward',
    idempotencyKey: 'idem-approved-001',
    approvalId: req.id,
  });
  assert.equal(first.afterBalance, 1000);
  assert.equal(first.idempotentReplay, false);

  // Duplicate retry with same idempotencyKey -> returns cached result, balance remains 1000
  const second = sys.ledgerService.applyAdjustment({
    actor: finCtx.actor,
    session: finCtx.session,
    targetUserId: 'user_99',
    currency: 'COINS',
    operation: 'CREDIT',
    amount: 1000,
    reason: 'Tournament reward',
    idempotencyKey: 'idem-approved-001',
    approvalId: req.id,
  });
  assert.equal(second.idempotentReplay, true);
  assert.equal(sys.ledgerService.getBalance('user_99', 'COINS'), 1000);
});

test('6. Room moderator blocked from managing another room & Agency owner blocked from viewing another agency', () => {
  const { sys, roomMod, agencyOwner } = setupSystem();
  const modLogin = sys.adminAuth.login({
    username: 'room_mod_1',
    password: 'StrongRoomMod#2026!',
    totpCode: generateTotpCode(roomMod.mfaSecret),
  });
  const modCtx = sys.adminAuth.validateAccessToken(modLogin.accessToken);

  // Own room -> allowed
  const okRoom = sys.accessControl.authorize({
    actor: modCtx.actor,
    session: modCtx.session,
    action: 'rooms.manage',
    scope: { type: 'ROOM', resourceId: 'room_100' },
  });
  assert.equal(okRoom.allowed, true);

  // Another room -> rejected
  assert.throws(
    () =>
      sys.accessControl.authorize({
        actor: modCtx.actor,
        session: modCtx.session,
        action: 'rooms.manage',
        scope: { type: 'ROOM', resourceId: 'room_200' },
      }),
    /Permission denied/i
  );

  // Agency owner accessing another agency -> rejected
  const agLogin = sys.adminAuth.login({
    username: 'agency_owner_1',
    password: 'StrongAgency#2026!',
    totpCode: generateTotpCode(agencyOwner.mfaSecret),
  });
  const agCtx = sys.adminAuth.validateAccessToken(agLogin.accessToken);
  assert.throws(
    () =>
      sys.accessControl.authorize({
        actor: agCtx.actor,
        session: agCtx.session,
        action: 'agencies.read',
        scope: { type: 'AGENCY', resourceId: 'agency_B' },
      }),
    /Permission denied/i
  );
});

test('7. Revoked admin session & expired permission are rejected immediately', () => {
  const { sys, roomMod } = setupSystem();
  const login = sys.adminAuth.login({
    username: 'room_mod_1',
    password: 'StrongRoomMod#2026!',
    totpCode: generateTotpCode(roomMod.mfaSecret),
  });
  sys.adminAuth.revokeSession(login.sessionId, 'LOST_DEVICE');
  assert.throws(() => sys.adminAuth.validateAccessToken(login.accessToken), /revoked/i);

  // Expired direct permission -> rejected
  sys.accessControl.assignDirectPermission({
    actor: sys.superOwner,
    targetActorId: roomMod.id,
    permissionCode: 'games.config.update',
    expiresAt: new Date(Date.now() - 60_000).toISOString(),
  });
  const freshLogin = sys.adminAuth.login({
    username: 'room_mod_1',
    password: 'StrongRoomMod#2026!',
    totpCode: generateTotpCode(roomMod.mfaSecret),
  });
  const ctx = sys.adminAuth.validateAccessToken(freshLogin.accessToken);
  assert.throws(
    () =>
      sys.accessControl.authorize({
        actor: ctx.actor,
        session: ctx.session,
        action: 'games.config.update',
        reason: 'Test expired',
      }),
    /Permission denied/i
  );
});

test('8. Level 5 Sovereign action blocked from direct mobile execution & VIP cannot receive admin permissions', () => {
  const { sys } = setupSystem();
  const ownerLogin = sys.adminAuth.login({
    username: 'owner_root',
    password: 'StrongOwner#2026!',
    totpCode: generateTotpCode(sys.superOwner.mfaSecret),
  });
  const ownerCtx = sys.adminAuth.validateAccessToken(ownerLogin.accessToken);

  assert.throws(
    () =>
      sys.accessControl.authorize({
        actor: ownerCtx.actor,
        session: ownerCtx.session,
        action: 'sovereign.transfer_ownership',
        reason: 'Mobile attempt',
        channel: 'MOBILE_ADMIN_APP',
      }),
    /Level 5 Sovereign/i
  );

  assert.throws(
    () => sys.accessControl.grantRolePermission('VIP', 'rooms.manage'),
    /cannot be granted administrative permissions/i
  );
});

test('9. Invalid theme rejected, valid theme published + synced, rollback creates new version, emergency disables single game only, audit log deletion blocked', () => {
  const { sys } = setupSystem();
  const ownerLogin = sys.adminAuth.login({
    username: 'owner_root',
    password: 'StrongOwner#2026!',
    totpCode: generateTotpCode(sys.superOwner.mfaSecret),
  });
  const ownerCtx = sys.adminAuth.validateAccessToken(ownerLogin.accessToken);

  // Invalid theme rejected
  assert.throws(
    () =>
      sys.controlSync.saveThemeDraft({
        actor: ownerCtx.actor,
        session: ownerCtx.session,
        payload: { colors: { primary: 'not-a-hex' } },
        reason: 'Invalid color test',
      }),
    /Invalid hex color/i
  );

  // Valid theme draft -> published -> emits sync event
  const received = [];
  const unsub = sys.controlSync.subscribe((e) => received.push(e));
  const draft = sys.controlSync.saveThemeDraft({
    actor: ownerCtx.actor,
    session: ownerCtx.session,
    payload: {
      colors: { primary: '#118B97', secondary: '#D5B45C', background: '#101426', textPrimary: '#FFFFFF' },
      buttons: { opacity: 0.9, borderRadius: 18, height: 46 },
    },
    reason: 'Seasonal theme update',
  });
  const published = sys.controlSync.publishTheme({
    actor: ownerCtx.actor,
    session: ownerCtx.session,
    version: draft.version,
    reason: 'Publish seasonal theme',
  });
  assert.equal(published.syncEvent.event, 'theme.updated');
  assert.equal(received.length, 1);
  unsub();

  // Config update + rollback creates NEW version (v3 restoring v1)
  sys.controlSync.updateConfig({
    actor: ownerCtx.actor,
    session: ownerCtx.session,
    patch: { features: { games: { ludo: false } } },
    reason: 'Disable ludo temporarily',
  });
  assert.equal(sys.controlSync.isFeatureEnabled('games.ludo'), false);
  assert.equal(sys.controlSync.isFeatureEnabled('games.chess'), true);

  const rolled = sys.controlSync.rollbackConfig({
    actor: ownerCtx.actor,
    session: ownerCtx.session,
    targetVersion: 1,
    reason: 'Restore ludo',
  });
  assert.equal(rolled.config.version, 3);
  assert.equal(sys.controlSync.isFeatureEnabled('games.ludo'), true);

  // Audit log deletion blocked & hash chain intact
  assert.throws(() => sys.auditService.deleteLog(), /AUDIT_LOG_IMMUTABLE/);
  assert.equal(sys.auditService.verifyChainIntegrity(), true);
});
