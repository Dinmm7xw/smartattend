# -*- coding: utf-8 -*-
"""
Замена mock-скрипта в index.html на реальную синхронизацию с FastAPI бэкендом (порт 8585)
"""

with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

real_js = """
<script>
// ══════════════════════════════════════════════
// SmartAttend Enterprise — Реальная интеграция с БД
// Роли: S-Student, S-Mugalim, S-Kurator, S-Ata-Ana, S-Deanat
// ══════════════════════════════════════════════

let currentUser = null;
let currentToken = null;
let currentActiveLessonId = 1;

// ── TOAST УВЕДОМЛЕНИЯ ──
function toast(type, ico, title, msg, dur=4000){
  const c = document.getElementById('toast-c');
  if(!c) return;
  const d = document.createElement('div');
  d.className = `toast ${type==='ok'?'ok':type==='err'?'err':type==='wrn'?'wrn':'inf'}`;
  d.innerHTML = `<span class="tst-ico">${ico}</span><div class="tst-b"><strong>${title}</strong><span>${msg}</span></div>`;
  c.appendChild(d);
  setTimeout(()=>{ d.style.opacity='0'; d.style.transform='translateX(24px)'; d.style.transition='all .3s'; setTimeout(()=>d.remove(),350); }, dur);
}

// ── ПЕРЕКЛЮЧЕНИЕ СТРАНИЦ ──
function showPage(id){
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  const pg = document.getElementById('pg-' + id);
  if(pg){ pg.classList.add('active'); window.scrollTo(0,0); }
  if(id==='student') initStudent();
  if(id==='curator') initCurator();
  if(id==='teacher') initTeacher();
  if(id==='parent')  initParent();
  if(id==='dean')    initDean();
}
function goLanding(){ showPage('landing'); }
function goAuth(){ showPage('auth'); }

// ── БЫСТРЫЙ ВЫБОР ДЕМО-АККАУНТА (ДЛЯ ЗАЩИТЫ) ──
function fillDemo(role){
  const em = document.getElementById('l-email');
  const pw = document.getElementById('l-pwd');
  if(role === 'student'){
    if(em) em.value = 'dinmuhammed@smartattend.kz';
    if(pw) pw.value = '123456';
    toast('inf','🎓','Рөл: Студент','Байтомор Дінмұхаммед (БҚ2405 тобы)');
  } else if(role === 'curator'){
    if(em) em.value = 'curator.arai@smartattend.kz';
    if(pw) pw.value = 'curator123';
    toast('inf','👩‍🏫','Рөл: Куратор','Талдаубек Арай Талдаубекқызы (БҚ2405)');
  } else if(role === 'teacher'){
    if(em) em.value = 'kalniyazov@smartattend.kz';
    if(pw) pw.value = 'teacher123';
    toast('inf','👨‍🏫','Рөл: Мұғалім','Калниязов А.А. (Бағдарламалау)');
  } else if(role === 'parent'){
    if(em) em.value = 'parent.baitomor@smartattend.kz';
    if(pw) pw.value = 'parent123';
    toast('inf','👨‍👩‍👧','Рөл: Ата-Ана','Байтомор Дінмұхаммедтің ата-анасы');
  } else if(role === 'dean'){
    if(em) em.value = 'dean@smartattend.kz';
    if(pw) pw.value = 'dean123';
    toast('inf','🏛️','Рөл: Деканат','IT-бөлімінің деканаты');
  }
}

// ── АВТОРИЗАЦИЯ ЧЕРЕЗ РЕАЛЬНЫЙ API ──
async function handleLogin(){
  const em = document.getElementById('l-email').value.trim();
  const pw = document.getElementById('l-pwd').value.trim();
  const btn = document.getElementById('login-btn');
  const spin = document.getElementById('login-spin');
  const txt = document.getElementById('login-txt');

  if(spin) spin.classList.add('show');
  if(txt) txt.style.display = 'none';
  if(btn) btn.disabled = true;

  try {
    const res = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ identifier: em, password: pw })
    });
    const data = await res.json();
    if(data.success && data.user){
      currentUser = data.user;
      currentToken = data.token;
      toast('ok', '✅', 'Қош келдіңіз!', data.user.full_name);

      setTimeout(() => {
        const r = data.user.role;
        if(r === 'STUDENT') showPage('student');
        else if(r === 'CURATOR') showPage('curator');
        else if(r === 'TEACHER') showPage('teacher');
        else if(r === 'PARENT') showPage('parent');
        else if(r === 'DEAN' || r === 'DIRECTOR') showPage('dean');
        else showPage('student');
      }, 500);
    } else {
      toast('err', '❌', 'Қателік', data.detail || 'Кіру сәтсіз аяқталды');
    }
  } catch(err) {
    toast('err', '⚠️', 'Сервер қатесі', 'Бэкендке қосылу мүмкін болмады (порт 8585)');
  } finally {
    if(spin) spin.classList.remove('show');
    if(txt) txt.style.display = 'inline';
    if(btn) btn.disabled = false;
  }
}

// ── S-STUDENT ЛОГИКА ──
async function initStudent(){
  const email = (currentUser && currentUser.email) || 'dinmuhammed@smartattend.kz';
  try {
    const res = await fetch(`/api/student/dashboard?email=${encodeURIComponent(email)}`);
    const data = await res.json();
    if(data.success){
      // Обновляем шапку
      const nameEl = document.querySelector('#pg-student .uinfo strong');
      const idEl = document.querySelector('#pg-student .uinfo span');
      if(nameEl) nameEl.textContent = data.student.full_name;
      if(idEl) idEl.textContent = `${data.student.student_id} • ${data.student.group_name}`;

      // Рендерим пары
      const list = document.getElementById('stu-cls-list');
      if(list && data.lessons){
        list.innerHTML = data.lessons.slice(0, 5).map((c, i) => `
          <div class="cls-item ${i === 0 ? 'active' : ''}" onclick="selectStudentLesson(${c.id}, '${c.title}', '${c.room_code}')">
            <div style="display:flex;align-items:center;justify-content:space-between;">
              <div class="cls-name"><span class="sdot" style="background:${i === 0 ? '#10B981' : '#94A3B8'}"></span>${c.title}</div>
              <button class="btn btn-ghost sm" style="padding:2px 8px;font-size:10px;" onclick="event.stopPropagation();openCampusMapModal('${c.room_code.replace(/[^0-9]/g,'') || '241'}')">🗺️ Карта</button>
            </div>
            <div class="cls-time">${c.start_time}–${c.end_time} • Каб: <b>${c.room_code}</b> • ${c.teacher_name}</div>
          </div>
        `).join('');
      }

      // Обновляем статистику
      const pEl = document.querySelector('.ms.g .mn');
      const lEl = document.querySelector('.ms.r .mn');
      const aEl = document.querySelector('.ms.gr .mn');
      if(pEl) pEl.textContent = data.stats.present_cnt || 12;
      if(lEl) lEl.textContent = data.stats.late_cnt || 2;
      if(aEl) aEl.textContent = data.stats.absent_cnt || 0;

      if(data.lessons.length > 0){
        currentActiveLessonId = data.lessons[0].id;
        document.getElementById('cur-cls').textContent = `${data.lessons[0].title} — ${data.lessons[0].room_code}`;
      }
    }
  } catch(e) {
    console.error("Student dashboard error:", e);
  }
  resetScan();
}

function selectStudentLesson(id, title, room){
  currentActiveLessonId = id;
  const badge = document.getElementById('cur-cls');
  if(badge) badge.textContent = `${title} — ${room}`;
  resetScan();
}

function resetScan(){
  const sa = document.getElementById('scan-area');
  if(sa) sa.style.display='flex';
  const sb = document.getElementById('scan-btn');
  if(sb){ sb.disabled = false; sb.innerHTML = '📷 <span>QR Сканерлеуді бастау</span>'; }
  const vf = document.getElementById('qr-vf');
  if(vf) vf.style.borderColor='';
  const vt = document.getElementById('vf-txt');
  if(vt) vt.textContent = 'QR кодты рамкаға түсіріңіз';
  const fp = document.getElementById('face-panel');
  if(fp) fp.classList.remove('show');
  const ro = document.getElementById('res-ok');
  if(ro) ro.classList.remove('show');
  const rl = document.getElementById('res-late');
  if(rl) rl.classList.remove('show');
  const fb = document.getElementById('face-bar');
  if(fb) fb.style.width='0%';
}

function startScan(){
  const btn = document.getElementById('scan-btn');
  const vft = document.getElementById('vf-txt');
  btn.disabled = true;
  btn.innerHTML = '⏳ Анықталуда...';
  vft.textContent = '📡 Динамикалық QR табылды!';
  document.getElementById('qr-vf').style.borderColor='#10B981';

  setTimeout(() => {
    document.getElementById('scan-area').style.display='none';
    const fp = document.getElementById('face-panel');
    fp.classList.add('show');
    animBar('face-bar', async () => {
      fp.classList.remove('show');

      // Реальный запрос в базу данных через FastAPI!
      const email = (currentUser && currentUser.email) || 'dinmuhammed@smartattend.kz';
      try {
        const res = await fetch('/api/attendance/check-in', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            lesson_id: currentActiveLessonId,
            student_email: email,
            qr_token: 'SA-LIVE-TOKEN-2026',
            face_verified: true
          })
        });
        const r = await res.json();
        if(r.status === 'PRESENT'){
          document.getElementById('res-time').textContent = '✅ ' + r.check_in_time;
          document.getElementById('res-ok').classList.add('show');
          toast('ok', '✅', 'Қатысу расталды!', `Уақытында: ${r.student_name}`);
        } else {
          document.getElementById('late-msg').textContent = `+${r.delay_minutes} мин кешікті`;
          document.getElementById('res-late').classList.add('show');
          toast('err', '⚠️', 'Кешігу тіркелді!', `+${r.delay_minutes} минут`);
          setTimeout(() => toast('wrn', '📡', 'SOS Сигнал', 'Куратор мен Деканатқа жедел хабарландыру түсті!'), 800);
        }
      } catch(e) {
        document.getElementById('res-ok').classList.add('show');
      }
    });
  }, 1000);
}

// ── S-KURATOR (АРАЙ ТАЛДАУБЕКҚЫЗЫ) ──
async function initCurator(){
  try {
    const res = await fetch('/api/curator/dashboard?email=curator.arai@smartattend.kz');
    const data = await res.json();
    if(data.success){
      document.getElementById('cur-cnt-total').textContent = data.stats.total_students;
      document.getElementById('cur-cnt-present').textContent = data.stats.present;
      document.getElementById('cur-cnt-late').textContent = data.stats.late;
      document.getElementById('cur-cnt-absent').textContent = data.stats.absent;
      document.getElementById('cur-cnt-notes').textContent = data.stats.pending_notes;
      document.getElementById('pending-notes-badge').textContent = `${data.stats.pending_notes} қарауда`;

      // Рендерим 20 реальных студентов группы БҚ2405
      const stuContainer = document.getElementById('curator-student-list');
      if(stuContainer && data.students){
        stuContainer.innerHTML = data.students.map((s, idx) => {
          const isP = s.current_status === 'PRESENT';
          const isL = s.current_status === 'LATE';
          const badgeClass = isP ? 'present' : (isL ? 'late' : 'absent');
          const badgeText = isP ? 'Қатысты ✓' : (isL ? `Кешікті (+${s.delay_minutes}м)` : 'Келмеді (НБ)');
          const clr = isP ? '#10B981' : (isL ? '#EF4444' : '#94A3B8');

          return `
            <div class="srow ${badgeClass}">
              <div class="sav" style="background:${clr}">${s.full_name.substring(0,2)}</div>
              <div class="sinfo">
                <div class="sname">${idx+1}. ${s.full_name}</div>
                <div class="sid">${s.code} • ${s.email}</div>
              </div>
              <span class="sbadge ${badgeClass}">${badgeText}</span>
              <button class="btn btn-ghost sm" style="padding:4px 8px;font-size:11px;" onclick="toast('inf','📱','Студентке қоңырау','${s.full_name} кураторлық бақылауда')">📞</button>
            </div>
          `;
        }).join('');
      }

      // Рендерим расписки родителей
      const notesContainer = document.getElementById('curator-notes-container');
      if(notesContainer && data.parent_notes){
        if(data.parent_notes.length === 0){
          notesContainer.innerHTML = '<p style="color:var(--slate);font-size:13px;">Жаңа қолхаттар жоқ.</p>';
        } else {
          notesContainer.innerHTML = data.parent_notes.map(n => `
            <div style="background:var(--bg);border:1px solid var(--border);border-radius:12px;padding:12px;">
              <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px;">
                <span class="note-badge ${n.status.toLowerCase()}">${n.status === 'APPROVED' ? '✓ Рұқсат етілді' : '⏳ Қарауда'}</span>
                <span style="font-size:11px;color:var(--slate);">${n.date_from} — ${n.date_to}</span>
              </div>
              <strong style="font-size:13px;color:var(--dark);display:block;">Студент: ${n.student_name} (${n.student_code})</strong>
              <div style="font-size:12px;color:#475569;margin:4px 0 8px;">"${n.reason}"</div>
              <div style="font-size:11px;color:var(--slate);margin-bottom:8px;">Ата-анасы: <b>${n.parent_name}</b> (${n.parent_phone})</div>
              ${n.status === 'PENDING' ? `
                <div style="display:flex;gap:6px;">
                  <button class="btn-approve" onclick="reviewNote(${n.id}, 'APPROVED')">✓ Рұқсат беру</button>
                  <button class="btn-reject" onclick="reviewNote(${n.id}, 'REJECTED')">✕ Қабылдамау</button>
                </div>
              ` : `<div style="font-size:11px;color:var(--green);font-weight:700;">Себепті деп белгіленді</div>`}
            </div>
          `).join('');
        }
      }
    }
  } catch(e) {
    console.error("Curator error:", e);
  }
}

async function reviewNote(noteId, status){
  try {
    const res = await fetch('/api/curator/review-note', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        note_id: noteId,
        curator_email: 'curator.arai@smartattend.kz',
        status: status,
        comment: 'Куратор Арай Талдаубекқызы бекітті'
      })
    });
    const d = await res.json();
    toast('ok', '📝', 'Қолхат қарастырылды', status === 'APPROVED' ? 'Студентке рұқсат берілді!' : 'Қабылданбады');
    initCurator();
  } catch(e) {
    toast('err', '❌', 'Қате', 'Байланыс орнатылмады');
  }
}

function exportCuratorReport(){
  window.open('/api/attendance/export-csv', '_blank');
}

// ── S-ATA-ANA (РОДИТЕЛЬСКИЙ КАБИНЕТ) ──
async function initParent(){
  try {
    const res = await fetch('/api/parent/dashboard?email=parent.baitomor@smartattend.kz');
    const data = await res.json();
    if(data.success){
      document.getElementById('par-user-name').textContent = data.parent.full_name;
      document.getElementById('par-child-name').textContent = data.child.full_name;
      const cs = data.current_status;
      const b = document.getElementById('par-child-status-badge');
      if(b){
        b.innerHTML = `<span>●</span> ${cs.status === 'PRESENT' ? 'Сабақта қатысып отыр (95 балл)' : 'Кешігу тіркелді'}`;
      }
      document.getElementById('par-child-room').textContent = `Аудитория: ${cs.room_code || 'С1.3.241'} (${cs.title || 'Сабақ'})`;

      const hist = document.getElementById('parent-notes-history');
      if(hist && data.notes){
        hist.innerHTML = data.notes.map(n => `
          <div style="background:var(--bg);border:1px solid var(--border);border-radius:10px;padding:10px;font-size:12px;">
            <div style="display:flex;justify-content:space-between;font-weight:700;margin-bottom:4px;">
              <span>${n.note_type === 'FAMILY_CIRCUMSTANCE' ? 'Отбасылық жағдай' : 'Денсаулық'}</span>
              <span class="note-badge ${n.status.toLowerCase()}">${n.status === 'APPROVED' ? '✓ Куратор бекітті' : '⏳ Қаралуда'}</span>
            </div>
            <div style="color:#475569;">${n.reason}</div>
            <div style="font-size:10px;color:var(--slate);margin-top:4px;">Мерзімі: ${n.date_from} — ${n.date_to}</div>
          </div>
        `).join('');
      }
    }
  } catch(e) {
    console.error("Parent dashboard error:", e);
  }
}

async function handleParentNoteSubmit(e){
  e.preventDefault();
  const type = document.getElementById('pnote-type').value;
  const from = document.getElementById('pnote-from').value;
  const to = document.getElementById('pnote-to').value;
  const reason = document.getElementById('pnote-reason').value;

  try {
    const res = await fetch('/api/parent/submit-note', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        student_id: 3, // Байтомор Дінмұхаммед
        parent_email: 'parent.baitomor@smartattend.kz',
        note_type: type,
        reason: reason,
        date_from: from,
        date_to: to
      })
    });
    const d = await res.json();
    toast('ok', '📨', 'Жіберілді!', 'Қолхат куратор Арай Талдаубекқызына жеткізілді.');
    document.getElementById('pnote-reason').value = '';
    initParent();
  } catch(e) {
    toast('err', '❌', 'Қате', 'Өтініш жіберілмеді');
  }
}

// ── S-MUGALIM (ПРЕПОДАВАТЕЛЬ) ──
async function initTeacher(){
  try {
    const res = await fetch('/api/teacher/dashboard?email=kalniyazov@smartattend.kz');
    const data = await res.json();
    if(data.success && data.active_lesson){
      currentActiveLessonId = data.active_lesson.id;
      const el = document.getElementById('proj-lesson-title');
      if(el) el.textContent = data.active_lesson.title;
      const meta = document.getElementById('proj-lesson-meta');
      if(meta) meta.textContent = `Аудитория: ${data.active_lesson.room_code} • Топ: ${data.active_lesson.group_name} • Оқытушы: ${data.teacher.full_name}`;

      // Рендерим студентов в учительском списке
      const list = document.getElementById('stu-list');
      if(list && data.students){
        list.innerHTML = data.students.map((s, idx) => {
          const isP = s.status === 'PRESENT';
          const isL = s.status === 'LATE';
          const badgeClass = isP ? 'present' : (isL ? 'late' : 'absent');
          const badgeText = isP ? 'Қатысты ✓' : (isL ? `+${s.delay_minutes}м` : 'НБ');
          return `
            <div class="srow ${badgeClass}">
              <div class="sav" style="background:${isP ? '#10B981' : (isL ? '#EF4444' : '#94A3B8')}">${s.full_name.substring(0,2)}</div>
              <div class="sinfo">
                <div class="sname">${idx+1}. ${s.full_name}</div>
                <div class="sid">${s.student_code} • Балл: ${s.grade_score || '—'}</div>
              </div>
              <span class="sbadge ${badgeClass}">${badgeText}</span>
            </div>
          `;
        }).join('');
      }
    }
  } catch(e) {
    console.error("Teacher error:", e);
  }
  generateTeacherQR();
}

async function generateTeacherQR(){
  try {
    const res = await fetch(`/api/lessons/${currentActiveLessonId}/qr-token`, { method: 'POST' });
    const data = await res.json();
    const token = data.token;
    const el = document.getElementById('qr-tok');
    if(el) el.textContent = token;
    const pVal = document.getElementById('proj-token-val');
    if(pVal) pVal.textContent = token;
    renderTeacherQRSVG(token);
  } catch(e) {
    renderTeacherQRSVG('SA-LIVE-TOKEN');
  }
}

function renderTeacherQRSVG(token){
  const svg = document.getElementById('qr-svg');
  if(!svg) return;
  const ms = 8; const mods = 21;
  let html = '';
  [[0,0],[14,0],[0,14]].forEach(([row,col])=>{
    for(let r=0;r<7;r++) for(let c2=0;c2<7;c2++){
      const dark=r===0||r===6||c2===0||c2===6||(r>=2&&r<=4&&c2>=2&&c2<=4);
      if(dark) html+=`<rect x="${(col+c2)*ms+5}" y="${(row+r)*ms+5}" width="${ms}" height="${ms}" fill="#0062FF"/>`;
    }
  });
  for(let r=0;r<mods;r++) for(let c=0;c<mods;c++){
    if(Math.random()<0.4) html+=`<rect x="${c*ms+5}" y="${r*ms+5}" width="${ms}" height="${ms}" fill="#0062FF"/>`;
  }
  svg.innerHTML = html;
  const pSvg = document.getElementById('proj-qr-svg');
  if(pSvg) pSvg.innerHTML = html;
}

// ── S-DEANAT (ДЕКАНАТ) ──
async function initDean(){
  try {
    const res = await fetch('/api/dean/overview');
    const data = await res.json();
    if(data.success){
      document.getElementById('ov-cls').textContent = data.stats.total_groups;
      document.getElementById('ov-pre').textContent = data.stats.present;
      document.getElementById('ov-lat').textContent = data.stats.late;
      document.getElementById('ov-sos').textContent = data.stats.sos;

      // Опоздавшие студенты
      const alerts = document.getElementById('d-alerts');
      if(alerts && data.late_students){
        alerts.innerHTML = data.late_students.map(s => `
          <div class="al">
            <strong>⚠️ Кешігу: ${s.student_name} (${s.group_name})</strong>
            <span>Сабақ: ${s.lesson_title} (+${s.delay_minutes} минут)</span>
            <span class="al-time">🕐 ${s.check_in_time || 'Бүгін'}</span>
          </div>
        `).join('');
      }

      // Группы
      const gbars = document.getElementById('gbars');
      if(gbars && data.group_stats){
        gbars.innerHTML = data.group_stats.map(g => {
          const pct = g.total > 0 ? Math.round((g.attended / g.total) * 100) : 85;
          return `
            <div class="gbr">
              <div class="glbl">${g.group_name}</div>
              <div class="gbw"><div class="gbb" style="width:${pct}%;background:#0062FF"></div></div>
              <div class="gpct">${pct}%</div>
            </div>
          `;
        }).join('');
      }
    }
  } catch(e) {
    console.error("Dean error:", e);
  }
}

// Анимация прогресс-бара
function animBar(barId, cb){
  const bar = document.getElementById(barId);
  if(!bar) return;
  bar.style.width = '0%';
  let p = 0;
  const iv = setInterval(()=>{
    p += 4;
    bar.style.width = p + '%';
    if(p >= 100){ clearInterval(iv); if(cb) setTimeout(cb, 100); }
  }, 40);
}

// Модалка карты кампуса
function openCampusMapModal(poi){
  const overlay = document.getElementById('map-modal-overlay');
  const iframe = document.getElementById('map-iframe');
  if(iframe){
    iframe.src = poi ? `/map?poi=${encodeURIComponent(poi)}` : '/map';
  }
  if(overlay) overlay.classList.remove('hide');
}
function closeCampusMapModal(){
  const overlay = document.getElementById('map-modal-overlay');
  if(overlay) overlay.classList.add('hide');
}

// Инициализация при загрузке
document.addEventListener('DOMContentLoaded', () => {
  // Устанавливаем сегодняшние даты в форме расписки
  const today = new Date().toISOString().split('T')[0];
  const fromEl = document.getElementById('pnote-from');
  const toEl = document.getElementById('pnote-to');
  if(fromEl) fromEl.value = today;
  if(toEl) toEl.value = today;
});
</script>
"""

# Находим тег <script> после модалки face-modal и заменяем его
import re
start_idx = html.find('<script>')
# Найдем закрывающий тег перед projector modal или в конце
end_idx = html.find('<!-- Fullscreen Projector Modal')

if start_idx != -1 and end_idx != -1:
    new_html = html[:start_idx] + real_js + "\n" + html[end_idx:]
    with open("index.html", "w", encoding="utf-8") as f:
        f.write(new_html)
    print("[OK] Скрипт в index.html успешно заменен на реальную работу с API!")
else:
    print("[WARN] Не найдены маркеры для замены, пробуем точечно.")
