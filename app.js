/* ═══════════════════════════════════════════════════
   SmartAttend — JavaScript Business Logic
   ═══════════════════════════════════════════════════ */

'use strict';

// ══════════════════════════════════════════════════
// I18N — Translations (KK / RU / EN)
// ══════════════════════════════════════════════════
const i18n = {
  kk: {
    try_free: 'Тегін сынап көру',
    back: 'Артқа',
    nav_about: 'Жүйе туралы',
    nav_features: 'Мүмкіндіктер',
    nav_pricing: 'Тариф',
    nav_contact: 'Байланыс',
    login: 'Кіру',
    register: 'Тіркелу',
    badge_live: 'Жүйе белсенді',
    hero_title: 'Ақылды Қатысу Жүйесі',
    hero_sub: 'QR + Face ID + Жедел хабарлама',
    stat_qr: 'QR жаңарту',
    stat_late: 'Кешігу шегі',
    stat_lang: 'Тіл қолдауы',
    role_student: '🎓 Студент',
    role_teacher: '👨‍🏫 Мұғалім',
    role_dean: '🏛️ Деканат',
    get_started: 'Жүйеге кіру →',
    demo_note: 'Демо режим — нақты деректерсіз сынауға болады',
    feat_qr: 'Динамикалық QR',
    feat_face: 'Face ID биометрия',
    feat_notif: 'Жедел хабарлама',
    feat_stat: 'Нақты уақыт статистика',
    feat_dean: 'Деканат бақылауы',
    email: 'Электрондық пошта',
    password: 'Құпия сөз',
    remember: 'Есте сақта',
    forgot: 'Құпия сөзді ұмыттым',
    select_role: 'Рөліңізді таңдаңыз',
    login_btn: 'Жүйеге кіру',
    or: 'немесе',
    face_login: 'Face ID арқылы кіру',
    auth_title: 'SmartAttend жүйесіне кіру',
    reg_title: 'Жаңа аккаунт жасау',
    fullname: 'Толық аты-жөні',
    student_id: 'Студент ID',
    create_account: 'Аккаунт жасау',
    deco_secure: 'Қауіпсіз жүйе',
    deco_encrypt: 'AES-256 шифрлау',
    deco_face: 'Face ID',
    deco_biometric: 'Биометриялық тексеру',
    deco_realtime: 'Нақты уақыт',
    deco_sync: 'Синхрондалған деректер',
    accuracy: 'Дәлдік деңгейі',
    deco_telegram: 'Telegram хабарлама',
    deco_instant: 'Жедел SOS-хабар',
    deco_15sec: '15 секунд',
    deco_qr_refresh: 'QR автожаңарту',
    nav_home: '🏠 Басты',
    nav_history: '📋 Тарих',
    nav_stats: '📊 Статистика',
    exit: 'Шығу',
    today_classes: 'Бүгінгі сабақтар',
    my_stats: 'Менің статистикам',
    present: 'Қатысты',
    late: 'Кешікті',
    absent: 'Келмеді',
    excused: 'Себепті',
    scan_qr: 'QR Сканерлеу',
    aim_qr: 'QR кодты рамкаға түсіріңіз',
    start_scan: 'Сканерлеуді бастау',
    face_look: 'Камераға тура қараңыз...',
    face_id_verify: 'Face ID тексеру',
    cancel: 'Бас тарту',
    success_title: 'Қатысу тіркелді!',
    success_msg: 'Сіз уақытында тіркелдіңіз. Жақсы оқулар!',
    late_title: 'Себепсіз кешіктіңіз!',
    sos_sent: '📡 Деканат пен кураторға хабарлама жіберілді',
    nav_qr_panel: '📟 QR Панель',
    nav_journal: '📓 Журнал',
    nav_reports: '📈 Есептер',
    teacher_label: 'Оқытушы',
    qr_code: 'QR Код',
    updates_in: 'Жаңару:',
    start_qr: 'QR Бастау',
    stop_qr: 'Тоқтату',
    qr_token: 'Токен:',
    refreshing: 'Жаңартылуда...',
    live_attendance: 'Нақты уақыт қатысуы',
    sos_log: 'Жедел хабарламалар журналы',
    warn_late_start: 'Сабақ басталғанына 6+ минут болды. Деканатқа хабарлама жіберілді!',
    nav_overview: '📊 Шолу',
    nav_alerts: '🔔 Хабарламалар',
    nav_groups: '👥 Топтар',
    deanat: 'Деканат',
    ov_today_classes: 'Бүгінгі сабақтар',
    ov_present: 'Қатысып жатыр',
    ov_late: 'Кешіккен',
    ov_sos: 'SOS-хабарламалар',
    sos_alerts: '🚨 Жедел Хабарламалар',
    teacher_status: '👨‍🏫 Мұғалімдер статусы',
    group_attendance: '📊 Топтардың қатысу деңгейі',
  },
  ru: {
    try_free: 'Попробовать бесплатно',
    back: 'Назад',
    nav_about: 'О системе',
    nav_features: 'Возможности',
    nav_pricing: 'Тарифы',
    nav_contact: 'Контакты',
    login: 'Войти',
    register: 'Регистрация',
    badge_live: 'Система активна',
    hero_title: 'Умная система посещаемости',
    hero_sub: 'QR + Face ID + Мгновенные уведомления',
    stat_qr: 'Обновление QR',
    stat_late: 'Порог опоздания',
    stat_lang: 'Языковая поддержка',
    role_student: '🎓 Студент',
    role_teacher: '👨‍🏫 Преподаватель',
    role_dean: '🏛️ Деканат',
    get_started: 'Войти в систему →',
    demo_note: 'Демо-режим — можно тестировать без реальных данных',
    feat_qr: 'Динамический QR',
    feat_face: 'Биометрия Face ID',
    feat_notif: 'Мгновенные уведомления',
    feat_stat: 'Статистика в реальном времени',
    feat_dean: 'Контроль деканата',
    email: 'Электронная почта',
    password: 'Пароль',
    remember: 'Запомнить',
    forgot: 'Забыл пароль',
    select_role: 'Выберите роль',
    login_btn: 'Войти',
    or: 'или',
    face_login: 'Войти через Face ID',
    auth_title: 'Вход в SmartAttend',
    reg_title: 'Создать аккаунт',
    fullname: 'Полное имя',
    student_id: 'ID студента',
    create_account: 'Создать аккаунт',
    deco_secure: 'Безопасная система',
    deco_encrypt: 'Шифрование AES-256',
    deco_face: 'Face ID',
    deco_biometric: 'Биометрическая верификация',
    deco_realtime: 'Реальное время',
    deco_sync: 'Синхронизированные данные',
    accuracy: 'Точность системы',
    deco_telegram: 'Telegram-уведомление',
    deco_instant: 'Мгновенный SOS-сигнал',
    deco_15sec: '15 секунд',
    deco_qr_refresh: 'Автообновление QR',
    nav_home: '🏠 Главная',
    nav_history: '📋 История',
    nav_stats: '📊 Статистика',
    exit: 'Выйти',
    today_classes: 'Сегодняшние занятия',
    my_stats: 'Моя статистика',
    present: 'Присутствовал',
    late: 'Опоздал',
    absent: 'Отсутствовал',
    excused: 'Уважительная',
    scan_qr: 'Сканировать QR',
    aim_qr: 'Наведите камеру на QR-код',
    start_scan: 'Начать сканирование',
    face_look: 'Смотрите прямо в камеру...',
    face_id_verify: 'Проверка Face ID',
    cancel: 'Отмена',
    success_title: 'Посещение зафиксировано!',
    success_msg: 'Вы зарегистрированы вовремя. Удачной учёбы!',
    late_title: 'Опоздание без уважительной причины!',
    sos_sent: '📡 Уведомление отправлено деканату и куратору',
    nav_qr_panel: '📟 QR Панель',
    nav_journal: '📓 Журнал',
    nav_reports: '📈 Отчёты',
    teacher_label: 'Преподаватель',
    qr_code: 'QR Код',
    updates_in: 'Обновление:',
    start_qr: 'Запустить QR',
    stop_qr: 'Остановить',
    qr_token: 'Токен:',
    refreshing: 'Обновляется...',
    live_attendance: 'Посещаемость в реальном времени',
    sos_log: 'Журнал экстренных уведомлений',
    warn_late_start: 'Прошло 6+ минут с начала занятия. Уведомление отправлено деканату!',
    nav_overview: '📊 Обзор',
    nav_alerts: '🔔 Уведомления',
    nav_groups: '👥 Группы',
    deanat: 'Деканат',
    ov_today_classes: 'Занятия сегодня',
    ov_present: 'Присутствуют',
    ov_late: 'Опоздавшие',
    ov_sos: 'SOS-уведомления',
    sos_alerts: '🚨 Экстренные уведомления',
    teacher_status: '👨‍🏫 Статус преподавателей',
    group_attendance: '📊 Посещаемость по группам',
  },
  en: {
    try_free: 'Try for Free',
    back: 'Back',
    nav_about: 'About',
    nav_features: 'Features',
    nav_pricing: 'Pricing',
    nav_contact: 'Contact',
    login: 'Sign In',
    register: 'Register',
    badge_live: 'System Live',
    hero_title: 'Smart Attendance System',
    hero_sub: 'QR + Face ID + Instant Notifications',
    stat_qr: 'QR Refresh',
    stat_late: 'Late Threshold',
    stat_lang: 'Languages',
    role_student: '🎓 Student',
    role_teacher: '👨‍🏫 Teacher',
    role_dean: '🏛️ Deanery',
    get_started: 'Enter System →',
    demo_note: 'Demo mode — test without real data',
    feat_qr: 'Dynamic QR',
    feat_face: 'Face ID Biometrics',
    feat_notif: 'Instant Alerts',
    feat_stat: 'Real-Time Statistics',
    feat_dean: 'Deanery Control',
    email: 'Email Address',
    password: 'Password',
    remember: 'Remember me',
    forgot: 'Forgot password',
    select_role: 'Select your role',
    login_btn: 'Sign In',
    or: 'or',
    face_login: 'Sign in with Face ID',
    auth_title: 'Sign in to SmartAttend',
    reg_title: 'Create new account',
    fullname: 'Full Name',
    student_id: 'Student ID',
    create_account: 'Create Account',
    deco_secure: 'Secure System',
    deco_encrypt: 'AES-256 Encryption',
    deco_face: 'Face ID',
    deco_biometric: 'Biometric Verification',
    deco_realtime: 'Real-Time',
    deco_sync: 'Synchronized Data',
    accuracy: 'Accuracy Level',
    deco_telegram: 'Telegram Alert',
    deco_instant: 'Instant SOS Alert',
    deco_15sec: '15 Seconds',
    deco_qr_refresh: 'Auto QR Refresh',
    nav_home: '🏠 Home',
    nav_history: '📋 History',
    nav_stats: '📊 Statistics',
    exit: 'Exit',
    today_classes: "Today's Classes",
    my_stats: 'My Statistics',
    present: 'Present',
    late: 'Late',
    absent: 'Absent',
    excused: 'Excused',
    scan_qr: 'Scan QR Code',
    aim_qr: 'Point camera at QR code',
    start_scan: 'Start Scanning',
    face_look: 'Look directly at camera...',
    face_id_verify: 'Face ID Verification',
    cancel: 'Cancel',
    success_title: 'Attendance Recorded!',
    success_msg: 'You checked in on time. Have a great class!',
    late_title: 'Unexcused Tardiness!',
    sos_sent: '📡 Notification sent to Deanery and Curator',
    nav_qr_panel: '📟 QR Panel',
    nav_journal: '📓 Journal',
    nav_reports: '📈 Reports',
    teacher_label: 'Teacher',
    qr_code: 'QR Code',
    updates_in: 'Refresh:',
    start_qr: 'Start QR',
    stop_qr: 'Stop',
    qr_token: 'Token:',
    refreshing: 'Refreshing...',
    live_attendance: 'Real-Time Attendance',
    sos_log: 'Emergency Notification Log',
    warn_late_start: '6+ min since class start. Notification sent to Deanery!',
    nav_overview: '📊 Overview',
    nav_alerts: '🔔 Alerts',
    nav_groups: '👥 Groups',
    deanat: 'Deanery',
    ov_today_classes: "Today's Classes",
    ov_present: 'Currently Present',
    ov_late: 'Late',
    ov_sos: 'SOS Alerts',
    sos_alerts: '🚨 Emergency Alerts',
    teacher_status: '👨‍🏫 Teacher Status',
    group_attendance: '📊 Group Attendance Levels',
  }
};

