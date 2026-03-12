"""
Database Module - SQLite
Lưu trữ lịch sử can thiệp, trọng số AHP, thông tin mô hình
"""
import sqlite3
import os
import json
import pandas as pd
import numpy as np

DB_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'data', 'dss_database.db'
)


def get_connection():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_connection()
    c = conn.cursor()

    c.execute('''CREATE TABLE IF NOT EXISTS interventions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_name TEXT NOT NULL,
        class_name TEXT,
        intervention_type TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'Chưa thực hiện',
        result TEXT,
        created_at TEXT DEFAULT (datetime('now','localtime')),
        updated_at TEXT DEFAULT (datetime('now','localtime'))
    )''')

    c.execute('''CREATE TABLE IF NOT EXISTS ahp_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        criteria_json TEXT NOT NULL,
        weights_json TEXT NOT NULL,
        matrix_json TEXT NOT NULL,
        ci REAL,
        cr REAL,
        is_consistent INTEGER,
        created_at TEXT DEFAULT (datetime('now','localtime'))
    )''')

    c.execute('''CREATE TABLE IF NOT EXISTS model_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        features_json TEXT,
        accuracy REAL,
        precision_val REAL,
        recall_val REAL,
        f1_val REAL,
        max_depth INTEGER,
        min_samples_leaf INTEGER,
        threshold REAL DEFAULT 0.5,
        created_at TEXT DEFAULT (datetime('now','localtime'))
    )''')

    conn.commit()
    conn.close()


# ── Intervention CRUD ─────────────────────────────────────────

def add_intervention(student_name, class_name, intervention_type, description=''):
    conn = get_connection()
    c = conn.cursor()
    c.execute(
        '''INSERT INTO interventions
           (student_name, class_name, intervention_type, description)
           VALUES (?, ?, ?, ?)''',
        (student_name, class_name, intervention_type, description)
    )
    conn.commit()
    conn.close()


def get_interventions(student_name=None):
    conn = get_connection()
    c = conn.cursor()
    if student_name:
        c.execute(
            'SELECT * FROM interventions WHERE student_name = ? ORDER BY created_at DESC',
            (student_name,)
        )
    else:
        c.execute('SELECT * FROM interventions ORDER BY created_at DESC')
    rows = c.fetchall()
    conn.close()
    if not rows:
        return pd.DataFrame(columns=[
            'id', 'student_name', 'class_name', 'intervention_type',
            'description', 'status', 'result', 'created_at', 'updated_at'
        ])
    return pd.DataFrame([dict(r) for r in rows])


def update_intervention(intervention_id, status, result=''):
    conn = get_connection()
    c = conn.cursor()
    c.execute(
        '''UPDATE interventions
           SET status = ?, result = ?, updated_at = datetime('now','localtime')
           WHERE id = ?''',
        (status, result, intervention_id)
    )
    conn.commit()
    conn.close()


def delete_intervention(intervention_id):
    conn = get_connection()
    c = conn.cursor()
    c.execute('DELETE FROM interventions WHERE id = ?', (intervention_id,))
    conn.commit()
    conn.close()


# ── AHP History ───────────────────────────────────────────────

def save_ahp_result(criteria, weights, matrix, ci, cr, is_consistent):
    conn = get_connection()
    c = conn.cursor()
    c.execute(
        '''INSERT INTO ahp_history
           (criteria_json, weights_json, matrix_json, ci, cr, is_consistent)
           VALUES (?, ?, ?, ?, ?, ?)''',
        (json.dumps(criteria, ensure_ascii=False),
         json.dumps(weights.tolist() if isinstance(weights, np.ndarray) else list(weights)),
         json.dumps(matrix.tolist() if isinstance(matrix, np.ndarray) else matrix),
         float(ci), float(cr), int(is_consistent))
    )
    conn.commit()
    conn.close()


def get_latest_ahp():
    conn = get_connection()
    c = conn.cursor()
    c.execute('SELECT * FROM ahp_history ORDER BY created_at DESC LIMIT 1')
    row = c.fetchone()
    conn.close()
    if row:
        return {
            'criteria': json.loads(row['criteria_json']),
            'weights': np.array(json.loads(row['weights_json'])),
            'matrix': np.array(json.loads(row['matrix_json'])),
            'ci': row['ci'],
            'cr': row['cr'],
            'is_consistent': bool(row['is_consistent']),
        }
    return None


# ── Model History ─────────────────────────────────────────────

def save_model_info(features, accuracy, precision_val, recall_val, f1_val,
                    max_depth, min_samples_leaf, threshold=0.5):
    conn = get_connection()
    c = conn.cursor()
    c.execute(
        '''INSERT INTO model_history
           (features_json, accuracy, precision_val, recall_val, f1_val,
            max_depth, min_samples_leaf, threshold)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        (json.dumps(features, ensure_ascii=False),
         accuracy, precision_val, recall_val, f1_val,
         max_depth, min_samples_leaf, threshold)
    )
    conn.commit()
    conn.close()


def get_latest_model_info():
    conn = get_connection()
    c = conn.cursor()
    c.execute('SELECT * FROM model_history ORDER BY created_at DESC LIMIT 1')
    row = c.fetchone()
    conn.close()
    return dict(row) if row else None
