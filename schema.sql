-- ========================================================
-- SmartAttend Enterprise — Полная Схема Базы Данных Колледжа
-- СУБД: PostgreSQL / SQLite совместимая
-- Архитектура: S-Student, S-Mugalim, S-Kurator, S-Ata-Ana, S-Deanat
-- ========================================================

-- 1. ТАБЛИЦА АКАДЕМИЧЕСКИХ ГРУПП
CREATE TABLE IF NOT EXISTS academic_groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,      -- БҚ2405, ПО2501, ПО2502, ВТ2510 и др.
    faculty VARCHAR(150) NOT NULL,          -- Ақпараттық технологиялар бөлімі
    course_year INT DEFAULT 2,              -- 2 курс
    curator_id INT,                         -- Ссылка на куратора группы
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. ТАБЛИЦА ПОЛЬЗОВАТЕЛЕЙ (Все роли в одной защищенной системе)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) DEFAULT '123456', -- Пароль, выданный руководством колледжа
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,              -- 'STUDENT', 'TEACHER', 'CURATOR', 'PARENT', 'DEAN', 'DIRECTOR'
    student_id VARCHAR(50) UNIQUE,          -- Студенческий билет: STU-2405-01 ...
    group_id INT REFERENCES academic_groups(id) ON DELETE SET NULL,
    child_student_id INT REFERENCES users(id) ON DELETE SET NULL, -- Для родителей (связка с ребенком)
    phone VARCHAR(30),
    department VARCHAR(150),
    avatar_url TEXT,
    face_embedding TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. ТАБЛИЦА АУДИТОРИЙ И ЗОН КАМПУСА (Прямая связка с векторной картой AITU)
CREATE TABLE IF NOT EXISTS rooms (
    code VARCHAR(50) PRIMARY KEY,           -- С1.3.241, С1.3.240, С1.3.228, спорт.зал
    svg_id VARCHAR(50),                     -- C1.3.241P, C1.3.240P, C1.3.228K, ZONE_GYM
    floor INT NOT NULL DEFAULT 2,           -- 1, 2, 3
    block VARCHAR(20) DEFAULT 'C1.3',       -- Корпус/Блок
    name_kk VARCHAR(150) NOT NULL,
    name_ru VARCHAR(150) NOT NULL,
    name_en VARCHAR(150) NOT NULL,
    capacity INT DEFAULT 30
);

-- 4. ТАБЛИЦА РАСПИСАНИЯ ЗАНЯТИЙ (Lessons)
CREATE TABLE IF NOT EXISTS lessons (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,            -- Название дисциплины
    teacher_id INT REFERENCES users(id) ON DELETE CASCADE,
    group_id INT REFERENCES academic_groups(id) ON DELETE CASCADE,
    room_code VARCHAR(50) REFERENCES rooms(code) ON DELETE CASCADE,
    day_of_week VARCHAR(20) NOT NULL,       -- 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'
    pair_number INT NOT NULL DEFAULT 1,     -- 1, 2, 3, 4 пара
    start_time VARCHAR(20) NOT NULL,        -- '08:00', '09:45', '11:40', '13:30'
    end_time VARCHAR(20) NOT NULL,          -- '09:35', '11:20', '13:15', '15:00'
    is_qr_active BOOLEAN DEFAULT FALSE,
    current_qr_token VARCHAR(255),
    qr_updated_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'SCHEDULED' -- 'SCHEDULED', 'ACTIVE', 'FINISHED'
);

-- 5. ТАБЛИЦА ПОСЕЩАЕМОСТИ И БАЛЛОВ (Attendance & Grades)
CREATE TABLE IF NOT EXISTS attendance_records (
    id SERIAL PRIMARY KEY,
    lesson_id INT REFERENCES lessons(id) ON DELETE CASCADE,
    student_id INT REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,            -- 'PRESENT', 'LATE', 'ABSENT', 'EXCUSED'
    delay_minutes INT DEFAULT 0,            -- Минуты опоздания
    grade_score INT DEFAULT NULL,           -- Балл за занятие (0 - 100)
    face_verified BOOLEAN DEFAULT TRUE,     -- Биометрия Face ID
    qr_token VARCHAR(255),
    check_in_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(lesson_id, student_id)
);

