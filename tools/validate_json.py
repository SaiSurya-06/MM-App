import json
import os

def validate():
    json_path = os.path.join(os.path.dirname(__file__), '..', 'demo_money_manager.json')
    if not os.path.exists(json_path):
        print(f"File not found: {json_path}")
        return

    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 1. Check top level keys (tables)
    expected_tables = [
        'user_profile', 'account', 'category', 'transaction_log',
        'budget', 'savings_goal', 'debt_loan', 'filter_preset', 'diagnostic_profile'
    ]
    for table in expected_tables:
        if table not in data:
            print(f"[-] Missing expected table: {table}")
        else:
            print(f"[+] Found table: {table} ({len(data[table])} rows)")

    # 2. Check schemas
    # user_profile schema: id, name, preferred_currency, pin_hash, biometric_enabled, theme_preference, reminder_enabled, reminder_time
    if 'user_profile' in data:
        for r in data['user_profile']:
            for field in ['id', 'name', 'preferred_currency', 'pin_hash', 'biometric_enabled', 'theme_preference', 'reminder_enabled', 'reminder_time']:
                if field not in r:
                    print(f"[-] user_profile missing field: {field}")
                elif r[field] is None:
                    print(f"[-] user_profile {field} is null (not allowed)")

    # account schema: id, name, type, balance, icon, color, is_shared, limit_amount, created_at
    if 'account' in data:
        for r in data['account']:
            for field in ['id', 'name', 'type', 'balance', 'icon', 'color', 'is_shared', 'created_at']:
                if field not in r:
                    print(f"[-] account missing field: {field}")
                elif r[field] is None:
                    print(f"[-] account {field} is null (not allowed)")

    # category schema: id, name, icon, color, is_default, type, parent_id, spending_limit, dark_color
    if 'category' in data:
        for r in data['category']:
            for field in ['id', 'name', 'icon', 'color', 'is_default', 'type']:
                if field not in r:
                    print(f"[-] category missing field: {field}")
                elif r[field] is None:
                    print(f"[-] category {field} is null (not allowed)")

    # transaction_log schema: id, account_id, category_id, title, amount, type, date, note, recurrence, recurrence_end_date, is_private, tags, parent_id, transfer_to_account_id, created_at, subcategory_id
    if 'transaction_log' in data:
        for r in data['transaction_log']:
            for field in ['id', 'account_id', 'category_id', 'title', 'amount', 'type', 'date', 'recurrence', 'is_private', 'tags', 'created_at']:
                if field not in r:
                    print(f"[-] transaction_log missing field: {field}")
                elif r[field] is None:
                    print(f"[-] transaction_log {field} is null (not allowed)")

            # Check foreign keys
            acc_ids = [a['id'] for a in data['account']]
            cat_ids = [c['id'] for c in data['category']]
            if r.get('account_id') not in acc_ids:
                print(f"[-] transaction_log {r['id']} references invalid account_id: {r['account_id']}")
            if r.get('category_id') not in cat_ids:
                print(f"[-] transaction_log {r['id']} references invalid category_id: {r['category_id']}")
            if r.get('transfer_to_account_id') is not None and r.get('transfer_to_account_id') not in acc_ids:
                print(f"[-] transaction_log {r['id']} references invalid transfer_to_account_id: {r['transfer_to_account_id']}")

    # budget schema: id, category_id, month, limit_amount, recurrence, group_name
    if 'budget' in data:
        for r in data['budget']:
            for field in ['id', 'category_id', 'month', 'limit_amount', 'recurrence']:
                if field not in r:
                    print(f"[-] budget missing field: {field}")
                elif r[field] is None:
                    print(f"[-] budget {field} is null (not allowed)")
            if r.get('category_id') not in cat_ids:
                print(f"[-] budget {r['id']} references invalid category_id: {r['category_id']}")

    print("[*] Schema validation complete.")

if __name__ == '__main__':
    validate()
