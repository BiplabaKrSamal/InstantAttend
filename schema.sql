-- ================================================================
--  InstantAttend — SQLite Schema
--  File    : schema.sql
--  Used by : app.py → init_db() → conn.executescript(f.read())
--  Run     : Automatically on every app startup. Never run manually.
-- ================================================================
--
--  QUERY MAP — every SQL statement in app.py and the column it needs:
--
--  totalreg()
--      SELECT COUNT(*) FROM users
--      → needs table: users
--
--  extract_attendance()
--      SELECT name, roll, time FROM attendance WHERE date = ? ORDER BY id ASC
--      → needs columns: name, roll, time, date, id   in attendance
--
--  add_attendance()
--      SELECT id FROM users WHERE roll = ?
--      → needs columns: id, roll   in users
--
--      INSERT INTO attendance (user_id, name, roll, date, time) VALUES (?,?,?,?,?)
--      → needs columns: user_id, name, roll, date, time   in attendance
--
--  register_user_in_db()
--      INSERT INTO users (name, roll, face_folder, registered_on) VALUES (?,?,?,?)
--      → needs columns: name, roll, face_folder, registered_on   in users
--
-- ================================================================


-- ----------------------------------------------------------------
-- TABLE: users
--
-- Columns used in app.py:
--   id            ← SELECT id FROM users WHERE roll = ?
--   name          ← INSERT INTO users (name, ...)
--   roll          ← INSERT INTO users (..., roll, ...)
--                   SELECT id FROM users WHERE roll = ?
--                   UNIQUE constraint blocks duplicate rolls
--   face_folder   ← INSERT INTO users (..., face_folder, ...)
--   registered_on ← INSERT INTO users (..., registered_on)
--                   value passed = datetoday2() → "21-March-2026"
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id            INTEGER  PRIMARY KEY AUTOINCREMENT,  -- used by: attendance.user_id FK
    name          TEXT     NOT NULL,                   -- used by: register_user_in_db()
    roll          INTEGER  NOT NULL UNIQUE,            -- used by: add_attendance() lookup
    face_folder   TEXT     NOT NULL,                   -- used by: register_user_in_db()
    registered_on TEXT     NOT NULL                    -- used by: register_user_in_db()
                                                       --   value format: "DD-Month-YYYY"
);


-- ----------------------------------------------------------------
-- TABLE: attendance
--
-- Columns used in app.py:
--   id       ← ORDER BY id ASC  in extract_attendance()
--   user_id  ← INSERT INTO attendance (user_id, ...)
--              holds users.id — FK enforces referential integrity
--   name     ← INSERT INTO attendance (..., name, ...)
--              SELECT name FROM attendance  in extract_attendance()
--   roll     ← INSERT INTO attendance (..., roll, ...)
--              SELECT roll FROM attendance  in extract_attendance()
--              UNIQUE(roll, date) blocks same person marked twice/day
--   date     ← INSERT INTO attendance (..., date, ...)
--              WHERE date = ?  in extract_attendance()
--              value format: "MM_DD_YY"  e.g. "03_21_26"
--   time     ← INSERT INTO attendance (..., time)
--              SELECT time FROM attendance  in extract_attendance()
--              value format: "HH:MM:SS"  e.g. "09:15:42"
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS attendance (
    id       INTEGER  PRIMARY KEY AUTOINCREMENT,
    user_id  INTEGER  NOT NULL,                  -- FK → users.id
    name     TEXT     NOT NULL,                  -- denormalised for fast SELECT display
    roll     INTEGER  NOT NULL,                  -- denormalised for fast SELECT display
    date     TEXT     NOT NULL,                  -- format: MM_DD_YY
    time     TEXT     NOT NULL,                  -- format: HH:MM:SS

    -- Blocks the same person being marked twice on the same day.
    -- Replaces the old CSV check: if int(userid) not in list(df['Roll'])
    UNIQUE (roll, date),

    -- Cascade delete: removing a user wipes their attendance history too
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);


-- ----------------------------------------------------------------
-- INDEXES
-- Speeds up the two most frequent queries as data grows:
--   WHERE date = ?   (called every page load)
--   WHERE roll = ?   (called every face recognition hit)
-- ----------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance (date);
CREATE INDEX IF NOT EXISTS idx_attendance_roll ON attendance (roll);
