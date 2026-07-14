#!/usr/bin/env python3
"""
Generate a demo JSON backup for the Money Manager app.
User: Krishna | Currency: INR | PIN: 1234
Salary: ₹89,000/month on 1st
4 Accounts: HDFC (Salary), ICICI (Daily), Axis (Savings), SBI (Investment)
Last 4 months of data: April–July 2026 (July is the current month)
"""

import json
import hashlib
import os

OUTPUT_PATH = os.path.join(os.path.dirname(__file__), '..', 'demo_money_manager.json')

PIN_HASH = hashlib.sha256(b'1234').hexdigest()

# ─── Helper ───
def iso(year, month, day, hour=9, minute=0):
    return f"{year}-{month:02d}-{day:02d}T{hour:02d}:{minute:02d}:00.000"

def main():
    data = {}

    # ═══════════════════════════════════════════════════════
    # 1. USER PROFILE
    # ═══════════════════════════════════════════════════════
    data['user_profile'] = [{
        'id': 1,
        'name': 'Krishna',
        'preferred_currency': 'INR',
        'pin_hash': PIN_HASH,
        'biometric_enabled': 0,
        'theme_preference': 'dark',
        'reminder_enabled': 1,
        'reminder_time': '20:00'
    }]

    # ═══════════════════════════════════════════════════════
    # 2. ACCOUNTS
    # ═══════════════════════════════════════════════════════
    accounts = [
        {'id': 1, 'name': 'HDFC Savings',  'type': 'bank', 'balance': 0.0, 'icon': 'account_balance',        'color': '1565C0', 'is_shared': 1, 'limit_amount': None, 'created_at': iso(2026,3,15,10,0)},
        {'id': 2, 'name': 'ICICI Daily',   'type': 'bank', 'balance': 0.0, 'icon': 'account_balance_wallet', 'color': 'F57C00', 'is_shared': 1, 'limit_amount': None, 'created_at': iso(2026,3,15,10,5)},
        {'id': 3, 'name': 'Axis Savings',  'type': 'bank', 'balance': 0.0, 'icon': 'savings',                'color': '7B1FA2', 'is_shared': 1, 'limit_amount': None, 'created_at': iso(2026,3,15,10,10)},
        {'id': 4, 'name': 'SBI Investment','type': 'bank', 'balance': 0.0, 'icon': 'trending_up',            'color': '2E7D32', 'is_shared': 1, 'limit_amount': None, 'created_at': iso(2026,3,15,10,15)},
    ]

    # ═══════════════════════════════════════════════════════
    # 3. CATEGORIES
    # ═══════════════════════════════════════════════════════
    categories = [
        # Default categories
        {'id': 1,  'name': 'Food',                'icon': 'fastfood',        'color': 'E53935', 'is_default': 1, 'type': 'expense', 'parent_id': None, 'spending_limit': None, 'dark_color': None},
        {'id': 2,  'name': 'Rent',                'icon': 'home',            'color': '1E88E5', 'is_default': 1, 'type': 'expense', 'parent_id': None, 'spending_limit': None, 'dark_color': None},
        {'id': 3,  'name': 'Salary',              'icon': 'payments',        'color': '4CAF50', 'is_default': 1, 'type': 'income',  'parent_id': None, 'spending_limit': None, 'dark_color': None},
        {'id': 4,  'name': 'Transport',            'icon': 'directions_bus',  'color': 'FFB300', 'is_default': 1, 'type': 'expense', 'parent_id': None, 'spending_limit': None, 'dark_color': None},
        {'id': 5,  'name': 'Entertainment',        'icon': 'movie',           'color': '8E24AA', 'is_default': 1, 'type': 'expense', 'parent_id': None, 'spending_limit': None, 'dark_color': None},
        {'id': 6,  'name': 'Health',               'icon': 'local_hospital', 'color': '00ACC1', 'is_default': 1, 'type': 'expense', 'parent_id': None, 'spending_limit': None, 'dark_color': None},
        {'id': 7,  'name': 'Utilities',            'icon': 'power',           'color': 'FB8C00', 'is_default': 1, 'type': 'expense', 'parent_id': None, 'spending_limit': None, 'dark_color': None},
        {'id': 8,  'name': 'Credit Card Payment',  'icon': 'credit_card',     'color': 'E53935', 'is_default': 1, 'type': 'expense', 'parent_id': None, 'spending_limit': None, 'dark_color': None},
        {'id': 9,  'name': 'Other',                'icon': 'category',        'color': '757575', 'is_default': 1, 'type': 'both',    'parent_id': None, 'spending_limit': None, 'dark_color': None},
        # Custom categories
        {'id': 10, 'name': 'Shopping',             'icon': 'shopping_bag',    'color': 'FF7043', 'is_default': 0, 'type': 'expense', 'parent_id': None, 'spending_limit': None, 'dark_color': None},
        {'id': 11, 'name': 'Personal Care',        'icon': 'spa',             'color': '26A69A', 'is_default': 0, 'type': 'expense', 'parent_id': None, 'spending_limit': None, 'dark_color': None},
    ]

    # ═══════════════════════════════════════════════════════
    # 4. TRANSACTIONS — 4 months of data (April–July 2026)
    # ═══════════════════════════════════════════════════════
    tx = []
    tx_id = 0
    bal = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0}

    def add_income(acc, cat, title, amount, date, note='', tags='', recurrence='none', subcat=None):
        nonlocal tx_id
        tx_id += 1
        bal[acc] += amount
        tx.append({
            'id': tx_id, 'account_id': acc, 'category_id': cat,
            'title': title, 'amount': amount, 'type': 'income',
            'date': date, 'note': note, 'recurrence': recurrence,
            'recurrence_end_date': None, 'is_private': 0, 'tags': tags,
            'parent_id': None, 'transfer_to_account_id': None,
            'created_at': date, 'subcategory_id': subcat
        })

    def add_expense(acc, cat, title, amount, date, note='', tags='', recurrence='none', subcat=None):
        nonlocal tx_id
        tx_id += 1
        bal[acc] -= amount
        tx.append({
            'id': tx_id, 'account_id': acc, 'category_id': cat,
            'title': title, 'amount': amount, 'type': 'expense',
            'date': date, 'note': note, 'recurrence': recurrence,
            'recurrence_end_date': None, 'is_private': 0, 'tags': tags,
            'parent_id': None, 'transfer_to_account_id': None,
            'created_at': date, 'subcategory_id': subcat
        })

    def add_transfer(src, dst, cat, title, amount, date, note=''):
        nonlocal tx_id
        tx_id += 1
        bal[src] -= amount
        bal[dst] += amount
        tx.append({
            'id': tx_id, 'account_id': src, 'category_id': cat,
            'title': title, 'amount': amount, 'type': 'transfer',
            'date': date, 'note': note, 'recurrence': 'none',
            'recurrence_end_date': None, 'is_private': 0, 'tags': '',
            'parent_id': None, 'transfer_to_account_id': dst,
            'created_at': date, 'subcategory_id': None
        })

    # Random expenses per month (4 per month, all kept on or before 11th for July safety)
    random_expenses = {
        4: [
            (2, 4,  'Cab to Airport',     850,  7, 14, 30, 'Airport trip for family pickup'),
            (2, 6,  'Pharmacy',            780, 11, 11, 15, 'Cold and flu medicines'),
            (2, 1,  'Coffee Meetup',       450,  9, 16, 0,  'Catch-up with college friends'),
            (1, 4,  'Car Service',        2800, 10, 10, 0,  'Quarterly car servicing at workshop'),
        ],
        5: [
            (2, 4,  'Cab to Airport',     850,  7, 14, 30, 'Airport trip for family pickup'),
            (2, 6,  'Pharmacy',            780, 11, 11, 15, 'Cold and flu medicines'),
            (2, 1,  'Coffee Meetup',       450,  9, 16, 0,  'Catch-up with college friends'),
            (1, 4,  'Car Service',        2800, 10, 10, 0,  'Quarterly car servicing at workshop'),
        ],
        6: [
            (2, 4,  'Cab to Airport',     850,  7, 14, 30, 'Airport trip for family pickup'),
            (2, 6,  'Pharmacy',            780, 11, 11, 15, 'Cold and flu medicines'),
            (2, 1,  'Coffee Meetup',       450,  9, 16, 0,  'Catch-up with college friends'),
            (1, 4,  'Car Service',        2800, 10, 10, 0,  'Quarterly car servicing at workshop'),
        ],
        7: [
            (2, 4,  'Cab to Airport',     850,  7, 14, 30, 'Airport trip for family pickup'),
            (2, 6,  'Pharmacy',            780, 11, 11, 15, 'Cold and flu medicines'),
            (2, 1,  'Coffee Meetup',       450,  9, 16, 0,  'Catch-up with college friends'),
            (1, 4,  'Car Service',        2800, 10, 10, 0,  'Quarterly car servicing at workshop'),
        ],
    }

    for month in [4, 5, 6, 7]:
        year = 2026
        is_last_month = (month == 7)

        # ── SALARY ₹89,000 on 1st ──
        add_income(1, 3, 'Monthly Salary', 89000.0,
                   iso(year, month, 1, 9, 30),
                   note='Salary credited for the month',
                   tags='salary,income',
                   recurrence='monthly' if is_last_month else 'none')

        # ── TRANSFERS from HDFC on 2nd–3rd ──
        add_transfer(1, 2, 9, 'Transfer to ICICI for Expenses', 30000.0,
                     iso(year, month, 2, 10, 0),
                     note='Monthly fund allocation for daily expenses')

        add_transfer(1, 3, 9, 'Transfer to Axis Savings', 15000.0,
                     iso(year, month, 2, 10, 15),
                     note='Monthly savings allocation')

        add_transfer(1, 4, 9, 'Transfer to SBI Investment', 10000.0,
                     iso(year, month, 3, 10, 0),
                     note='Monthly investment contribution')

        # ── UTILITIES ₹6,500 on 4th (from HDFC) ──
        add_expense(1, 7, 'Electricity & Water Bill', 6500.0,
                    iso(year, month, 4, 14, 0),
                    note='Monthly utility bills',
                    tags='utilities,bills')

        # ── RENT ₹13,500 on 5th (from HDFC) ──
        add_expense(1, 2, 'House Rent', 13500.0,
                    iso(year, month, 5, 10, 0),
                    note='Monthly rent payment',
                    tags='rent,fixed',
                    recurrence='monthly' if is_last_month else 'none')

        # ── DINING OUT & SNACKS ₹3,500 on 6th (from ICICI) ──
        add_expense(2, 1, 'Dining Out & Snacks', 3500.0,
                    iso(year, month, 6, 20, 0),
                    note='Restaurant meals and street food',
                    tags='food,dining')

        # ── ENTERTAINMENT & OUTINGS ₹3,500 on 7th (from ICICI) ──
        add_expense(2, 5, 'Entertainment & Outings', 3500.0,
                    iso(year, month, 7, 19, 0),
                    note='Movies, games, and leisure activities',
                    tags='entertainment,personal')

        # ── ONLINE SHOPPING ₹5,000 on 8th (from ICICI) ──
        add_expense(2, 10, 'Online Shopping', 5000.0,
                    iso(year, month, 8, 13, 0),
                    note='Amazon/Flipkart purchases',
                    tags='shopping,personal')

        # ── GROCERIES ₹9,000 on 10th (from ICICI) ──
        add_expense(2, 1, 'Grocery Shopping', 9000.0,
                    iso(year, month, 10, 11, 30),
                    note='Monthly grocery supplies from BigBasket/DMart',
                    tags='groceries,food')

        # ── PERSONAL CARE & GROOMING ₹3,000 on 11th (from ICICI) ──
        add_expense(2, 11, 'Personal Care & Grooming', 3000.0,
                    iso(year, month, 11, 16, 0),
                    note='Salon, skincare, and grooming',
                    tags='personal,care')

        # ── RANDOM EXPENSES (4 per month) ──
        for (acc, cat, title, amount, day, hr, mn, note) in random_expenses[month]:
            add_expense(acc, cat, title, amount,
                        iso(year, month, day, hr, mn),
                        note=note)

    # ── Update account balances ──
    for acc in accounts:
        acc['balance'] = round(bal[acc['id']], 2)

    data['account'] = accounts
    data['category'] = categories
    data['transaction_log'] = tx

    # ═══════════════════════════════════════════════════════
    # 5. BUDGETS — Monthly limits for key categories
    # ═══════════════════════════════════════════════════════
    budgets = []
    budget_id = 0
    budget_limits = [
        (1,  'Food',          15000.0, 'Essentials'),
        (2,  'Rent',          14000.0, 'Essentials'),
        (4,  'Transport',      5000.0, 'Essentials'),
        (5,  'Entertainment',  5000.0, 'Lifestyle'),
        (7,  'Utilities',      7000.0, 'Essentials'),
        (10, 'Shopping',       6000.0, 'Lifestyle'),
        (11, 'Personal Care',  4000.0, 'Lifestyle'),
        (6,  'Health',         3000.0, 'Essentials'),
    ]
    for month in ['2026-04', '2026-05', '2026-06', '2026-07']:
        for (cat_id, _, limit, group) in budget_limits:
            budget_id += 1
            budgets.append({
                'id': budget_id,
                'category_id': cat_id,
                'month': month,
                'limit_amount': limit,
                'recurrence': 'monthly',
                'group_name': group,
            })

    data['budget'] = budgets

    # ═══════════════════════════════════════════════════════
    # 6. EMPTY TABLES
    # ═══════════════════════════════════════════════════════
    data['savings_goal'] = []
    data['debt_loan'] = []
    data['filter_preset'] = []
    data['diagnostic_profile'] = []

    # ═══════════════════════════════════════════════════════
    # WRITE JSON
    # ═══════════════════════════════════════════════════════
    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    # ── Print summary ──
    print(f"User: Krishna | Currency: INR | PIN: 1234\n")
    print(f"Accounts:")
    for acc in accounts:
        print(f"  {acc['name']:20s} Rs.{acc['balance']:>10,.2f}")
    print(f"\nTransactions: {len(tx)} total ({len(tx)//4} per month)")
    print(f"Categories:   {len(categories)}")
    print(f"Budgets:      {len(budgets)}")
    print(f"\nMonthly Breakdown:")
    for month in [4, 5, 6, 7]:
        month_str = f'2026-{month:02d}'
        income = sum(t['amount'] for t in tx if t['type'] == 'income' and t['date'].startswith(month_str))
        expense = sum(t['amount'] for t in tx if t['type'] == 'expense' and t['date'].startswith(month_str))
        transfers = sum(t['amount'] for t in tx if t['type'] == 'transfer' and t['date'].startswith(month_str))
        print(f"  {month_str}: Income Rs.{income:>10,.2f} | Expenses Rs.{expense:>10,.2f} | Transfers Rs.{transfers:>10,.2f} | Savings Rs.{income - expense:>10,.2f}")

    abs_path = os.path.abspath(OUTPUT_PATH)
    print(f"\n[OK] JSON backup created: {abs_path}")
    print(f"     Size: {os.path.getsize(abs_path) / 1024:.1f} KB")

if __name__ == '__main__':
    main()
