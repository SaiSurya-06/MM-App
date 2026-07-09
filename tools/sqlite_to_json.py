import sqlite3
import json
import os

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'demo_money_manager.db')
JSON_PATH = os.path.join(os.path.dirname(__file__), '..', 'demo_money_manager.json')

def dict_factory(cursor, row):
    d = {}
    for idx, col in enumerate(cursor.description):
        d[col[0]] = row[idx]
    return d

def main():
    if not os.path.exists(DB_PATH):
        print(f"Error: {DB_PATH} not found!")
        return

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = dict_factory
    cursor = conn.cursor()
    
    tables = [
        'user_profile',
        'account',
        'category',
        'transaction_log',
        'budget',
        'savings_goal',
        'debt_loan',
        'filter_preset',
        'diagnostic_profile'
    ]
    
    data = {}
    for table in tables:
        try:
            cursor.execute(f"SELECT * FROM {table}")
            data[table] = cursor.fetchall()
        except sqlite3.OperationalError as e:
            print(f"Skipping table {table}: {e}")
            
    conn.close()
    
    with open(JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        
    print(f"[OK] Exported {DB_PATH} to {JSON_PATH}")

if __name__ == '__main__':
    main()
