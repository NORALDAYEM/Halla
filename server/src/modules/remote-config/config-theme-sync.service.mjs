import crypto from 'node:crypto';

function createError(message, statusCode) {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
}

const HEX_COLOR_RE = /^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/;

export function validateThemePayload(payload) {
  if (!payload || typeof payload !== 'object') {
    throw createError('BAD_REQUEST: Theme payload must be a JSON object', 400);
  }
  if (!payload.colors || typeof payload.colors !== 'object') {
    throw createError('BAD_REQUEST: Theme colors section is required', 400);
  }
  for (const key of ['primary', 'secondary', 'background', 'textPrimary']) {
    if (!HEX_COLOR_RE.test(String(payload.colors[key] || ''))) {
      throw createError(`BAD_REQUEST: Invalid hex color for colors.${key}`, 400);
    }
  }
  if (payload.buttons) {
    const { opacity, borderRadius, height } = payload.buttons;
    if (opacity !== undefined && (opacity < 0.2 || opacity > 1)) {
      throw createError('BAD_REQUEST: buttons.opacity must be between 0.2 and 1.0', 400);
    }
    if (borderRadius !== undefined && (borderRadius < 0 || borderRadius > 40)) {
      throw createError('BAD_REQUEST: buttons.borderRadius must be between 0 and 40', 400);
    }
    if (height !== undefined && (height < 32 || height > 72)) {
      throw createError('BAD_REQUEST: buttons.height must be between 32 and 72', 400);
    }
  }
  if (payload.animations?.durationMs !== undefined) {
    const d = payload.animations.durationMs;
    if (d < 0 || d > 1500) {
      throw createError('BAD_REQUEST: animations.durationMs must be between 0 and 1500', 400);
    }
  }
}

/**
 * Combined Remote Config, Feature Flags, Dynamic Theme Engine, Emergency Control,
 * and Versioned Real-Time Sync Outbox (Sections 12, 13, 14, 20, 22, 23, 33, 34).
 */
export class CentralControlSyncService {
  constructor({ accessControl, auditService }) {
    this.accessControl = accessControl;
    this.auditService = auditService;

    this.globalVersion = 1;
    this.configVersions = [
      {
        version: 1,
        value: {
          maintenanceMode: false,
          minAppVersion: '3.1.5',
          features: {
            voiceRooms: true,
            privateChat: true,
            guestLogin: true,
            gifts: true,
            vip: true,
            agencies: true,
            games: {
              ludo: true,
              billiards: true,
              chess: true,
              domino: true,
              tarneeb: true,
            },
          },
        },
        createdAt: new Date().toISOString(),
      },
    ];

    this.themes = new Map();
    this.themes.set('halaa_default', {
      themeId: 'halaa_default',
      status: 'PUBLISHED',
      currentVersion: 1,
      versions: [
        {
          version: 1,
          status: 'PUBLISHED',
          payload: {
            colors: {
              primary: '#118B97',
              secondary: '#54649F',
              background: '#101426',
              textPrimary: '#FFFFFF',
            },
            buttons: { opacity: 0.9, borderRadius: 16, height: 46 },
            animations: { enabled: true, durationMs: 200 },
          },
          createdAt: new Date().toISOString(),
        },
      ],
    });

    this.emergencyActions = new Map(); // actionKey -> { active, scope, reason, expiresAt }
    this.syncEvents = [];
    this.acknowledgments = new Map(); // eventId -> Map<deviceId, ack>
    this.listeners = new Set();       // active SSE/realtime subscribers
  }

  _emitSyncEvent({ event, resourceId, scope = 'GLOBAL', targetId = null }) {
    this.globalVersion += 1;
    const syncEvt = Object.freeze({
      eventId: `evt_${crypto.randomUUID()}`,
      event,
      resourceId,
      version: this.globalVersion,
      refreshRequired: true,
      scope,
      targetId,
      createdAt: new Date().toISOString(),
    });
    this.syncEvents.push(syncEvt);
    for (const listener of this.listeners) {
      try {
        listener(syncEvt);
      } catch {
        // Ignore broken subscriber stream
      }
    }
    return syncEvt;
  }