let currentLang = 'kk';

function setLang(lang) {
  currentLang = lang;
  document.body.setAttribute('data-lang', lang);
  // Update all lang buttons
  document.querySelectorAll('.lang-btn').forEach(btn => {
    btn.classList.toggle('active', btn.textContent.trim() === langBtnLabel(lang));
  });
  // Apply translations
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (i18n[lang][key]) el.textContent = i18n[lang][key];
  });
}

function langBtnLabel(lang) {
  return { kk: 'ҚАЗ', ru: 'РУС', en: 'ENG' }[lang];
}

function t(key) {
  return i18n[currentLang][key] || i18n.kk[key] || key;
}

// ══════════════════════════════════════════════════
// PAGE NAVIGATION
// ══════════════════════════════════════════════════
let selectedRole = 'student';

function showPage(pageName) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  const target = document.getElementById('page-' + pageName);
  if (target) {
    target.classList.add('active');
    window.scrollTo(0, 0);
  }
  // Initialize pages when entering
  if (pageName === 'teacher') initTeacherDashboard();
  if (pageName === 'student') initStudentDashboard();
  if (pageName === 'dean')    initDeanDashboard();
}

function selectRole(role, btn) {
  selectedRole = role;
  document.querySelectorAll('.role-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
}

// ══════════════════════════════════════════════════
// AUTH LOGIC
// ══════════════════════════════════════════════════
function switchAuthTab(tab) {
  const loginForm = document.getElementById('form-login');
  const regForm   = document.getElementById('form-register');
  const tabLogin  = document.getElementById('tab-login');
  const tabReg    = document.getElementById('tab-register');
  if (tab === 'login') {
    loginForm.classList.remove('hidden');
    regForm.classList.add('hidden');
    tabLogin.classList.add('active');
    tabReg.classList.remove('active');
  } else {
    loginForm.classList.add('hidden');
    regForm.classList.remove('hidden');
    tabLogin.classList.remove('active');
    tabReg.classList.add('active');
  }
}

function handleLogin(e) {
  e.preventDefault();
  const loader = document.getElementById('login-loader');
  const btn    = document.getElementById('login-btn');
  loader.classList.remove('hidden');
  btn.disabled = true;
  const role = document.querySelector('input[name="role"]:checked').value;
  setTimeout(() => {
    loader.classList.add('hidden');
    btn.disabled = false;
    showToast('success', '✅', t('login_btn'), role === 'student' ? 'STU-2024-001' : role === 'teacher' ? 'Асқар Мұратов' : 'Admin');
    setTimeout(() => {
      selectedRole = role;
      showPage(role);
    }, 600);
  }, 1500);
}

function handleRegister(e) {
  e.preventDefault();
  showToast('success', '✅', 'Аккаунт жасалды!', 'Жүйеге кіре аласыз.');
  setTimeout(() => switchAuthTab('login'), 1000);
}

function togglePwd(inputId, btn) {
  const input = document.getElementById(inputId);
  if (input.type === 'password') { input.type = 'text'; btn.textContent = '🙈'; }
  else                           { input.type = 'password'; btn.textContent = '👁'; }
}

function handleBiometricLogin() {
  openModal('biometric-modal');
  animateFaceProgress('modal-face-bar', () => {
    closeModal('biometric-modal');
    showToast('success', '👁️', 'Face ID', 'Сәтті расталды!');
    setTimeout(() => showPage(selectedRole || 'student'), 600);
  });
}

// ══════════════════════════════════════════════════
// MODAL
// ══════════════════════════════════════════════════
function openModal(id)  { document.getElementById(id).classList.remove('hidden'); }
function closeModal(id) { document.getElementById(id).classList.add('hidden'); }

// ══════════════════════════════════════════════════
// FACE ID ANIMATION
// ══════════════════════════════════════════════════
function animateFaceProgress(barId, onComplete) {
  const bar = document.getElementById(barId);
  if (!bar) return;
  bar.style.width = '0%';
  let pct = 0;
  const iv = setInterval(() => {
    pct += 2;
    bar.style.width = pct + '%';
    if (pct >= 100) {
      clearInterval(iv);
      if (onComplete) onComplete();
    }
  }, 40);
}

// ══════════════════════════════════════════════════
// TOAST NOTIFICATIONS
// ══════════════════════════════════════════════════
function showToast(type, icon, title, message, duration = 4000) {
  const container = document.getElementById('toast-container');
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `<span class="toast-icon">${icon}</span><div class="toast-body"><strong>${title}</strong><span>${message}</span></div>`;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(24px)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, duration);
}

