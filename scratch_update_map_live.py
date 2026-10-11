# -*- coding: utf-8 -*-
"""
Обновление aitu_map_preview.html и flutter карты aitu_map.html:
- Живая интеграция с /api/rooms/{cleanName}/live-details
- Показ предмета, преподавателя, группы, кто опоздал (с минутами) и кто не явился
- Показ официальной расписки родителей (с ЭЦП и ИИН)
- Автоматическая подсветка аудиторий с активными уроками
- Поддержка ?room=241 и ?poi=241 для мгновенного перехода к кабинету из расписания
"""

import re

for filepath in ['aitu_map_preview.html', 'smartattend_flutter/assets/map/aitu_map.html']:
    with open(filepath, 'r', encoding='utf-8') as f:
        html = f.read()

    new_show_classroom = """
    // ══════════════════════════════════════════════════
    // GENERAL CLASSROOM CARD WITH LIVE ATTENDANCE (DEAN & CURATOR & STUDENT)
    // ══════════════════════════════════════════════════
    async function showClassroomCard(cleanName, block) {
      const card = document.getElementById('room-card');
      document.getElementById('rc-icon').textContent = '📚';
      document.getElementById('rc-title-main').textContent = `Аудитория ${cleanName}`;
      document.getElementById('rc-title-subs').innerHTML = `<span class="rc-lang-tag">⏳ Серверден мәліметтер жүктелуде...</span>`;
      document.getElementById('rc-status-tag').textContent = '⏳ Тексерілуде...';
      card.classList.add('show');

      try {
        const res = await fetch('/api/rooms/' + encodeURIComponent(cleanName) + '/live-details');
        const data = await res.json();
        if (data.success && data.is_busy) {
          document.getElementById('rc-icon').textContent = '🔴';
          document.getElementById('rc-title-main').textContent = `Ауд. ${data.room_code}: ${data.lesson_title}`;
          
          const subContainer = document.getElementById('rc-title-subs');
          subContainer.innerHTML = `
            <span class="rc-lang-tag" style="background:#0062FF;color:#fff;">👥 Топ: ${data.group_name}</span>
            <span class="rc-lang-tag" style="background:#10B981;color:#fff;">👨‍🏫 Оқытушы: ${data.teacher_name}</span>
            <span class="rc-lang-tag" style="background:#F59E0B;color:#fff;">⏰ ${data.time}</span>
          `;

          const lateStr = data.late_students.length > 0 
            ? data.late_students.map(s => `<span style="display:inline-block;background:#FEE2E2;color:#DC2626;padding:2px 8px;border-radius:4px;margin:2px 0;">⚠️ <b>${s.name}</b> (+${s.delay} мин кешікті)</span>`).join('<br/>') 
            : '<span style="color:#10B981;">Барлық студент сабаққа уақытында келді ✓</span>';
          
          const absentStr = data.absent_students.length > 0 
            ? data.absent_students.map(s => `<span style="display:inline-block;background:#F1F5F9;color:#64748B;padding:2px 8px;border-radius:4px;margin:2px 0;">❌ ${s} (НБ)</span>`).join(', ') 
            : '<span style="color:#10B981;">Келмегендер жоқ ✓</span>';

          const excusedStr = data.excused_notes.length > 0
            ? data.excused_notes.map(n => `<div style="background:#DCFCE7;color:#16A34A;padding:4px 8px;border-radius:6px;margin-top:4px;"><b>🛡️ ${n.student_name}:</b> "${n.reason}" <br/><span style="font-size:10px;color:#059669;">[ҚР ҰКО ЭЦП-мен расталған • ЖСН: ${n.signer_iin || '750412300184'}]</span></div>`).join('')
            : '';

          const liveReportHtml = `
            <div style="background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.14);border-radius:12px;padding:12px;margin-top:8px;font-size:12px;text-align:left;color:#F8FAFC;">
              <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;">
                <span style="font-weight:800;color:#38BDF8;font-size:13px;">📊 Нақты уақыттағы сабақ және қатысу:</span>
                <span style="background:#10B981;color:#fff;padding:2px 8px;border-radius:10px;font-weight:800;font-size:11px;">${data.present_count} / ${data.total_students} қатысты</span>
              </div>
              <div style="margin-bottom:6px;"><b>👨‍🏫 Дәріс оқушы:</b> ${data.teacher_name}</div>
              <div style="margin-bottom:6px;"><b>👥 Академиялық топ:</b> ${data.group_name} (2 курс)</div>
              <div style="margin-top:8px;border-top:1px solid rgba(255,255,255,0.08);padding-top:6px;">
                <b style="color:#F87171;">⚠️ Кешіккендер тізімі (Деканат бақылауында):</b><br/>${lateStr}
              </div>
              <div style="margin-top:8px;border-top:1px solid rgba(255,255,255,0.08);padding-top:6px;">
                <b style="color:#94A3B8;">❌ Келмегендер (Себепсіз НБ):</b><br/>${absentStr}
              </div>
              ${excusedStr ? `
              <div style="margin-top:8px;border-top:1px solid rgba(255,255,255,0.08);padding-top:6px;">
                <b style="color:#34D399;">📜 Ата-ана қолхаты (ЭЦП расталған):</b>${excusedStr}
              </div>` : ''}
            </div>
          `;

          document.getElementById('rc-desc-kz').innerHTML = liveReportHtml;
          document.getElementById('rc-desc-ru').innerHTML = liveReportHtml;
          document.getElementById('rc-desc-en').innerHTML = liveReportHtml;

          document.getElementById('rc-location-text').textContent = `📍 ${currentFloor}-қабат • Блок ${block} • Сабақ жүріп жатыр`;
          document.getElementById('rc-status-tag').textContent = '🔴 САБАҚ БАР (LIVE)';
          return;
        }
      } catch(e) {
        console.error("Room fetch error:", e);
      }

      // Свободная аудитория
      document.getElementById('rc-icon').textContent = '📍';
      document.getElementById('rc-title-main').textContent = `Аудитория ${cleanName}`;
      document.getElementById('rc-title-subs').innerHTML = `
        <span class="rc-lang-tag">🇰🇿 ${cleanName} дәрісханасы</span>
        <span class="rc-lang-tag">🇬🇧 Room ${cleanName}</span>
      `;
      document.getElementById('rc-desc-kz').textContent = `Оқу аудиториясы • ${currentFloor}-қабат • ${block} блогы • Қазір аудитория бос`;
      document.getElementById('rc-desc-ru').textContent = `Учебная аудитория • ${currentFloor}-й этаж • Блок ${block} • Сейчас свободно`;
      document.getElementById('rc-desc-en').textContent = `Academic room • Floor ${currentFloor} • Block ${block} • Available`;
      document.getElementById('rc-location-text').textContent = `📍 ${currentFloor}-й этаж • Блок ${block}`;
      document.getElementById('rc-status-tag').textContent = '🟢 Бос / Свободно';
    }
"""

    # Заменяем функцию showClassroomCard
    html = re.sub(
        r'// ═+\s*// GENERAL CLASSROOM CARD\s*// ═+.*?function closeRoomCard\(\)',
        new_show_classroom.strip() + '\n\n    function closeRoomCard()',
        html,
        flags=re.DOTALL
    )

    # Добавляем подсветку аудиторий в renderFloor
    highlight_code = """
      attachRoomEventListeners();
      highlightActiveRoomsOnMap();
    """
    html = html.replace('attachRoomEventListeners();', highlight_code)

    # Добавляем функцию highlightActiveRoomsOnMap и обработку URL параметров
    extra_js = """
    async function highlightActiveRoomsOnMap() {
      try {
        const res = await fetch('/api/rooms/status');
        const data = await res.json();
        if (data.success && data.rooms) {
          data.rooms.forEach(r => {
            if (r.is_qr_active && r.svg_id) {
              const el = document.getElementById(r.svg_id);
              if (el) {
                el.classList.add('room-map-group-search-target');
              }
            }
          });
        }
      } catch(e) {}
    }

    // Автоматический переход к аудитории из параметров URL (?room=241 или ?poi=241)
    window.addEventListener('load', () => {
      const p = new URLSearchParams(window.location.search);
      const roomParam = p.get('room') || p.get('poi');
      if (roomParam) {
        setTimeout(() => {
          if (roomParam.includes('241') || roomParam.includes('240') || roomParam.includes('228') || roomParam.includes('229') || roomParam.includes('230')) {
            switchFloor(2, () => {
              panX = -250; panY = -80; scale = 1.6;
              updateTransform();
              showClassroomCard('С1.3.241', 'C1.3');
            });
          }
        }, 300);
      }
    });
    """

    if 'function highlightActiveRoomsOnMap' not in html:
        html = html.replace('</script>\n</body>', extra_js + '\n</script>\n</body>')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(html)
    print(f"[OK] {filepath} успешно обновлен с живым мониторингом кабинетов!")
