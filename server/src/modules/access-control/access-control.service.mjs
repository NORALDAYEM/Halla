/**
 * Halaa Dynamic Access Control Engine (RBAC + ABAC + ReBAC + Delegation + Policy)
 * Implements Sections 6, 7, 8, 9, and 10 of the Engineering Specification:
 * - Deny By Default
 * - Explicit DENY overrides ALLOW for matching scope
 * - 5 Risk Levels (Level 5 SOVEREIGN cannot execute directly from mobile)
 * - Protected SUPER_OWNER rules (immutable, cannot be modified/banned/deleted by others)
 * - Strict separation between Admin roles and VIP/User/Guest tiers
 */

export const RISK_LEVELS = Object.freeze({
  GENERAL: 1,
  OPERATIONAL: 2,
  SENSITIVE_ADMIN: 3,
  CRITICAL_FINANCIAL_SECURITY: 4,
  SOVEREIGN: 5,
});

export const INITIAL_ROLES = Object.freeze([
  { code: 'SUPER_OWNER', nameAr: 'المالك الرئيسي', category: 'ADMIN', priority: 1, isProtected: true },
  { code: 'GENERAL_MANAGER', nameAr: 'المدير العام', category: 'ADMIN', priority: 10 },
  { code: 'DEPUTY_MANAGER', nameAr: 'نائب المدير', category: 'ADMIN', priority: 20 },
  { code: 'SECURITY_DIRECTOR', nameAr: 'مدير الأمن', category: 'ADMIN', priority: 25 },
  { code: 'FINANCE_DIRECTOR', nameAr: 'المدير المالي', category: 'ADMIN', priority: 25 },
  { code: 'DESIGN_DIRECTOR', nameAr: 'مدير التصميم', category: 'ADMIN', priority: 30 },
  { code: 'CONTENT_DIRECTOR', nameAr: 'مدير المحتوى', category: 'ADMIN', priority: 30 },
  { code: 'ROOMS_DIRECTOR', nameAr: 'مدير الغرف', category: 'ADMIN', priority: 30 },
  { code: 'GAMES_DIRECTOR', nameAr: 'مدير الألعاب', category: 'ADMIN', priority: 30 },
  { code: 'AGENCIES_DIRECTOR', nameAr: 'مدير الوكالات', category: 'ADMIN', priority: 30 },
  { code: 'GIFTS_DIRECTOR', nameAr: 'مدير الهدايا', category: 'ADMIN', priority: 30 },
  { code: 'GENERAL_SUPERVISOR', nameAr: 'المشرف العام', category: 'ADMIN', priority: 40 },
  { code: 'TECHNICAL_SUPPORT', nameAr: 'الدعم الفني', category: 'ADMIN', priority: 50 },
  { code: 'AGENCY_OWNER', nameAr: 'مالك الوكالة', category: 'AGENCY', priority: 60 },
  { code: 'ROOM_OWNER', nameAr: 'مالك الغرفة', category: 'ROOM', priority: 70 },
  { code: 'ROOM_MODERATOR', nameAr: 'مشرف الغرفة', category: 'ROOM', priority: 75 },
  { code: 'HOST', nameAr: 'المضيف', category: 'ROOM', priority: 80 },
  { code: 'VIP', nameAr: 'VIP', category: 'USER', priority: 90 },
  { code: 'USER', nameAr: 'المستخدم', category: 'USER', priority: 95 },
  { code: 'GUEST', nameAr: 'الضيف', category: 'USER', priority: 100 },
]);

