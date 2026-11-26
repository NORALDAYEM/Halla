import crypto from 'node:crypto';

function createError(message, statusCode) {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
}

function stablePayloadHash(payload) {
  const canonical = JSON.stringify(payload, Object.keys(payload || {}).sort());
  return crypto.createHash('sha256').update(canonical).digest('hex');
}

/**
 * Halaa Secure Approval Engine (Section 19)
 * - Dual-approval for critical financial/security/role operations
 * - Strictly prevents self-approval
 * - Cryptographically binds approval to exact payload hash (tamper-proof)
 * - Enforces expiration window
 */
export class ApprovalService {
  constructor({ auditService }) {
    this.auditService = auditService;
    this.requests = new Map();
  }

  createRequest({ requesterId, actionCode, resourceType, resourceId = null, payload, reason, requiredApprovers = 1, ttlMs = 30 * 60 * 1000 }) {
    if (!reason || String(reason).trim().length < 3) {
      throw createError('BAD_REQUEST: Reason is required for approval requests', 400);
    }
    const id = `appr_${crypto.randomUUID()}`;
    const request = {
      id,
      requesterId,
      actionCode,
      resourceType,
      resourceId,
      payload,
      payloadHash: stablePayloadHash(payload),
      reason: String(reason).trim(),
      status: 'PENDING',
      requiredApprovers,
      approvers: [],
      decisions: [],
      expiresAt: Date.now() + ttlMs,
      executedAt: null,
      createdAt: new Date().toISOString(),
    };
    this.requests.set(id, request);
    this.auditService.record({
      actorId: requesterId,
      action: 'approval.request.created',
      resourceType,
      targetId: id,
      afterValue: { actionCode, resourceId, requiredApprovers },
      reason: request.reason,
      result: 'SUCCESS',
    });
    return request;
  }

  decide({ requestId, approverId, decision, comment = '', mfaVerified = false }) {
    const req = this.requests.get(requestId);
    if (!req) throw createError('NOT_FOUND: Approval request not found', 404);
    if (req.status !== 'PENDING') {
      throw createError(`CONFLICT: Approval request is already ${req.status}`, 409);
    }
    if (Date.now() > req.expiresAt) {
      req.status = 'EXPIRED';
      throw createError('CONFLICT: Approval request has expired', 409);
    }
    if (!mfaVerified) {
      throw createError('FORBIDDEN: MFA verification is required to approve sensitive requests', 403);
    }
    if (req.requesterId === approverId) {
      this.auditService.recordSecurityEvent({
        severity: 'HIGH',
        eventType: 'SELF_APPROVAL_ATTEMPT',
        actorId: approverId,
        details: { requestId, actionCode: req.actionCode },
      });
      throw createError('FORBIDDEN: Requesters cannot approve their own request', 403);
    }
    if (req.decisions.some((d) => d.approverId === approverId)) {
      throw createError('CONFLICT: Approver has already decided on this request', 409);
    }

    const normalized = decision === 'APPROVE' ? 'APPROVE' : 'REJECT';
    req.decisions.push({ approverId, decision: normalized, comment, at: new Date().toISOString() });

    if (normalized === 'REJECT') {
      req.status = 'REJECTED';
    } else {
      req.approvers.push(approverId);
      if (req.approvers.length >= req.requiredApprovers) {
        req.status = 'APPROVED';
      }
    }

    this.auditService.record({
      actorId: approverId,
      action: `approval.request.${normalized.toLowerCase()}`,
      targetId: requestId,
      reason: comment || normalized,
      approvalId: requestId,
      result: 'SUCCESS',
    });

    return req;
  }

  verifyForExecution(requestId, expectedPayload) {
    const req = this.requests.get(requestId);
    if (!req) throw createError('NOT_FOUND: Approval request not found', 404);
    if (req.status !== 'APPROVED') {
      throw createError(`FORBIDDEN: Approval request is ${req.status}, not APPROVED`, 403);
    }
    if (Date.now() > req.expiresAt) {
      req.status = 'EXPIRED';
      throw createError('FORBIDDEN: Approval request expired before execution', 403);
    }
    const hash = stablePayloadHash(expectedPayload);
    if (hash !== req.payloadHash) {
      this.auditService.recordSecurityEvent({
        severity: 'CRITICAL',
        eventType: 'APPROVAL_PAYLOAD_TAMPERING',
        details: { requestId },
      });
      throw createError('FORBIDDEN: Payload was modified after approval', 403);
    }
    return req;
  }

  markExecuted(requestId) {
    const req = this.requests.get(requestId);
    if (req) {
      req.status = 'EXECUTED';
      req.executedAt = new Date().toISOString();
    }
  }
}
