(() => {
  const STORAGE_KEY = 'halla.support.tickets.v1';

  const STATUS_LABELS = {
    open: 'قيد المراجعة',
    in_progress: 'قيد المعالجة',
    resolved: 'تم الحل',
    closed: 'مغلقة'
  };

  function readTickets() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      const parsed = raw ? JSON.parse(raw) : [];
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }

  function writeTickets(list) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
    } catch {}
  }

  function generateTicketId(existing) {
    const used = new Set(existing.map(t => t.id));
    for (let i = 0; i < 20; i++) {
      const num = Math.floor(100000 + Math.random() * 900000);
      const id = 'HLA-' + num;
      if (!used.has(id)) return id;
    }
    return 'HLA-' + Date.now().toString().slice(-6);
  }

  function formatDate(iso) {
    try {
      return new Intl.DateTimeFormat('ar-SA', {
        dateStyle: 'medium',
        timeStyle: 'short'
      }).format(new Date(iso));
    } catch {
      return iso;
    }
  }

  const HallaSupport = {
    createTicket({ reason, contact = '', details = '' }) {
      const tickets = readTickets();
      const now = new Date().toISOString();
      const ticket = {
        id: generateTicketId(tickets),
        reason: String(reason || '').trim(),
        contact: String(contact || '').trim(),
        details: String(details || '').trim(),
        status: 'open',
        reply: '',
        createdAt: now,
        updatedAt: now
      };
      tickets.unshift(ticket);
      writeTickets(tickets);
      window.dispatchEvent(new CustomEvent('halla:ticket-created', { detail: ticket }));
      return ticket;
    },
    getTicket(ticketId) {
      const clean = String(ticketId || '').trim().toUpperCase();
      if (!clean) return null;
      return readTickets().find(t => t.id.toUpperCase() === clean) || null;
    },
    listTickets() {
      return readTickets();
    },
    updateTicket(ticketId, { status, reply } = {}) {
      const tickets = readTickets();
      const clean = String(ticketId || '').trim().toUpperCase();
      const idx = tickets.findIndex(t => t.id.toUpperCase() === clean);
      if (idx === -1) return null;
      if (status && STATUS_LABELS[status]) tickets[idx].status = status;
      if (typeof reply === 'string') tickets[idx].reply = reply.trim();
      tickets[idx].updatedAt = new Date().toISOString();
      writeTickets(tickets);
      window.dispatchEvent(new CustomEvent('halla:ticket-updated', { detail: tickets[idx] }));
      return tickets[idx];
    }
  };
  window.HallaSupport = HallaSupport;

  document.addEventListener('DOMContentLoaded', () => {
    const dialog = document.getElementById('help');
    if (!dialog) return;

    const helpBtn = document.querySelector('.help');
    if (helpBtn) {
      helpBtn.onclick = () => {
        if (!dialog.open) dialog.showModal();
      };
    }

    const closeBtn = dialog.querySelector('.help-close');
    if (closeBtn) closeBtn.onclick = () => dialog.close();

    const tabBtns = Array.from(dialog.querySelectorAll('[data-help-tab]'));
    const panels = Array.from(dialog.querySelectorAll('[data-help-panel]'));
    const form = dialog.querySelector('#support-ticket-form');
    const reasonEl = dialog.querySelector('#ticket-reason');
    const contactEl = dialog.querySelector('#ticket-contact');
    const detailsEl = dialog.querySelector('#ticket-details');
    const formErrorEl = dialog.querySelector('#ticket-form-error');
    const createdBox = dialog.querySelector('#ticket-created-box');
    const createdIdEl = dialog.querySelector('#ticket-created-id');
    const copyIdBtn = dialog.querySelector('#ticket-copy-id');
    const goTrackBtn = dialog.querySelector('#ticket-go-track');

    const trackForm = dialog.querySelector('#ticket-track-form');
    const trackInput = dialog.querySelector('#ticket-track-input');
    const trackResult = dialog.querySelector('#ticket-track-result');
    const recentList = dialog.querySelector('#ticket-recent-list');

    function switchTab(name) {
      tabBtns.forEach(btn => {
        const active = btn.dataset.helpTab === name;
        btn.classList.toggle('active', active);
        btn.setAttribute('aria-selected', active ? 'true' : 'false');
      });
      panels.forEach(p => {
        p.hidden = p.dataset.helpPanel !== name;
      });
      if (name === 'track') renderRecent();
    }

    tabBtns.forEach(btn => {
      btn.addEventListener('click', () => switchTab(btn.dataset.helpTab));
    });

    function renderTicketCard(ticket) {
      if (!ticket) {
        trackResult.innerHTML = '<div class="ticket-empty">لم يتم العثور على تذكرة بهذا الرقم. تأكد من كتابة الرقم بشكل صحيح (مثال: HLA-123456).</div>';
        return;
      }
      const statusText = STATUS_LABELS[ticket.status] || STATUS_LABELS.open;
      const safe = (str) => String(str || '').replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
      const replyHtml = ticket.reply
        ? `<div class="ticket-reply"><strong>رد الدعم الفني:</strong><p>${safe(ticket.reply)}</p></div>`
        : '<div class="ticket-reply pending">تم استلام البلاغ وسيقوم فريق الدعم الفني بالرد والمتابعة قريباً.</div>';

      trackResult.innerHTML = `
        <div class="ticket-card">
          <div class="ticket-card-head">
            <span class="ticket-id-badge" dir="ltr">${safe(ticket.id)}</span>
            <span class="ticket-status status-${safe(ticket.status)}">${safe(statusText)}</span>
          </div>
          <div class="ticket-meta"><strong>سبب المشكلة:</strong> ${safe(ticket.reason)}</div>
          ${ticket.contact ? `<div class="ticket-meta"><strong>بيانات التواصل:</strong> ${safe(ticket.contact)}</div>` : ''}
          ${ticket.details ? `<div class="ticket-meta"><strong>التفاصيل:</strong> ${safe(ticket.details)}</div>` : ''}
          <div class="ticket-dates">تاريخ الرفع: ${safe(formatDate(ticket.createdAt))}</div>
          ${replyHtml}
        </div>
      `;
    }

    function renderRecent() {
      if (!recentList) return;
      const list = HallaSupport.listTickets().slice(0, 5);
      if (!list.length) {
        recentList.innerHTML = '';
        return;
      }
      recentList.innerHTML = '<div class="recent-title">تذاكرك السابقة على هذا الجهاز:</div>' +
        list.map(t => `<button type="button" class="recent-chip" data-ticket-id="${t.id}" dir="ltr">${t.id}</button>`).join('');
      recentList.querySelectorAll('.recent-chip').forEach(chip => {
        chip.addEventListener('click', () => {
          trackInput.value = chip.dataset.ticketId;
          renderTicketCard(HallaSupport.getTicket(chip.dataset.ticketId));
        });
      });
    }

    if (form) {
      form.addEventListener('submit', (e) => {
        e.preventDefault();
        if (formErrorEl) formErrorEl.textContent = '';
        const reason = reasonEl.value.trim();
        const contact = contactEl.value.trim();
        const details = detailsEl.value.trim();
        if (!reason) {
          if (formErrorEl) formErrorEl.textContent = 'يرجى اختيار سبب المشكلة من القائمة.';
          reasonEl.focus();
          return;
        }
        if (!details && !contact) {
          if (formErrorEl) formErrorEl.textContent = 'يرجى كتابة تفاصيل المشكلة أو بيانات الحساب للمتابعة.';
          detailsEl.focus();
          return;
        }
        const ticket = HallaSupport.createTicket({ reason, contact, details });
        createdIdEl.textContent = ticket.id;
        createdBox.hidden = false;
        form.reset();
        if (copyIdBtn) copyIdBtn.textContent = 'نسخ الرقم';
      });
    }

    if (copyIdBtn) {
      copyIdBtn.addEventListener('click', async () => {
        const id = createdIdEl.textContent.trim();
        if (!id) return;
        try {
          await navigator.clipboard.writeText(id);
          copyIdBtn.textContent = 'تم النسخ ✓';
        } catch {
          copyIdBtn.textContent = id;
        }
      });
    }

    if (goTrackBtn) {
      goTrackBtn.addEventListener('click', () => {
        const id = createdIdEl.textContent.trim();
        switchTab('track');
        if (id) {
          trackInput.value = id;
          renderTicketCard(HallaSupport.getTicket(id));
        }
      });
    }

    if (trackForm) {
      trackForm.addEventListener('submit', (e) => {
        e.preventDefault();
        renderTicketCard(HallaSupport.getTicket(trackInput.value));
      });
    }

    window.addEventListener('storage', (e) => {
      if (e.key === STORAGE_KEY && !dialog.querySelector('[data-help-panel="track"]').hidden) {
        renderRecent();
        if (trackInput.value.trim()) renderTicketCard(HallaSupport.getTicket(trackInput.value));
      }
    });
  });
})();