export const INITIAL_PERMISSIONS = Object.freeze({
  'dashboard.read': {
    code: 'dashboard.read',
    nameAr: 'عرض لوحة القيادة',
    descriptionAr: 'الاطلاع على الإحصائيات العامة غير الحساسة',
    riskLevel: RISK_LEVELS.GENERAL,
    requiresMfa: false,
    requiresApproval: false,
    requiresReason: false,
    mobileExecutable: true,
  },
  'rooms.manage': {
    code: 'rooms.manage',
    nameAr: 'إدارة الغرف الصوتية',
    descriptionAr: 'تعديل إعدادات الغرفة والمقاعد وطرد أو كتم المخالفين ضمن النطاق المصرح به',
    riskLevel: RISK_LEVELS.OPERATIONAL,
    requiresMfa: false,
    requiresApproval: false,
    requiresReason: false,
    mobileExecutable: true,
  },
  'games.config.update': {
    code: 'games.config.update',
    nameAr: 'إدارة إعدادات الألعاب',
    descriptionAr: 'تفعيل أو تعطيل الألعاب وتعديل إعداداتها المعتمدة مسبقًا',
    riskLevel: RISK_LEVELS.OPERATIONAL,
    requiresMfa: false,
    requiresApproval: false,
    requiresReason: true,
    mobileExecutable: true,
  },
  'themes.publish': {
    code: 'themes.publish',
    nameAr: 'نشر وتعديل الثيمات',
    descriptionAr: 'إنشاء ومعاينة ونشر أو استعادة ثيمات التطبيق',
    riskLevel: RISK_LEVELS.OPERATIONAL,
    requiresMfa: false,
    requiresApproval: false,
    requiresReason: true,
    mobileExecutable: true,
  },
  'config.update': {
    code: 'config.update',
    nameAr: 'تعديل إعدادات التطبيق عن بعد',
    descriptionAr: 'تحديث الإعدادات والخصائص عن بعد ومزامنتها مع الأجهزة',
    riskLevel: RISK_LEVELS.SENSITIVE_ADMIN,
    requiresMfa: true,
    requiresApproval: false,
    requiresReason: true,
    mobileExecutable: true,
  },
  'agencies.read': {
    code: 'agencies.read',
    nameAr: 'الاطلاع على بيانات الوكالة',
    descriptionAr: 'عرض تفاصيل وإحصائيات الوكالة ضمن النطاق المحدد',
    riskLevel: RISK_LEVELS.SENSITIVE_ADMIN,
    requiresMfa: false,
    requiresApproval: false,
    requiresReason: false,
    mobileExecutable: true,
  },
  'users.ban': {
    code: 'users.ban',
    nameAr: 'حظر الحسابات',
    descriptionAr: 'حظر أو تجميد حسابات المستخدمين المخالفين',
    riskLevel: RISK_LEVELS.SENSITIVE_ADMIN,
    requiresMfa: true,
    requiresApproval: false,
    requiresReason: true,
    mobileExecutable: true,
  },
  'roles.assign': {
    code: 'roles.assign',
    nameAr: 'منح وتعديل الرتب والصلاحيات',
    descriptionAr: 'تعيين الرتب الإدارية وتعديل الصلاحيات ضمن التفويض الممنوح',
    riskLevel: RISK_LEVELS.SENSITIVE_ADMIN,
    requiresMfa: true,
    requiresApproval: true,
    requiresReason: true,
    mobileExecutable: true,
  },
  'finance.wallet.read': {
    code: 'finance.wallet.read',
    nameAr: 'عرض أرصدة المحافظ',
    descriptionAr: 'الاطلاع على أرصدة العملات والجواهر',
    riskLevel: RISK_LEVELS.SENSITIVE_ADMIN,
    requiresMfa: false,
    requiresApproval: false,
    requiresReason: false,
    mobileExecutable: true,
  },
  'finance.wallet.credit': {
    code: 'finance.wallet.credit',
    nameAr: 'إضافة رصيد مالي',
    descriptionAr: 'إضافة عملات أو جواهر عبر دفتر مزدوج القيد بموافقة مزدوجة',
    riskLevel: RISK_LEVELS.CRITICAL_FINANCIAL_SECURITY,
    requiresMfa: true,
    requiresApproval: true,
    requiresReason: true,
    mobileExecutable: true,
  },
  'finance.wallet.debit': {
    code: 'finance.wallet.debit',
    nameAr: 'خصم رصيد مالي',
    descriptionAr: 'خصم عملات أو جواهر عبر دفتر مزدوج القيد بموافقة مزدوجة',
    riskLevel: RISK_LEVELS.CRITICAL_FINANCIAL_SECURITY,
    requiresMfa: true,
    requiresApproval: true,
    requiresReason: true,
    mobileExecutable: true,
  },
  'emergency.control': {
    code: 'emergency.control',
    nameAr: 'مركز التحكم في الطوارئ',
    descriptionAr: 'تفعيل أو إيقاف إجراءات الطوارئ المحددة لخاصية معينة',
    riskLevel: RISK_LEVELS.CRITICAL_FINANCIAL_SECURITY,
    requiresMfa: true,
    requiresApproval: false,
    requiresReason: true,
    mobileExecutable: true,
  },
  'sovereign.transfer_ownership': {
    code: 'sovereign.transfer_ownership',
    nameAr: 'نقل ملكية التطبيق',
    descriptionAr: 'عملية سيادية محمية لا تُنفذ مباشرة من الهاتف وتتطلب مسار بنية تحتية معتمد',
    riskLevel: RISK_LEVELS.SOVEREIGN,
    requiresMfa: true,
    requiresApproval: true,
    requiresReason: true,
    mobileExecutable: false,
  },
  'sovereign.rotate_keys': {
    code: 'sovereign.rotate_keys',
    nameAr: 'تدوير مفاتيح الخدمات',
    descriptionAr: 'تدوير مفاتيح الخادم والبنية التحتية عبر طلب آمن معتمد فقط',
    riskLevel: RISK_LEVELS.SOVEREIGN,
    requiresMfa: true,
    requiresApproval: true,
    requiresReason: true,
    mobileExecutable: false,
  },
});