  subscribe(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  getCurrentConfig() {
    return this.configVersions[this.configVersions.length - 1];
  }

  getPublishedTheme(themeId = 'halaa_default') {
    const theme = this.themes.get(themeId);
    if (!theme) return null;
    const published = theme.versions.slice().reverse().find((v) => v.status === 'PUBLISHED');
    return published ? { themeId, version: published.version, status: published.status, ...published.payload } : null;
  }

  isFeatureEnabled(featurePath) {
    // Emergency kill-switch overrides config cleanly without crashing the app
    const emergency = this.emergencyActions.get(`disable.${featurePath}`);
    if (emergency && emergency.active) return false;

    const current = this.getCurrentConfig().value.features;
    const parts = String(featurePath).split('.');
    let node = current;
    for (const p of parts) {
      if (node === undefined || node === null) return false;
      node = node[p];
    }
    return Boolean(node);
  }

  updateConfig({ actor, session, patch, reason }) {
    this.accessControl.authorize({
      actor,
      session,
      action: 'config.update',
      reason,
    });

    const prev = this.getCurrentConfig();
    const nextValue = {
      ...prev.value,
      ...patch,
      features: {
        ...prev.value.features,
        ...(patch.features || {}),
        games: {
          ...prev.value.features.games,
          ...(patch.features?.games || {}),
        },
      },
    };
    const nextVersion = prev.version + 1;
    const entry = { version: nextVersion, value: nextValue, reason, createdAt: new Date().toISOString() };
    this.configVersions.push(entry);

    const syncEvt = this._emitSyncEvent({ event: 'config.updated', resourceId: 'app_config' });
    this.auditService.record({
      actorId: actor.id,
      action: 'config.update',
      permissionUsed: 'config.update',
      beforeVersion: prev.version,
      afterVersion: nextVersion,
      beforeValue: prev.value,
      afterValue: nextValue,
      reason,
      sessionId: session.id,
      result: 'SUCCESS',
    });

    return { config: entry, syncEvent: syncEvt };
  }

  rollbackConfig({ actor, session, targetVersion, reason }) {
    this.accessControl.authorize({
      actor,
      session,
      action: 'config.update',
      reason,
    });

    const target = this.configVersions.find((v) => v.version === Number(targetVersion));
    if (!target) throw createError(`NOT_FOUND: Config version ${targetVersion} not found`, 404);

    const prev = this.getCurrentConfig();
    const nextVersion = prev.version + 1;
    // Creates a brand-new documented version instead of deleting history (Section 33)
    const entry = {
      version: nextVersion,
      rolledBackFrom: prev.version,
      restoredVersion: target.version,
      value: structuredClone(target.value),
      reason,
      createdAt: new Date().toISOString(),
    };
    this.configVersions.push(entry);

    const syncEvt = this._emitSyncEvent({ event: 'config.updated', resourceId: 'app_config' });
    this.auditService.record({
      actorId: actor.id,
      action: 'config.rollback',
      permissionUsed: 'config.update',
      beforeVersion: prev.version,
      afterVersion: nextVersion,
      reason,
      sessionId: session.id,
      result: 'SUCCESS',
    });

    return { config: entry, syncEvent: syncEvt };
  }

  saveThemeDraft({ actor, session, themeId = 'halaa_default', payload, reason }) {
    this.accessControl.authorize({
      actor,
      session,
      action: 'themes.publish',
      reason,
    });
    validateThemePayload(payload);

    let theme = this.themes.get(themeId);
    if (!theme) {
      theme = { themeId, status: 'DRAFT', currentVersion: 0, versions: [] };
      this.themes.set(themeId, theme);
    }
    const nextVersion = theme.versions.length + 1;
    const draft = {
      version: nextVersion,
      status: 'DRAFT',
      payload,
      createdAt: new Date().toISOString(),
    };
    theme.versions.push(draft);
    // Draft is NOT published to users (Section 13)
    return draft;
  }

  publishTheme({ actor, session, themeId = 'halaa_default', version, reason }) {
    this.accessControl.authorize({
      actor,
      session,
      action: 'themes.publish',
      reason,
    });
    const theme = this.themes.get(themeId);
    if (!theme) throw createError('NOT_FOUND: Theme not found', 404);
    const target = theme.versions.find((v) => v.version === Number(version));
    if (!target) throw createError('NOT_FOUND: Theme version not found', 404);

    validateThemePayload(target.payload);
    target.status = 'PUBLISHED';
    theme.status = 'PUBLISHED';
    theme.currentVersion = target.version;

    const syncEvt = this._emitSyncEvent({ event: 'theme.updated', resourceId: themeId });
    this.auditService.record({
      actorId: actor.id,
      action: 'themes.publish',
      permissionUsed: 'themes.publish',
      targetId: themeId,
      afterVersion: target.version,
      reason,
      sessionId: session.id,
      result: 'SUCCESS',
    });
    return { theme: target, syncEvent: syncEvt };
  }

  setEmergencyAction({ actor, session, actionKey, active, reason, scope = 'GLOBAL' }) {
    this.accessControl.authorize({
      actor,
      session,
      action: 'emergency.control',
      reason,
    });
    const record = {
      actionKey,
      active: Boolean(active),
      scope,
      reason,
      updatedBy: actor.id,
      updatedAt: new Date().toISOString(),
    };
    this.emergencyActions.set(actionKey, record);
    const syncEvt = this._emitSyncEvent({ event: 'maintenance.updated', resourceId: actionKey, scope });
    this.auditService.record({
      actorId: actor.id,
      action: 'emergency.control',
      permissionUsed: 'emergency.control',
      targetId: actionKey,
      afterValue: record,
      reason,
      sessionId: session.id,
      result: 'SUCCESS',
    });
    return { emergency: record, syncEvent: syncEvt };
  }

  getMissedEvents(sinceVersion = 0) {
    const v = Number(sinceVersion) || 0;
    return this.syncEvents.filter((e) => e.version > v);
  }

  acknowledgeSync({ eventId, deviceId, appType = 'USER_APP', appliedVersion, status = 'ACK' }) {
    if (!this.acknowledgments.has(eventId)) {
      this.acknowledgments.set(eventId, new Map());
    }
    const ack = {
      eventId,
      deviceId,
      appType,
      appliedVersion,
      status,
      acknowledgedAt: new Date().toISOString(),
    };
    this.acknowledgments.get(eventId).set(deviceId, ack);
    return ack;
  }

  getSyncStatus() {
    const latestEvent = this.syncEvents[this.syncEvents.length - 1] || null;
    const latestAcks = latestEvent ? (this.acknowledgments.get(latestEvent.eventId)?.size || 0) : 0;
    return {
      globalVersion: this.globalVersion,
      configVersion: this.getCurrentConfig().version,
      themeVersion: this.getPublishedTheme()?.version || 1,
      connectedListeners: this.listeners.size,
      totalEventsEmitted: this.syncEvents.length,
      latestEventAcknowledgedDevices: latestAcks,
      activeEmergencies: Array.from(this.emergencyActions.values()).filter((e) => e.active),
    };
  }
}