// ══════════════════════════════════════════════════
// DATA: Students & Classes
// ══════════════════════════════════════════════════
const STUDENTS = [
  { id: 'STU-001', name: 'Айдар Сейітов',    abbr: 'АС', status: null, time: null, color: '#6366F1' },
  { id: 'STU-002', name: 'Нұрай Бекова',     abbr: 'НБ', status: null, time: null, color: '#EC4899' },
  { id: 'STU-003', name: 'Марат Қасымов',    abbr: 'МК', status: null, time: null, color: '#10B981' },
  { id: 'STU-004', name: 'Зарина Ахметова',  abbr: 'ЗА', status: null, time: null, color: '#F59E0B' },
  { id: 'STU-005', name: 'Дамир Жұмабеков', abbr: 'ДЖ', status: null, time: null, color: '#EF4444' },
  { id: 'STU-006', name: 'Алия Мансурова',   abbr: 'АМ', status: null, time: null, color: '#8B5CF6' },
  { id: 'STU-007', name: 'Ерлан Дүйсенов',  abbr: 'ЕД', status: null, time: null, color: '#0EA5E9' },
  { id: 'STU-008', name: 'Сания Назарова',   abbr: 'СН', status: null, time: null, color: '#14B8A6' },
  { id: 'STU-009', name: 'Тимур Байдільдін', abbr: 'ТБ', status: null, time: null, color: '#F97316' },
  { id: 'STU-010', name: 'Жансая Ермекова', abbr: 'ЖЕ', status: null, time: null, color: '#06B6D4' },
  { id: 'STU-011', name: 'Ақерке Мусина',   abbr: 'АМ', status: null, time: null, color: '#A855F7' },
  { id: 'STU-012', name: 'Руслан Сейлханов',abbr: 'РС', status: null, time: null, color: '#22C55E' },
];

