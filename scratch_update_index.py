import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('index.html', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update landing header nav
old_nav = '<a href="javascript:void(0)" onclick="openCampusMapModal()" class="nav-link" style="color:var(--blue);font-weight:700">🗺️ Карта кампуса</a>'
new_nav = '<a href="javascript:void(0)" onclick="openCampusMapModal()" class="nav-link" style="color:var(--blue);font-weight:700">🗺️ Карта кампуса</a>\n      <a href="javascript:void(0)" onclick="openStudentProfileModal()" class="nav-link" style="color:var(--dark);font-weight:600">👤 Студент Профилі</a>'

if old_nav in content and 'openStudentProfileModal' not in content[:content.find('</nav>')]:
    content = content.replace(old_nav, new_nav, 1)
    print("Updated landing header nav!")

# 2. Update pg-student app-nav
old_stu_nav = '<button class="anav-btn" onclick="openCampusMapModal()"><span style="font-size:15px">🗺️</span> Карта</button>'
new_stu_nav = '<button class="anav-btn" onclick="openCampusMapModal()"><span style="font-size:15px">🗺️</span> Карта</button>\n      <button class="anav-btn" onclick="openStudentProfileModal()"><span style="font-size:15px">👤</span> Профиль</button>'

if old_stu_nav in content:
    content = content.replace(old_stu_nav, new_stu_nav, 1)
    print("Updated pg-student nav!")

# 3. Add profile-modal-overlay before </body>
profile_modal_code = '''
<!-- ════════════════════════════════════════════
     AITU STUDENT DIGITAL ID & PROFILE MODAL (WEB EMBED)
════════════════════════════════════════════ -->
<div id="profile-modal-overlay" class="moverlay hide" style="z-index:99999;padding:0;">
  <div style="width:95vw;max-width:440px;height:92vh;background:#0F172A;border-radius:28px;border:1px solid rgba(255,255,255,0.12);overflow:hidden;display:flex;flex-direction:column;box-shadow:0 30px 80px rgba(0,0,0,0.85);">
    <div style="height:50px;background:#0E131D;display:flex;align-items:center;justify-content:space-between;padding:0 18px;border-bottom:1px solid rgba(255,255,255,0.08);flex-shrink:0;">
      <div style="display:flex;align-items:center;gap:10px;">
        <span style="background:#0062FF;color:#fff;font-weight:900;font-size:11px;padding:3px 8px;border-radius:6px;letter-spacing:0.05em;">DIGITAL ID</span>
        <strong style="color:#fff;font-size:13.5px;">Студент Профилі</strong>
      </div>
      <div style="display:flex;align-items:center;gap:10px;">
        <a href="/profile" target="_blank" class="btn btn-ghost sm" style="color:#38BDF8;border-color:rgba(56,189,248,0.4);font-size:11px;padding:4px 8px;">↗ Ашу</a>
        <button class="btn-proj-close" onclick="closeStudentProfileModal()" style="width:32px;height:32px;font-size:15px;color:#fff;cursor:pointer;">✕</button>
      </div>
    </div>
    <iframe id="profile-iframe" src="/profile" style="width:100%;flex:1;border:none;"></iframe>
  </div>
</div>

<script>
function openStudentProfileModal() {
  const modal = document.getElementById('profile-modal-overlay');
  const iframe = document.getElementById('profile-iframe');
  if (iframe) iframe.src = '/profile';
  if (modal) modal.classList.remove('hide');
}
function closeStudentProfileModal() {
  const modal = document.getElementById('profile-modal-overlay');
  if (modal) modal.classList.add('hide');
}
</script>
'''

if 'id="profile-modal-overlay"' not in content:
    idx_map_modal = content.rfind('</div>\n</div>\n\n<script>\nfunction openCampusMapModal')
    if idx_map_modal != -1:
        # insert right after closeCampusMapModal script
        end_script_idx = content.find('</script>', idx_map_modal) + 9
        content = content[:end_script_idx] + '\n' + profile_modal_code + '\n' + content[end_script_idx:]
        print("Added profile-modal-overlay!")
    else:
        # Fallback before </body>
        b_idx = content.rfind('</body>')
        content = content[:b_idx] + profile_modal_code + '\n' + content[b_idx:]
        print("Added profile-modal-overlay before </body>!")

with open('index.html', 'w', encoding='utf-8') as f:
    f.write(content)

print("index.html updated successfully!")