function createError(message, statusCode) {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
}

function isGrantActive(grant, nowMs) {
  if (grant.revokedAt) return false;
  if (grant.startsAt && new Date(grant.startsAt).getTime() > nowMs) return false;
  if (grant.expiresAt && new Date(grant.expiresAt).getTime() <= nowMs) return false;
  return true;
}

function scopeMatches(grantScope, reqScope) {
  if (!grantScope || grantScope.type === 'GLOBAL') return true;
  if (!reqScope) return false;
  if (grantScope.type !== reqScope.type) return false;
  return String(grantScope.resourceId) === String(reqScope.resourceId);
}

export class AccessControlService {
  constructor({ auditService }) {
    this.auditService = auditService;
    this.roles = new Map(INITIAL_ROLES.map((r) => [r.code, { ...r }]));
    this.permissions = new Map(Object.entries(INITIAL_PERMISSIONS).map(([k, v]) => [k, { ...v }]));
    this.rolePermissions = new Map(); // roleCode -> Map<permCode, grant>
    this.userRoles = new Map();       // actorId -> Array<roleAssignment>
    this.userPermissions = new Map(); // actorId -> Array<directGrant>
    this.delegations = [];            // temporary delegations
    this.dailyUsage = new Map();      // `${actorId}:${permCode}:${YYYY-MM-DD}` -> { ops, amount }
  }

  grantRolePermission(roleCode, permissionCode, options = {}) {
    const role = this.roles.get(roleCode);
    if (!role) throw createError(`Unknown role: ${roleCode}`, 404);
    if (role.category === 'USER') {
      throw createError('VIP/USER/GUEST roles cannot be granted administrative permissions', 403);
    }
    if (!this.permissions.has(permissionCode)) {
      throw createError(`Unknown permission: ${permissionCode}`, 404);
    }
    if (!this.rolePermissions.has(roleCode)) this.rolePermissions.set(roleCode, new Map());
    this.rolePermissions.get(roleCode).set(permissionCode, {
      permissionCode,
      effect: options.effect === 'DENY' ? 'DENY' : 'ALLOW',
      canDelegate: Boolean(options.canDelegate),
      conditions: options.conditions || {},
    });
  }

