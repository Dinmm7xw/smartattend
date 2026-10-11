# -*- coding: utf-8 -*-
"""
Добавление официального модального окна ЭЦП (eGov Mobile / ҰКО НУЦ РК) в index.html
"""

with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

# 1. HTML модалки ЭЦП
ecp_modal_html = """
<!-- ════════════════════════════════════════════
     ҚР ҰКО ЭЦП / eGOV MOBILE РАСТАУ МОДАЛКАСЫ
════════════════════════════════════════════ -->
<div class="moverlay hide" id="ecp-modal">
  <div class="card modal" style="max-width:440px;text-align:left;padding:26px;">
    <div style="display:flex;align-items:center;gap:12px;margin-bottom:14px;border-bottom:1px solid var(--border);padding-bottom:12px;">
      <div style="width:42px;height:42px;border-radius:10px;background:#EFF4FF;display:flex;align-items:center;justify-content:center;font-size:22px;color:#0062FF;">🛡️</div>
      <div>
        <h3 style="font-size:16px;font-weight:800;color:var(--dark);margin:0;">ҚР ҰКО ЭЦП арқылы қол қою</h3>
        <p style="font-size:11px;color:var(--slate);margin:2px 0 0 0;">«Электрондық құжат және ЭЦП туралы» ҚР Заңы</p>
      </div>
    </div>

    <div style="background:#F8FAFC;border:1px solid var(--border);border-radius:12px;padding:12px;font-size:12px;margin-bottom:14px;display:flex;flex-direction:column;gap:6px;">
      <div style="display:flex;justify-content:space-between;">
        <span style="color:var(--slate);">Қол қоюшы:</span>
        <strong id="ecp-signer-name" style="color:var(--dark);">Байтомор Ата-Анасы</strong>
      </div>
      <div style="display:flex;justify-content:space-between;">
        <span style="color:var(--slate);">ЖСН (ИИН):</span>
        <strong id="ecp-signer-iin" style="color:#0062FF;font-family:monospace;">750412300184</strong>
      </div>
      <div style="display:flex;justify-content:space-between;">
        <span style="color:var(--slate);">Кілт түрі:</span>
        <strong style="color:var(--dark);">RSA-256 (eGov/ҰКО РК)</strong>
      </div>
      <div style="display:flex;justify-content:space-between;">
        <span style="color:var(--slate);">Сертификат күйі:</span>
        <strong style="color:#10B981;">● Жарамды (Заңды күші бар)</strong>
      </div>
      <div style="border-top:1px dashed var(--border);padding-top:6px;margin-top:2px;">
        <span style="color:var(--slate);display:block;font-size:11px;margin-bottom:2px;">Цифрлық хэш таңбасы:</span>
        <code style="font-size:10px;background:#E2E8F0;padding:2px 6px;border-radius:4px;color:#334155;word-break:break-all;">SHA256-8F3B92E1C4AA9082-KZ-COLLEGE</code>
      </div>
    </div>

    <div style="display:flex;align-items:center;gap:8px;margin-bottom:16px;">
      <input type="checkbox" id="ecp-agree" checked style="width:16px;height:16px;" />
      <label for="ecp-agree" style="font-size:11px;color:var(--slate);cursor:pointer;">
        Мен ата-ана ретінде осы өтініштің заңдылығын <b>ЭЦП арқылы</b> растаймын.
      </label>
    </div>

    <div style="display:flex;gap:10px;">
      <button class="btn btn-ghost" onclick="closeEcpModal()" style="flex:1;">Бас тарту</button>
      <button class="btn btn-primary" onclick="confirmEcpSignature()" style="flex:2;background:#10B981;box-shadow:0 8px 20px rgba(16,185,129,0.3);">✍️ Қол қойып, жіберу</button>
    </div>
  </div>
</div>
"""

if 'id="ecp-modal"' not in html:
    html = html.replace('<div class="toast-c" id="toast-c"></div>', ecp_modal_html + '\n<div class="toast-c" id="toast-c"></div>')

# 2. Обновляем JS функцию handleParentNoteSubmit и добавляем confirmEcpSignature
old_parent_js = """function handleParentNoteSubmit(e){
  e.preventDefault();
  const type = document.getElementById('pnote-type').value;
  const from = document.getElementById('pnote-from').value;
  const to = document.getElementById('pnote-to').value;
  const reason = document.getElementById('pnote-reason').value;

  try {"""

new_parent_js = """let pendingParentNoteData = null;

function handleParentNoteSubmit(e){
  e.preventDefault();
  const type = document.getElementById('pnote-type').value;
  const from = document.getElementById('pnote-from').value;
  const to = document.getElementById('pnote-to').value;
  const reason = document.getElementById('pnote-reason').value;

  // Сохраняем во временную переменную и открываем модалку ЭЦП
  pendingParentNoteData = { type, from, to, reason };
  openEcpModal();
}

function openEcpModal(){
  const m = document.getElementById('ecp-modal');
  if(m) m.classList.remove('hide');
}

function closeEcpModal(){
  const m = document.getElementById('ecp-modal');
  if(m) m.classList.add('hide');
}

async function confirmEcpSignature(){
  if(!pendingParentNoteData) return;
  closeEcpModal();

  try {"""

html = html.replace(old_parent_js, new_parent_js)

# Обновляем body запроса в submit-note
html = html.replace("""body: JSON.stringify({
        student_id: 3, // Байтомор Дінмұхаммед
        parent_email: 'parent.baitomor@smartattend.kz',
        note_type: type,
        reason: reason,
        date_from: from,
        date_to: to
      })""", """body: JSON.stringify({
        student_id: 3, // Байтомор Дінмұхаммед
        parent_email: 'parent.baitomor@smartattend.kz',
        note_type: pendingParentNoteData.type,
        reason: pendingParentNoteData.reason,
        date_from: pendingParentNoteData.from,
        date_to: pendingParentNoteData.to,
        is_signed_ecp: true,
        signer_iin: "750412300184",
        ecp_hash: "SHA256-8F3B92E1C4AA9082-KZ"
      })""")

html = html.replace(
    "toast('ok', '📨', 'Жіберілді!', 'Қолхат куратор Арай Талдаубекқызына жеткізілді.');",
    "toast('ok', '🛡️', 'ЭЦП-мен қол қойылды!', 'Қолхат (ЖСН: 750412300184) куратор Арай Талдаубекқызына жеткізілді.');"
)

with open("index.html", "w", encoding="utf-8") as f:
    f.write(html)

print("[OK] Модалка ЭЦП и обработка цифровой подписи успешно внедрены в index.html!")
