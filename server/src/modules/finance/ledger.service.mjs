import crypto from 'node:crypto';

function createError(message, statusCode) {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
}

/**
 * Double-Entry Financial Ledger Service (Section 18)
 * - No direct balance overwrites
 * - Strict idempotencyKey deduplication (duplicate requests execute once only)
 * - Requires AccessControlService + ApprovalService verification
 */
export class FinancialLedgerService {
  constructor({ accessControl, approvalService, auditService }) {
    this.accessControl = accessControl;
    this.approvalService = approvalService;
    this.auditService = auditService;
    this.entries = [];
    this.idempotencyCache = new Map(); // idempotencyKey -> transactionGroupResult
  }

  getBalance(accountId, currency = 'COINS') {
    let balance = 0;
    for (const e of this.entries) {
      if (e.accountId === accountId && e.currency === currency) {
        balance += e.entryType === 'CREDIT' ? e.amount : -e.amount;
      }
    }
    return Number(balance.toFixed(2));
  }

  applyAdjustment({
    actor,
    session,
    targetUserId,
    currency = 'COINS',
    operation = 'CREDIT',
    amount,
    reason,
    idempotencyKey,
    approvalId,
    scope = { type: 'GLOBAL' },
  }) {
    if (!idempotencyKey || String(idempotencyKey).trim().length < 6) {
      throw createError('BAD_REQUEST: idempotencyKey is required for financial adjustments', 400);
    }

    // Idempotent replay protection: return original result without double-applying
    if (this.idempotencyCache.has(idempotencyKey)) {
      return {
        ...this.idempotencyCache.get(idempotencyKey),
        idempotentReplay: true,
      };
    }

    const op = operation === 'DEBIT' ? 'DEBIT' : 'CREDIT';
    const action = op === 'CREDIT' ? 'finance.wallet.credit' : 'finance.wallet.debit';
    const numericAmount = Number(amount);

    // Verify independent approval bound to exact payload
    const payload = { targetUserId, currency, operation: op, amount: numericAmount };
    const approval = approvalId ? this.approvalService.verifyForExecution(approvalId, payload) : null;

    // Central authorization check (permission, MFA, limits, approval, self-approval)
    this.accessControl.authorize({
      actor,
      session,
      action,
      scope,
      amount: numericAmount,
      reason,
      approval,
    });

    if (op === 'DEBIT' && this.getBalance(targetUserId, currency) < numericAmount) {
      throw createError('CONFLICT: Insufficient user balance for debit', 409);
    }

    const beforeBalance = this.getBalance(targetUserId, currency);
    const txGroup = `tx_${crypto.randomUUID()}`;
    const now = new Date().toISOString();

    // Double-entry pair: user account + central treasury counterpart
    const userEntry = Object.freeze({
      id: `led_${crypto.randomUUID()}`,
      transactionGroup: txGroup,
      idempotencyKey,
      accountId: targetUserId,
      currency,
      entryType: op,
      amount: numericAmount,
      reason,
      actorAdminId: actor.id,
      approvalId: approval?.id || null,
      createdAt: now,
    });

    const treasuryEntry = Object.freeze({
      id: `led_${crypto.randomUUID()}`,
      transactionGroup: txGroup,
      idempotencyKey,
      accountId: 'SYSTEM_TREASURY',
      currency,
      entryType: op === 'CREDIT' ? 'DEBIT' : 'CREDIT',
      amount: numericAmount,
      reason,
      actorAdminId: actor.id,
      approvalId: approval?.id || null,
      createdAt: now,
    });

    this.entries.push(userEntry, treasuryEntry);
    if (approval) this.approvalService.markExecuted(approval.id);

    const afterBalance = this.getBalance(targetUserId, currency);

    this.auditService.record({
      actorId: actor.id,
      action,
      permissionUsed: action,
      resourceType: 'WALLET',
      targetId: targetUserId,
      beforeValue: { balance: beforeBalance, currency },
      afterValue: { balance: afterBalance, currency, amount: numericAmount, operation: op },
      reason,
      sessionId: session.id,
      approvalId: approval?.id || null,
      result: 'SUCCESS',
    });

    const result = {
      transactionGroup: txGroup,
      targetUserId,
      currency,
      operation: op,
      amount: numericAmount,
      beforeBalance,
      afterBalance,
      idempotentReplay: false,
    };
    this.idempotencyCache.set(idempotencyKey, result);
    return result;
  }
}