const CLASSES_TODAY = [
  { id: 'cs101',   name: 'Информатика негіздері', time: '14:00–15:30', room: '312А' },
  { id: 'math201', name: 'Жоғары математика',      time: '16:00–17:30', room: '210Б' },
  { id: 'phys301', name: 'Физика',                  time: '10:00–11:30', room: '105В' },
];

let classStartTime = null;   // for teacher warning
let teacherWarnTimer = null;

// ══════════════════════════════════════════════════
// STUDENT DASHBOARD
// ══════════════════════════════════════════════════
function initStudentDashboard() {
  renderStudentClasses();
}

function renderStudentClasses() {
  const list = document.getElementById('student-class-list');
  if (!list) return;
  list.innerHTML = CLASSES_TODAY.map((cls, i) => `
    <div class="class-item ${i === 0 ? 'active' : ''}" onclick="selectClass('${cls.id}')">
      <div class="class-name">
        <span class="class-status-dot" style="background:${i === 0 ? '#10B981' : '#94A3B8'}"></span>
        ${cls.name}
      </div>
      <div class="class-time">${cls.time} • ${cls.room}</div>
    </div>
  `).join('');
}

function selectClass(id) {
  const cls = CLASSES_TODAY.find(c => c.id === id);
  const badge = document.getElementById('current-class-name');
  if (cls && badge) badge.textContent = `${cls.name} — ${cls.time}`;
  // reset scan state
  resetScanState();
}