-- 6. ЖУРНАЛ ПРИСУТСТВИЯ
CREATE TABLE IF NOT EXISTS attendance_journal (
    id SERIAL PRIMARY KEY,
    student_id TEXT NOT NULL,
    teacher_id TEXT NOT NULL,
    scan_timestamp TEXT NOT NULL,
    verification_timestamp TEXT NOT NULL,
    photo BYTEA NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. ТАБЛИЦА РОДИТЕЛЬСКИХ РАСПИСОК И СПРАВОК (Parent Notes & Medical Excuses)
-- По регламенту колледжа: даже при 18 годах требуется расписка от родителей при уходе или болезни
CREATE TABLE IF NOT EXISTS parent_notes (
    id SERIAL PRIMARY KEY,
    student_id INT REFERENCES users(id) ON DELETE CASCADE,
    parent_id INT REFERENCES users(id) ON DELETE CASCADE,
    note_type VARCHAR(50) NOT NULL,         -- 'FAMILY_CIRCUMSTANCE' (Отпросить/қолхат), 'ILLNESS' (Ауырып қалды), 'OFFICIAL_DUTY'
    reason TEXT NOT NULL,                   -- Причина / текст расписки
    date_from DATE NOT NULL,
    date_to DATE NOT NULL,
    document_url TEXT,                      -- Фото рукописной расписки или справки
    status VARCHAR(50) DEFAULT 'PENDING',   -- 'PENDING', 'APPROVED', 'REJECTED'
    reviewed_by INT REFERENCES users(id),   -- Куратор, рассмотревший расписку
    review_comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. ТАБЛИЦА ЭКСТРЕННЫХ СООБЩЕНИЙ И ОПОВЕЩЕНИЙ ОБ ОПОЗДАНИЯХ (SOS Alerts)
CREATE TABLE IF NOT EXISTS sos_alerts (
    id SERIAL PRIMARY KEY,
    lesson_id INT REFERENCES lessons(id) ON DELETE SET NULL,
    student_id INT REFERENCES users(id) ON DELETE CASCADE,
    group_id INT REFERENCES academic_groups(id) ON DELETE CASCADE,
    alert_type VARCHAR(50) NOT NULL,        -- 'LATE_SOS' (Опоздание > 5 мин), 'ABSENCE_SOS', 'PANIC_SOS'
    message TEXT NOT NULL,
    severity VARCHAR(20) DEFAULT 'HIGH',    -- 'HIGH', 'MEDIUM', 'INFO'
    is_resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================================
-- НАЧАЛЬНОЕ НАПОЛНЕНИЕ ДАННЫМИ (SEEDS)
-- ========================================================

-- А. Аудитории кампуса (соответствуют векторной карте aitu_floors_data.js)
INSERT INTO rooms (code, svg_id, floor, block, name_kk, name_ru, name_en) VALUES
('С1.3.241', 'C1.3.241P', 2, 'C1.3', 'С1.3.241 Компьютерлік сынып', 'С1.3.241 Компьютерный класс', 'С1.3.241 Computer Lab'),
('С1.3.240', 'C1.3.240P', 2, 'C1.3', 'С1.3.240 Дәрісхана', 'С1.3.240 Лекционная аудитория', 'С1.3.240 Lecture Hall'),
('С1.3.228', 'C1.3.228K', 2, 'C1.3', 'С1.3.228 Бағдарламалау зертханасы', 'С1.3.228 Лаборатория программирования', 'С1.3.228 Programming Lab'),
('С1.3.229', 'C1.3.229P', 2, 'C1.3', 'С1.3.229 Мәліметтер базасы аудиториясы', 'С1.3.229 Аудитория баз данных', 'С1.3.229 Database Lab'),
('С1.3.230', 'C1.3.230P', 2, 'C1.3', 'С1.3.230 Желілік технологиялар', 'С1.3.230 Сетевые технологии', 'С1.3.230 Networking Lab'),
('С1.3.237', 'C1.3.237P', 2, 'C1.3', 'С1.3.237 Экономика және бизнес', 'С1.3.237 Экономика и бизнес', 'С1.3.237 Economics & Business'),
('С1.3.262', 'C1.3.262P', 2, 'C1.3', 'С1.3.262 Кәсіпкерлік негіздері', 'С1.3.262 Основы предпринимательства', 'С1.3.262 Entrepreneurship'),
('С1.3.263', 'C1.3.263P', 2, 'C1.3', 'С1.3.263 Дәріс аудиториясы', 'С1.3.263 Лекционная аудитория', 'С1.3.263 Lecture Hall'),
('С1.3.222', 'C1.3.222P', 2, 'C1.3', 'С1.3.222 Семинар бөлмесі', 'С1.3.222 Семинарская аудитория', 'С1.3.222 Seminar Room'),
('спорт.зал', 'ZONE_GYM', 1, 'C1.3', 'Спорт кешені / Спортзал', 'Спортивный комплекс / Спортзал', 'Sports Gym & Arena')
ON CONFLICT (code) DO NOTHING;

-- Б. Академические группы колледжа
INSERT INTO academic_groups (name, faculty, course_year) VALUES
('БҚ2405', 'Ақпараттық қауіпсіздік және бағдарламалау', 2),
('ПО2501', 'Бағдарламалық қамтамасыздандыру', 2),
('ПО2502', 'Бағдарламалық қамтамасыздандыру', 2),
('БҚ2503', 'Ақпараттық қауіпсіздік жүйелері', 2),
('БҚ2504', 'Ақпараттық қауіпсіздік жүйелері', 2),
('ПО2506', 'Бағдарламалық қамтамасыздандыру', 2),
('ПО2507', 'Бағдарламалық қамтамасыздандыру', 2),
('ПО2508', 'Бағдарламалық қамтамасыздандыру', 2),
('ПО2509', 'Бағдарламалық қамтамасыздандыру', 2),
('ВТ2510', 'Есептеуіш техника және аппараттық қамту', 2)
ON CONFLICT (name) DO NOTHING;

-- В. Руководство колледжа и Деканат
INSERT INTO users (email, password_hash, full_name, role, department) VALUES
('p82041180@gmail.com', 'director2026', 'Главный администратор / Директор', 'DIRECTOR', 'Ректорат / Басқару аппараты'),
('dean@smartattend.kz', 'dean123', 'Деканат IT-Бөлімі', 'DEAN', 'Оқу бөлімі / Деканат')
ON CONFLICT (email) DO UPDATE SET role = EXCLUDED.role;

-- Г. Куратор группы БҚ2405
INSERT INTO users (email, password_hash, full_name, role, department) VALUES
('curator.arai@smartattend.kz', 'curator123', 'Талдаубек Арай Талдаубекқызы', 'CURATOR', 'Компьютерлік технологиялар кафедрасы')
ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name;

-- Привязываем куратора к группе БҚ2405
UPDATE academic_groups 
SET curator_id = (SELECT id FROM users WHERE email = 'curator.arai@smartattend.kz')
WHERE name = 'БҚ2405';

-- Д. Преподаватели колледжа из официального расписания
INSERT INTO users (email, password_hash, full_name, role, department) VALUES
('kalniyazov@smartattend.kz', 'teacher123', 'Калниязов А.А.', 'TEACHER', 'Бағдарламалау бөлімі'),
('bilal@smartattend.kz', 'teacher123', 'Билал Д.Д.', 'TEACHER', 'Деректер базасы кафедрасы'),
('akhmetova@smartattend.kz', 'teacher123', 'Ахметова Е.З.', 'TEACHER', 'Компьютерлік графика'),
('zhumaganbetova@smartattend.kz', 'teacher123', 'Жұмағанбетова А.К.', 'TEACHER', 'Дене тәрбиесі кафедрасы'),
('akubayeva@smartattend.kz', 'teacher123', 'Акубаева Б.А.', 'TEACHER', 'Экономика және кәсіпкерлік'),
('amiralin@smartattend.kz', 'teacher123', 'Амиралин Т.К.', 'TEACHER', 'Ақпараттық қауіпсіздік')
ON CONFLICT (email) DO NOTHING;

-- Е. Студенты группы БҚ2405 (20 реальных человек)
-- Логин: email / студенческий ID, Пароль: 123456
INSERT INTO users (email, password_hash, full_name, role, student_id, group_id, department) VALUES
('inkarai@smartattend.kz', '123456', 'Айдынбекқызы Іңкәрәй', 'STUDENT', 'STU-2405-01', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('tolganai.a@smartattend.kz', '123456', 'Ахметова Толганай Сериковна', 'STUDENT', 'STU-2405-02', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('dinmuhammed@smartattend.kz', '123456', 'Байтомор Дінмұхаммед', 'STUDENT', 'STU-2405-03', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('ayauzhan.b@smartattend.kz', '123456', 'Бектебай Аяужан Даулетжанқызы', 'STUDENT', 'STU-2405-04', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('berdibek.e@smartattend.kz', '123456', 'Егеубай Бердібек Азаматұлы', 'STUDENT', 'STU-2405-05', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('nurali.zh@smartattend.kz', '123456', 'Жексембай Нұрәли Мұратұлы', 'STUDENT', 'STU-2405-06', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('mukhtar.zh@smartattend.kz', '123456', 'Жұмабек Мұхтар Дүйсенбайұлы', 'STUDENT', 'STU-2405-07', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('makhfuza.zh@smartattend.kz', '123456', 'Жұматай Махфуза Мұратқызы', 'STUDENT', 'STU-2405-08', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('malika.k@smartattend.kz', '123456', 'Кусаинова Малика Абаевна', 'STUDENT', 'STU-2405-09', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('ayaulym.k@smartattend.kz', '123456', 'Құдайберген Аяулым Әскербекқызы', 'STUDENT', 'STU-2405-10', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('nurbakyt.k@smartattend.kz', '123456', 'Қыстаубай Нұрбақыт Серікұлы', 'STUDENT', 'STU-2405-11', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('nurai.m@smartattend.kz', '123456', 'Маркален Нұрай Қуанышқызы', 'STUDENT', 'STU-2405-12', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('alikhan.m@smartattend.kz', '123456', 'Мәлікұлы Алихан', 'STUDENT', 'STU-2405-13', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('ramazan.m@smartattend.kz', '123456', 'Молдабек Рамазан Ардақұлы', 'STUDENT', 'STU-2405-14', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('ansar.m@smartattend.kz', '123456', 'Мұрат Аңсар Сұңғатұлы', 'STUDENT', 'STU-2405-15', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('yerasyl.r@smartattend.kz', '123456', 'Рамазан Ерасыл Қайратұлы', 'STUDENT', 'STU-2405-16', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('zhasulan.s@smartattend.kz', '123456', 'Серікбек Жасұлан Есенбекұлы', 'STUDENT', 'STU-2405-17', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('nurlybek.t@smartattend.kz', '123456', 'Төлеген Нұрлыбек Талғатұлы', 'STUDENT', 'STU-2405-18', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('nurzhan.t@smartattend.kz', '123456', 'Тұрсынжан Нұржан Нұрханұлы', 'STUDENT', 'STU-2405-19', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405'),
('aruzhan.sh@smartattend.kz', '123456', 'Шаихова Аружан Амангазиевна', 'STUDENT', 'STU-2405-20', (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'БҚ2405')
ON CONFLICT (email) DO NOTHING;

-- Ж. Родители (S-Ata-Ana: родитель Дінмұхаммеда)
INSERT INTO users (email, password_hash, full_name, role, child_student_id, phone, department) VALUES
('parent.baitomor@smartattend.kz', 'parent123', 'Байтомор Ата-Анасы', 'PARENT', 
    (SELECT id FROM users WHERE email = 'dinmuhammed@smartattend.kz'), 
    '+7 (777) 123-45-67', 'Ата-Аналар алқасы')
ON CONFLICT (email) DO NOTHING;

-- З. Расписание занятий для группы БҚ2405 (понедельник — пятница)
-- Понедельник
INSERT INTO lessons (title, teacher_id, group_id, room_code, day_of_week, pair_number, start_time, end_time, is_qr_active) VALUES
('Бағдарламалық қамтамасыздандыру спецификациясы', (SELECT id FROM users WHERE email = 'kalniyazov@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.241', 'Monday', 1, '08:00', '09:35', TRUE),
('Деректер базасын басқару', (SELECT id FROM users WHERE email = 'bilal@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.241', 'Monday', 2, '09:45', '11:20', FALSE),
('Графика және жобалау', (SELECT id FROM users WHERE email = 'akhmetova@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.241', 'Monday', 3, '11:40', '13:15', FALSE),

-- Вторник
('Бағдарламалық қамтамасыздандыру спецификациясы', (SELECT id FROM users WHERE email = 'kalniyazov@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.228', 'Tuesday', 1, '08:00', '09:35', FALSE),
('Графика және жобалау', (SELECT id FROM users WHERE email = 'akhmetova@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.228', 'Tuesday', 2, '09:45', '11:20', FALSE),
('Ақпараттық-коммуникациялық және цифрлық технологиялар', (SELECT id FROM users WHERE email = 'curator.arai@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.228', 'Tuesday', 3, '11:40', '13:15', FALSE),

-- Среда
('Развитие и совершенствование физических качеств', (SELECT id FROM users WHERE email = 'zhumaganbetova@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'спорт.зал', 'Wednesday', 1, '08:00', '09:35', FALSE),
('Графика және жобалау', (SELECT id FROM users WHERE email = 'akhmetova@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.230', 'Wednesday', 2, '09:45', '11:20', FALSE),
('Бағдарламалық қамтамасыздандыру спецификациясы', (SELECT id FROM users WHERE email = 'kalniyazov@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.230', 'Wednesday', 3, '11:40', '13:15', FALSE),

-- Четверг
('Ақпараттық-коммуникациялық және цифрлық технологиялар', (SELECT id FROM users WHERE email = 'curator.arai@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.229', 'Thursday', 1, '08:00', '09:35', FALSE),
('Экономиканың базалық білімі және кәсіпкерлік', (SELECT id FROM users WHERE email = 'akubayeva@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.237', 'Thursday', 2, '09:45', '11:20', FALSE),
('Деректер базасын басқару', (SELECT id FROM users WHERE email = 'bilal@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.229', 'Thursday', 3, '11:40', '13:15', FALSE),

-- Пятница
('Деректер базасын басқару', (SELECT id FROM users WHERE email = 'bilal@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.240', 'Friday', 1, '08:00', '09:35', FALSE),
('Ақпараттық-коммуникациялық және цифрлық технологиялар', (SELECT id FROM users WHERE email = 'curator.arai@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.240', 'Friday', 2, '09:45', '11:20', FALSE),
('Бағдарламалық қамтамасыздандыру спецификациясы', (SELECT id FROM users WHERE email = 'kalniyazov@smartattend.kz'), (SELECT id FROM academic_groups WHERE name = 'БҚ2405'), 'С1.3.240', 'Friday', 3, '11:40', '13:15', FALSE);

-- И. Примеры посещаемости на текущей паре
INSERT INTO attendance_records (lesson_id, student_id, status, delay_minutes, grade_score, check_in_time) VALUES
(1, (SELECT id FROM users WHERE email = 'dinmuhammed@smartattend.kz'), 'PRESENT', 0, 95, CURRENT_TIMESTAMP - INTERVAL '10 minutes'),
(1, (SELECT id FROM users WHERE email = 'inkarai@smartattend.kz'), 'PRESENT', 0, 90, CURRENT_TIMESTAMP - INTERVAL '12 minutes'),
(1, (SELECT id FROM users WHERE email = 'tolganai.a@smartattend.kz'), 'LATE', 8, 80, CURRENT_TIMESTAMP - INTERVAL '2 minutes'),
(1, (SELECT id FROM users WHERE email = 'nurali.zh@smartattend.kz'), 'ABSENT', 0, NULL, CURRENT_TIMESTAMP)
ON CONFLICT (lesson_id, student_id) DO NOTHING;

-- К. Пример родительской расписки / қолхат
INSERT INTO parent_notes (student_id, parent_id, note_type, reason, date_from, date_to, status, reviewed_by, review_comment) VALUES
(
    (SELECT id FROM users WHERE email = 'dinmuhammed@smartattend.kz'),
    (SELECT id FROM users WHERE email = 'parent.baitomor@smartattend.kz'),
    'FAMILY_CIRCUMSTANCE',
    'Отбасылық жағдайларға байланысты (үй құжаттарын ресімдеу) сағат 14:00-ден бастап сұраймын.',
    CURRENT_DATE,
    CURRENT_DATE,
    'APPROVED',
    (SELECT id FROM users WHERE email = 'curator.arai@smartattend.kz'),
    'Куратор рұқсат берді. Сабақты оқып келуі тиіс.'
);