  assignRoleToActor({ actor, targetAdmin, roleCode, scope = { type: 'GLOBAL' }, expiresAt = null }) {
    // Prevent self-escalation
    if (actor && actor.id === targetAdmin.id) {
      this.auditService.recordSecurityEvent({
        severity: 'HIGH',
        eventType: 'SELF_ESCALATION_ATTEMPT',
        actorId: actor.id,
        details: { roleCode },
      });
      throw createError('FORBIDDEN: Administrators cannot escalate or modify their own role', 403);
    }
    // Protect SUPER_OWNER from modification by any other admin
    if (targetAdmin.isSuperOwner && (!actor || !actor.isSuperOwner)) {
      throw createError('FORBIDDEN: SUPER_OWNER account is protected and cannot be modified', 403);
    }
    if (roleCode === 'SUPER_OWNER' && (!actor || !actor.isSuperOwner)) {
      throw createError('FORBIDDEN: Cannot assign SUPER_OWNER role', 403);
    }
    if (!this.roles.has(roleCode)) {
      throw createError(`Unknown role: ${roleCode}`, 404);
    }
    const list = this.userRoles.get(targetAdmin.id) || [];
    list.push({
      roleCode,
      scope,
      startsAt: new Date().toISOString(),
      expiresAt,
      revokedAt: null,
    });
    this.userRoles.set(targetAdmin.id, list);
  }

  assignDirectPermission({ actor, targetActorId, permissionCode, effect = 'ALLOW', scope = { type: 'GLOBAL' }, conditions = {}, expiresAt = null, targetIsSuperOwner = false }) {
    if (targetIsSuperOwner && (!actor || !actor.isSuperOwner)) {
      throw createError('FORBIDDEN: Cannot modify SUPER_OWNER permissions', 403);
    }
    // Prevent delegating/granting a permission the actor does not possess (unless SUPER_OWNER)
    if (actor && !actor.isSuperOwner) {
      const actorHas = this.hasPermissionRaw(actor, permissionCode, scope);
      if (!actorHas.allowed || !actorHas.canDelegate) {
        throw createError('FORBIDDEN: Cannot grant or delegate a permission you are not authorized to delegate', 403);
      }
    }
    const list = this.userPermissions.get(targetActorId) || [];
    list.push({
      permissionCode,
      effect: effect === 'DENY' ? 'DENY' : 'ALLOW',
      scope,
      conditions,
      startsAt: new Date().toISOString(),
      expiresAt,
      revokedAt: null,
    });
    this.userPermissions.set(targetActorId, list);
  }

  hasPermissionRaw(actor, permissionCode, reqScope) {
    if (!actor || !actor.isActive) return { allowed: false, canDelegate: false, conditions: {} };
    if (actor.isSuperOwner) {
      return { allowed: true, canDelegate: true, conditions: { requireMfa: true } };
    }

    const nowMs = Date.now();
    let matchedAllow = null;
    let matchedDeny = false;

    // 1. Direct user_permissions
    const directGrants = this.userPermissions.get(actor.id) || [];
    for (const grant of directGrants) {
      if (grant.permissionCode !== permissionCode) continue;
      if (!isGrantActive(grant, nowMs)) continue;
      if (!scopeMatches(grant.scope, reqScope)) continue;
      if (grant.effect === 'DENY') matchedDeny = true;
      else matchedAllow = { allowed: true, canDelegate: Boolean(grant.canDelegate), conditions: grant.conditions || {} };
    }

    // 2. Role permissions
    const roleAssignments = this.userRoles.get(actor.id) || [];
    for (const assignment of roleAssignments) {
      if (!isGrantActive(assignment, nowMs)) continue;
      if (!scopeMatches(assignment.scope, reqScope)) continue;
      const rPerms = this.rolePermissions.get(assignment.roleCode);
      if (!rPerms) continue;
      const grant = rPerms.get(permissionCode);
      if (!grant) continue;
      if (grant.effect === 'DENY') matchedDeny = true;
      else if (!matchedAllow) {
        matchedAllow = { allowed: true, canDelegate: grant.canDelegate, conditions: grant.conditions || {} };
      }
    }

    // 3. Explicit DENY always wins
    if (matchedDeny) return { allowed: false, canDelegate: false, conditions: {} };
    if (matchedAllow) return matchedAllow;
    return { allowed: false, canDelegate: false, conditions: {} };
  }