function resetScanState() {
  document.getElementById('face-verify-panel').classList.add('hidden');
  document.getElementById('result-success').classList.add('hidden');
  document.getElementById('result-late').classList.add('hidden');
  document.getElementById('qr-viewfinder').style.display = 'flex';
  document.getElementById('scan-btn').style.display = 'block';
  document.getElementById('vf-text').textContent = t('aim_qr');
}

// QR Scan simulation
function simulateScan() {
  const viewfinder = document.getElementById('qr-viewfinder');
  const vfText     = document.getElementById('vf-text');
  const scanBtn    = document.getElementById('scan-btn');
  vfText.textContent = '📡 QR анықталды...';
  viewfinder.style.borderColor = '#10B981';
  scanBtn.disabled = true;
  setTimeout(() => {
    viewfinder.style.display = 'none';
    scanBtn.style.display = 'none';
    // Show Face ID
    const facePanel = document.getElementById('face-verify-panel');
    facePanel.classList.remove('hidden');
    animateFaceProgress('face-progress-bar', () => {
      facePanel.classList.add('hidden');
      showAttendanceResult();
    });
  }, 1200);
}

function showAttendanceResult() {
  // Simulate timing: 30% chance of being late
  const isLate = Math.random() < 0.3;
  const now = new Date();
  const timeStr = now.toLocaleTimeString('kk-KZ', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  if (!isLate) {
    const panel = document.getElementById('result-success');
    panel.classList.remove('hidden');
    document.getElementById('result-time-display').textContent = `✅ ${timeStr}`;
    showToast('success', '✅', t('success_title'), timeStr);
  } else {
    const delay = Math.floor(Math.random() * 25) + 6;
    const panel = document.getElementById('result-late');
    panel.classList.remove('hidden');
    document.getElementById('late-msg-text').textContent = `${t('late_title')} (+${delay} мин)`;
    showToast('error', '⚠️', t('late_title'), `+${delay} мин кешікті`);
    // Send SOS
    setTimeout(() => {
      showToast('warning', '📡', 'SOS хабарлама', `Деканатқа жіберілді: Студент +${delay}мин кешікті`);
    }, 800);
  }
}

// ══════════════════════════════════════════════════
// TEACHER DASHBOARD — QR Generation
// ══════════════════════════════════════════════════
let qrInterval = null;
let qrCountdown = 15;
let qrRunning = false;
let studentsData = [];

function initTeacherDashboard() {
  studentsData = STUDENTS.map(s => ({ ...s, status: null, time: null }));
  generateQRCode();
  renderStudentList();
  updateCounters();
}

function generateQRCode() {
  const token = 'SA-' + Math.random().toString(36).substr(2, 8).toUpperCase();
  document.getElementById('qr-token-text').textContent = token;
  renderQRSVG(token);
}

function renderQRSVG(token) {
  const svg = document.getElementById('qr-svg');
  if (!svg) return;
  // Generate a pseudo-random QR pattern based on token
  const seed = token.split('').reduce((a, c) => a + c.charCodeAt(0), 0);
  const rng = seededRandom(seed);
  const moduleSize = 8;
  const modules = 21; // QR v1
  let cells = '';
  // Fixed finder patterns
  const finderPos = [[0,0],[14,0],[0,14]];
  const finderSet = new Set();
  finderPos.forEach(([r,c]) => {
    for (let i=-1; i<=7; i++) for (let j=-1; j<=7; j++) {
      finderSet.add(`${r+i},${c+j}`);
    }
  });
  // Finder patterns
  [0,14].forEach(row => {
    [0,14].forEach((col, ci) => {
      if (ci === 1 && row === 14) return; // bottom-right unused
      // Outer 7x7
      for (let r = 0; r < 7; r++) for (let c2 = 0; c2 < 7; c2++) {
        const dark = r===0||r===6||c2===0||c2===6||(r>=2&&r<=4&&c2>=2&&c2<=4);
        if (dark) cells += `<rect x="${(col + c2) * moduleSize + 10}" y="${(row + r) * moduleSize + 10}" width="${moduleSize}" height="${moduleSize}" fill="#0062FF"/>`;
      }
    });
  });
  // Data modules
  for (let r = 0; r < modules; r++) {
    for (let c2 = 0; c2 < modules; c2++) {
      const key = `${r},${c2}`;
      if (finderSet.has(key)) continue;
      if (rng() > 0.5) {
        cells += `<rect x="${c2 * moduleSize + 10}" y="${r * moduleSize + 10}" width="${moduleSize - 1}" height="${moduleSize - 1}" rx="1" fill="#0F172A"/>`;
      }
    }
  }
  // Center logo
  cells += `<rect x="85" y="85" width="30" height="30" rx="6" fill="white"/>`;
  cells += `<rect x="90" y="90" width="20" height="20" rx="4" fill="#0062FF" opacity="0.15"/>`;
  cells += `<text x="100" y="105" text-anchor="middle" font-size="14" font-weight="800" fill="#0062FF">SA</text>`;
  svg.innerHTML = cells;
}

function seededRandom(seed) {
  let s = seed;
  return function() {
    s = (s * 1664525 + 1013904223) & 0xffffffff;
    return (s >>> 0) / 0xffffffff;
  };
}

function startQR() {
  if (qrRunning) return;
  qrRunning = true;
  qrCountdown = 15;
  classStartTime = Date.now();
  document.getElementById('start-qr-btn').disabled = true;
  document.getElementById('stop-qr-btn').disabled  = false;
  generateQRCode();
  updateExpireBar(15, 15);
  showToast('info', '📟', 'QR Бастау', 'QR код жасалды. 15 сек сайын жаңарады.');

  // Teacher late warning (after 6 min simulation → 10 sec in demo)
  teacherWarnTimer = setTimeout(() => {
    document.getElementById('teacher-warn').classList.remove('hidden');
    showToast('error', '⚠️', 'Мұғалім ескертуі', 'Деканатқа хабарлама жіберілді!');
    addSOSEntry('Мұғалім сабақты уақытында бастамады', 'Асқар Мұратов • CS101');
  }, 10000); // 10s demo (real: 6 min)

  // Start 15-second countdown
  qrInterval = setInterval(() => {
    qrCountdown--;
    document.getElementById('qr-countdown').textContent = qrCountdown;
    const pct = (qrCountdown / 15) * 100;
    updateExpireBar(pct, 15);
    if (qrCountdown <= 0) {
      refreshQR();
      qrCountdown = 15;
    }
  }, 1000);

  // Simulate students arriving
  simulateStudentArrival();
}

function updateExpireBar(pct) {
  const bar = document.getElementById('qr-expire-bar');
  if (bar) bar.style.width = pct + '%';
}

function refreshQR() {
  const overlay = document.getElementById('qr-refresh-overlay');
  if (overlay) overlay.classList.remove('hidden');
  setTimeout(() => {
    generateQRCode();
    if (overlay) overlay.classList.add('hidden');
    updateExpireBar(100);
  }, 600);
}

function stopQR() {
  if (!qrRunning) return;
  qrRunning = false;
  clearInterval(qrInterval);
  clearTimeout(teacherWarnTimer);
  document.getElementById('start-qr-btn').disabled = false;
  document.getElementById('stop-qr-btn').disabled  = true;
  document.getElementById('qr-countdown').textContent = '15';
  document.getElementById('teacher-warn').classList.add('hidden');
  showToast('warning', '■', 'QR Тоқтатылды', 'QR жасалуы тоқтатылды.');
}

function updateQR() {
  if (qrRunning) {
    clearInterval(qrInterval);
    clearTimeout(teacherWarnTimer);
    stopQR();
  }
  generateQRCode();
}

// Student arrival simulation
const statusSequence = ['present','present','present','late','present','excused','present','late','present','present','absent','present'];
let arrivalIndex = 0;

function simulateStudentArrival() {
  if (arrivalIndex >= studentsData.length) return;
  const delay = 1200 + Math.random() * 2000;
  setTimeout(() => {
    if (!qrRunning) return;
    const student = studentsData[arrivalIndex];
    const status  = statusSequence[arrivalIndex] || 'absent';
    const now = new Date();
    const timeStr = now.toLocaleTimeString('kk-KZ', { hour: '2-digit', minute: '2-digit' });
    student.status = status;
    student.time   = timeStr;
    arrivalIndex++;
    renderStudentList();
    updateCounters();
    if (status === 'late') {
      const delay2 = Math.floor(Math.random() * 20) + 6;
      addSOSEntry(`Себепсіз кешікті (+${delay2} мин)`, student.name);
      showToast('error', '🔴', student.name, `Кешікті (+${delay2} мин). SOS жіберілді.`);
    } else if (status === 'present') {
      showToast('success', '🟢', student.name, `Уақытында тіркелді — ${timeStr}`);
    }
    simulateStudentArrival();
  }, delay);
}

function renderStudentList() {
  const list = document.getElementById('teacher-student-list');
  if (!list) return;
  list.innerHTML = studentsData.map(s => {
    const statusClass = s.status || 'absent';
    const statusLabel = {
      present: `🟢 ${t('present')}`,
      late:    `🔴 ${t('late')}`,
      excused: `🔵 ${t('excused')}`,
      absent:  `⚫ ${t('absent')}`
    }[statusClass] || `⚫ ${t('absent')}`;
    return `
      <div class="student-row ${statusClass}">
        <div class="stu-avatar" style="background:${s.color}">${s.abbr}</div>
        <div class="stu-info">
          <div class="stu-name">${s.name}</div>
          <div class="stu-id">${s.id}</div>
        </div>
        <div>
          <div class="stu-status-badge ${statusClass}">${statusLabel}</div>
          <div class="stu-time">${s.time || '—'}</div>
        </div>
      </div>`;
  }).join('');
}

function updateCounters() {
  const present = studentsData.filter(s => s.status === 'present').length;
  const late    = studentsData.filter(s => s.status === 'late').length;
  const excused = studentsData.filter(s => s.status === 'excused').length;
  const absent  = studentsData.filter(s => !s.status || s.status === 'absent').length;
  const setText = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
  setText('cnt-present', present);
  setText('cnt-late',    late);
  setText('cnt-excused', excused);
  setText('cnt-absent',  absent);
}

function filterStudents(query) {
  const rows = document.querySelectorAll('.student-row');
  rows.forEach(row => {
    const name = row.querySelector('.stu-name')?.textContent.toLowerCase() || '';
    const id   = row.querySelector('.stu-id')?.textContent.toLowerCase() || '';
    row.style.display = (name.includes(query.toLowerCase()) || id.includes(query.toLowerCase())) ? '' : 'none';
  });
}

function addSOSEntry(title, subtitle) {
  const entries = document.getElementById('sos-entries');
  if (!entries) return;
  const now     = new Date();
  const timeStr = now.toLocaleTimeString('kk-KZ', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  const entry   = document.createElement('div');
  entry.className = 'sos-entry';
  entry.innerHTML = `<span>🚨</span><div><strong>${title}</strong>${subtitle}</div><span class="sos-time">${timeStr}</span>`;
  entries.insertBefore(entry, entries.firstChild);
}

function showTeacherTab(tab) {
  // Minimal tab switching for demo
  showToast('info', '📋', tab === 'journal' ? t('nav_journal') : t('nav_reports'), 'Бөлім ашылуда...');
}

function showStudentTab(tab) {
  showToast('info', '📊', tab === 'history' ? t('nav_history') : t('nav_stats'), 'Бөлім ашылуда...');
}

// ══════════════════════════════════════════════════
// DEAN DASHBOARD
// ══════════════════════════════════════════════════
const TEACHER_DATA = [
  { name: 'Асқар Мұратов',    class: 'CS101 — Информатика',     status: 'online' },
  { name: 'Айгүл Сейтқали',   class: 'MATH201 — Математика',    status: 'online' },
  { name: 'Болат Нұрғали',     class: 'PHYS301 — Физика',        status: 'late-sos' },
  { name: 'Дина Серікқали',    class: 'HIST401 — Тарих',         status: 'offline' },
  { name: 'Ержан Байтасов',    class: 'ENG501 — Ағылшын тілі',   status: 'online' },
];
const SOS_ALERTS = [
  { type: 'late', title: 'Студент кешіктіруі', desc: 'Нұрай Бекова — CS101 (+12мин)', time: '14:12' },
  { type: 'teacher', title: 'Мұғалім ескертуі', desc: 'Болат Нұрғали — PHYS301 сабақты бастамады', time: '10:07' },
  { type: 'late', title: 'Студент кешіктіруі', desc: 'Дамир Жұмабеков — MATH201 (+8мин)', time: '16:08' },
];
const GROUP_DATA = [
  { name: 'CS-2201', pct: 92, color: '#0062FF' },
  { name: 'CS-2202', pct: 78, color: '#10B981' },
  { name: 'MATH-21', pct: 85, color: '#8B5CF6' },
  { name: 'PHYS-21', pct: 65, color: '#F59E0B' },
  { name: 'ENG-21',  pct: 88, color: '#EC4899' },
  { name: 'HIST-21', pct: 71, color: '#EF4444' },
];

function initDeanDashboard() {
  renderDeanAlerts();
  renderTeacherStatus();
  renderGroupBars();
  // Animate numbers
  animateNumber('ov-classes', 8);
  animateNumber('ov-present', 142);
  animateNumber('ov-late', 18);
  animateNumber('ov-sos', 3);
  // Simulate new SOS arriving
  setTimeout(() => {
    showToast('error', '🚨', 'Жаңа SOS', 'Зарина Ахметова — ENG501 (+9мин)');
    const el = document.getElementById('ov-sos');
    if (el) el.textContent = '4';
  }, 5000);
}

function renderDeanAlerts() {
  const list = document.getElementById('dean-alerts-list');
  if (!list) return;
  list.innerHTML = SOS_ALERTS.map(a => `
    <div class="alert-item">
      <strong>${a.type === 'teacher' ? '👨‍🏫 ' : '🔴 '} ${a.title}</strong>
      <span>${a.desc}</span>
      <span class="alert-time">🕐 ${a.time}</span>
    </div>
  `).join('');
}

function renderTeacherStatus() {
  const list = document.getElementById('dean-teacher-list');
  if (!list) return;
  list.innerHTML = TEACHER_DATA.map(t2 => `
    <div class="teacher-row">
      <div class="teacher-status-dot ${t2.status}"></div>
      <div class="teacher-row-info">
        <div class="teacher-row-name">${t2.name}</div>
        <div class="teacher-row-class">${t2.class}</div>
      </div>
      <div class="teacher-row-badge ${t2.status === 'online' ? 'online' : t2.status === 'late-sos' ? 'sos' : 'offline'}">
        ${t2.status === 'online' ? '● Белсенді' : t2.status === 'late-sos' ? '🚨 SOS' : '○ Офлайн'}
      </div>
    </div>
  `).join('');
}

function renderGroupBars() {
  const wrap = document.getElementById('group-bars');
  if (!wrap) return;
  wrap.innerHTML = GROUP_DATA.map(g => `
    <div class="group-bar-row">
      <div class="group-label">${g.name}</div>
      <div class="group-bar-wrap">
        <div class="group-bar" style="width:0%; background:${g.color}" data-target="${g.pct}"></div>
      </div>
      <div class="group-pct" style="color:${g.color}">${g.pct}%</div>
    </div>
  `).join('');
  // Animate bars
  setTimeout(() => {
    document.querySelectorAll('.group-bar').forEach(bar => {
      bar.style.width = bar.dataset.target + '%';
    });
  }, 200);
}

function animateNumber(id, target) {
  const el = document.getElementById(id);
  if (!el) return;
  let current = 0;
  const step  = Math.ceil(target / 40);
  const iv    = setInterval(() => {
    current = Math.min(current + step, target);
    el.textContent = current;
    if (current >= target) clearInterval(iv);
  }, 30);
}

// ══════════════════════════════════════════════════
// INIT
// ══════════════════════════════════════════════════
document.addEventListener('DOMContentLoaded', () => {
  // Apply default language
  setLang('kk');

  // Role radio synchronization
  document.querySelectorAll('input[name="role"]').forEach(radio => {
    radio.addEventListener('change', () => {
      selectedRole = radio.value;
    });
  });

  // Initialize landing card stat units based on language
  // (already set by setLang)
});
