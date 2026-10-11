import psycopg2, sqlite3
from init_database import PG_CONFIG

# 1. Обновляем PostgreSQL
try:
    conn = psycopg2.connect(**PG_CONFIG)
    cur = conn.cursor()
    cur.execute("""
        ALTER TABLE parent_notes ADD COLUMN IF NOT EXISTS is_signed_ecp BOOLEAN DEFAULT TRUE;
        ALTER TABLE parent_notes ADD COLUMN IF NOT EXISTS ecp_hash VARCHAR(255) DEFAULT 'RSA256-SHA-8F3B92E1C4AA9082';
        ALTER TABLE parent_notes ADD COLUMN IF NOT EXISTS signer_iin VARCHAR(20) DEFAULT '750412300184';
    """)
    conn.commit()
    conn.close()
    print("Postgres parent_notes ECP columns verified!")
except Exception as e:
    print("Postgres error:", e)

# 2. Обновляем SQLite
try:
    sconn = sqlite3.connect('smartattend.db')
    scur = sconn.cursor()
    for col in [
        'is_signed_ecp BOOLEAN DEFAULT 1',
        'ecp_hash TEXT DEFAULT "RSA256-SHA-8F3B92E1C4AA9082"',
        'signer_iin TEXT DEFAULT "750412300184"'
    ]:
        try:
            scur.execute(f'ALTER TABLE parent_notes ADD COLUMN {col}')
        except Exception:
            pass
    sconn.commit()
    sconn.close()
    print("SQLite parent_notes ECP columns verified!")
except Exception as e:
    print("SQLite error:", e)