  /**
   * Central authorization gate (Section 10)
   */
  authorize({
    actor,
    session,
    action,
    resource = null,
    scope = { type: 'GLOBAL' },
    amount = null,
    reason = null,
    approval = null,
    channel = 'ADMIN_APP',
  }) {
    // 1. Validate session & active admin account
    if (!session || !session.valid) {
      throw createError('UNAUTHORIZED: Invalid or revoked admin session', 401);
    }
    if (!actor || !actor.isActive || actor.isAdmin !== true) {
      throw createError('FORBIDDEN: Administrative account required', 403);
    }
    if (session.permissionEpoch !== actor.permissionEpoch) {
      throw createError('UNAUTHORIZED: Session permission epoch expired after privilege change', 401);
    }

    // 2. Protected resource validation (SUPER_OWNER immutable rules)
    if (resource && resource.isSuperOwner && !actor.isSuperOwner) {
      this.auditService.recordSecurityEvent({
        severity: 'CRITICAL',
        eventType: 'SUPER_OWNER_PROTECTION_TRIGGERED',
        actorId: actor.id,
        details: { action, targetId: resource.id },
      });
      throw createError('FORBIDDEN: SUPER_OWNER cannot be targeted or modified by other administrators', 403);
    }

    // 3. Permission metadata lookup
    const permMeta = this.permissions.get(action);
    if (!permMeta) {
      throw createError(`FORBIDDEN: Unknown permission action ${action}`, 403);
    }

    // 4. Level 5 Sovereign mobile execution block (Section 8)
    if (permMeta.riskLevel === RISK_LEVELS.SOVEREIGN && channel === 'MOBILE_ADMIN_APP' && !permMeta.mobileExecutable) {
      throw createError('FORBIDDEN: Level 5 Sovereign actions cannot be executed directly from mobile; submit an approval/infrastructure request', 403);
    }

    // 5. Evaluate RBAC/ABAC/ReBAC + Deny-by-Default
    const evalResult = this.hasPermissionRaw(actor, action, scope);
    if (!evalResult.allowed) {
      this.auditService.record({
        actorId: actor.id,
        action,
        permissionUsed: action,
        resourceType: scope?.type || 'GLOBAL',
        targetId: resource?.id || scope?.resourceId || null,
        sessionId: session.id,
        result: 'DENIED',
        reason: reason || 'Missing or out-of-scope permission',
      });
      throw createError(`FORBIDDEN: Permission denied for ${action}`, 403);
    }

    // 6. Enforce security requirements (MFA, reason, financial limits, approval)
    const cond = evalResult.conditions || {};
    const requiresMfa = permMeta.requiresMfa || cond.requireMfa || permMeta.riskLevel >= RISK_LEVELS.CRITICAL_FINANCIAL_SECURITY;
    if (requiresMfa && !session.mfaVerified) {
      throw createError('FORBIDDEN: MFA re-authentication required for this sensitive operation', 403);
    }

    const requiresReason = permMeta.requiresReason || cond.requireReason;
    if (requiresReason && (!reason || String(reason).trim().length < 3)) {
      throw createError('BAD_REQUEST: A clear reason is required for this administrative operation', 400);
    }

    if (amount !== null && amount !== undefined) {
      const numericAmount = Number(amount);
      if (!Number.isFinite(numericAmount) || numericAmount <= 0) {
        throw createError('BAD_REQUEST: Invalid positive financial amount required', 400);
      }
      if (cond.maxAmountPerOperation && numericAmount > cond.maxAmountPerOperation) {
        throw createError(`FORBIDDEN: Amount exceeds per-operation limit (${cond.maxAmountPerOperation})`, 403);
      }
      if (cond.maxAmountPerDay) {
        const dayKey = `${actor.id}:${action}:${new Date().toISOString().slice(0, 10)}`;
        const used = this.dailyUsage.get(dayKey)?.amount || 0;
        if (used + numericAmount > cond.maxAmountPerDay) {
          throw createError(`FORBIDDEN: Amount exceeds daily limit (${cond.maxAmountPerDay})`, 403);
        }
      }
    }

    const requiresApproval = permMeta.requiresApproval || cond.requireApproval;
    if (requiresApproval) {
      if (!approval || approval.status !== 'APPROVED') {
        throw createError('FORBIDDEN: Independent administrative approval is required before execution', 403);
      }
      if (approval.requesterId === actor.id && approval.approvers?.includes(actor.id)) {
        throw createError('FORBIDDEN: Self-approval is strictly prohibited', 403);
      }
    }

    return {
      allowed: true,
      riskLevel: permMeta.riskLevel,
      permission: permMeta,
      conditions: cond,
    };
  }
}
