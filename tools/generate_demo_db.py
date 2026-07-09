#!/usr/bin/env python3
"""
Generate a demo SQLite database for the Money Manager app.
User: Krishna | Currency: INR | PIN: 1234
Income: ₹72,000/month salary
Expenses: Realistic spread across all categories for last 4 months.
"""

import sqlite3
import hashlib
import random
import os
import json
from datetime import datetime, timedelta

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'demo_money_manager.db')

# ── PIN hash (SHA-256 of "1234") ──
PIN_HASH = hashlib.sha256(b'1234').hexdigest()

# ── Date helpers ──
NOW = datetime(2026, 7, 8, 18, 0, 0)
MONTHS_BACK = 4  # March, April, May, June 2026

def iso(dt):
    return dt.strftime('%Y-%m-%dT%H:%M:%S.000')

def random_time(dt):
    """Add random hour/minute to a date."""
    return dt.replace(hour=random.randint(7, 22), minute=random.randint(0, 59), second=random.randint(0, 59))

def main():
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    # ═══════════════════════════════════════════════
    # 1. CREATE ALL TABLES (matching database.dart v10)
    # ═══════════════════════════════════════════════

    c.execute('''CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        preferred_currency TEXT NOT NULL,
        pin_hash TEXT NOT NULL,
        biometric_enabled INTEGER NOT NULL DEFAULT 0,
        theme_preference TEXT NOT NULL DEFAULT 'dark',
        reminder_enabled INTEGER NOT NULL DEFAULT 1,
        reminder_time TEXT NOT NULL DEFAULT '20:00'
    )''')

    c.execute('''CREATE TABLE account (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        is_shared INTEGER NOT NULL DEFAULT 1,
        limit_amount REAL,
        created_at TEXT NOT NULL
    )''')

    c.execute('''CREATE TABLE category (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        type TEXT NOT NULL DEFAULT 'both',
        parent_id INTEGER,
        spending_limit REAL,
        dark_color TEXT
    )''')

    c.execute('''CREATE TABLE transaction_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        recurrence TEXT NOT NULL DEFAULT 'none',
        recurrence_end_date TEXT,
        is_private INTEGER NOT NULL DEFAULT 0,
        tags TEXT NOT NULL DEFAULT '',
        parent_id INTEGER,
        transfer_to_account_id INTEGER,
        created_at TEXT NOT NULL,
        subcategory_id INTEGER,
        FOREIGN KEY (account_id) REFERENCES account (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE,
        FOREIGN KEY (subcategory_id) REFERENCES category (id) ON DELETE SET NULL
    )''')

    c.execute('''CREATE TABLE budget (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        recurrence TEXT NOT NULL DEFAULT 'monthly',
        group_name TEXT,
        FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE
    )''')

    c.execute('''CREATE TABLE partner_snapshot (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        partner_name TEXT NOT NULL,
        partner_display_color TEXT NOT NULL,
        encoded_data TEXT NOT NULL,
        imported_at TEXT NOT NULL,
        partner_key TEXT NOT NULL DEFAULT ''
    )''')

    c.execute('''CREATE TABLE savings_goal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0.0,
        target_date TEXT,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        created_at TEXT NOT NULL
    )''')

    c.execute('''CREATE TABLE debt_loan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        original_amount REAL NOT NULL,
        interest_rate REAL NOT NULL,
        monthly_payment REAL NOT NULL,
        start_date TEXT NOT NULL,
        created_at TEXT NOT NULL
    )''')

    c.execute('''CREATE TABLE filter_preset (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        filters_json TEXT NOT NULL
    )''')

    c.execute('''CREATE TABLE transaction_template (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL
    )''')

    c.execute('''CREATE TABLE health_score_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        score REAL NOT NULL
    )''')

    c.execute('''CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        record_data TEXT NOT NULL,
        created_at TEXT NOT NULL
    )''')

    c.execute('''CREATE TABLE diagnostic_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_profile_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        current_act INTEGER NOT NULL DEFAULT 0,
        current_section INTEGER NOT NULL DEFAULT 0,
        completed INTEGER NOT NULL DEFAULT 0,
        profile_json TEXT NOT NULL
    )''')

    # ═══════════════════════════════════════════════
    # 2. USER PROFILE
    # ═══════════════════════════════════════════════

    c.execute('''INSERT INTO user_profile (name, preferred_currency, pin_hash, biometric_enabled, theme_preference, reminder_enabled, reminder_time)
                 VALUES (?, ?, ?, ?, ?, ?, ?)''',
              ('Krishna', 'INR', PIN_HASH, 0, 'dark', 1, '20:00'))

    # ═══════════════════════════════════════════════
    # 3. ACCOUNTS
    # ═══════════════════════════════════════════════

    accounts = [
        # id=1: Main bank account
        ('HDFC Savings', 'bank', 0.0, 'account_balance', '1E88E5', 1, None, iso(NOW - timedelta(days=120))),
        # id=2: Cash wallet
        ('Cash', 'cash', 0.0, 'account_balance_wallet', '4CAF50', 1, None, iso(NOW - timedelta(days=120))),
        # id=3: Credit card
        ('ICICI Credit Card', 'credit_card', 0.0, 'credit_card', 'E53935', 1, 100000.0, iso(NOW - timedelta(days=120))),
        # id=4: UPI
        ('Google Pay', 'digital', 0.0, 'phone_android', '4285F4', 1, None, iso(NOW - timedelta(days=90))),
    ]
    for a in accounts:
        c.execute('''INSERT INTO account (name, type, balance, icon, color, is_shared, limit_amount, created_at)
                     VALUES (?,?,?,?,?,?,?,?)''', a)

    # ═══════════════════════════════════════════════
    # 4. CATEGORIES (default + subcategories)
    # ═══════════════════════════════════════════════

    # Default parent categories (IDs 1–9)
    default_cats = [
        ('Food', 'fastfood', 'E53935', 1, 'expense', None, 15000.0, None),          # 1
        ('Rent', 'home', '1E88E5', 1, 'expense', None, 20000.0, None),              # 2
        ('Salary', 'payments', '4CAF50', 1, 'income', None, None, None),             # 3
        ('Transport', 'directions_bus', 'FFB300', 1, 'expense', None, 5000.0, None), # 4
        ('Entertainment', 'movie', '8E24AA', 1, 'expense', None, 5000.0, None),      # 5
        ('Health', 'local_hospital', '00ACC1', 1, 'expense', None, 3000.0, None),    # 6
        ('Utilities', 'power', 'FB8C00', 1, 'expense', None, 5000.0, None),         # 7
        ('Credit Card Payment', 'credit_card', 'E53935', 1, 'expense', None, None, None),  # 8
        ('Other', 'category', '757575', 1, 'both', None, None, None),               # 9
    ]
    for cat in default_cats:
        c.execute('''INSERT INTO category (name, icon, color, is_default, type, parent_id, spending_limit, dark_color)
                     VALUES (?,?,?,?,?,?,?,?)''', cat)

    # P2P Categories
    c.execute('''INSERT INTO category (name, icon, color, is_default, type, parent_id, spending_limit, dark_color)
                 VALUES (?,?,?,?,?,?,?,?)''', ('Person 1', 'person', '9C27B0', 0, 'person', None, None, '4A148C'))  # 10
    c.execute('''INSERT INTO category (name, icon, color, is_default, type, parent_id, spending_limit, dark_color)
                 VALUES (?,?,?,?,?,?,?,?)''', ('Person 2', 'person', 'E91E63', 0, 'person', None, None, '880E4F'))  # 11

    # Subcategories (parent_id links to parent category)
    subcategories = [
        # Food subcategories (parent_id=1)
        ('Groceries', 'shopping_cart', 'EF5350', 0, 'expense', 1, None, None),       # 12
        ('Restaurants', 'restaurant', 'F44336', 0, 'expense', 1, None, None),        # 13
        ('Snacks & Beverages', 'local_cafe', 'E57373', 0, 'expense', 1, None, None), # 14
        ('Swiggy/Zomato', 'delivery_dining', 'D32F2F', 0, 'expense', 1, None, None), # 15

        # Transport subcategories (parent_id=4)
        ('Fuel', 'local_gas_station', 'FFA726', 0, 'expense', 4, None, None),        # 16
        ('Auto/Cab', 'local_taxi', 'FFB74D', 0, 'expense', 4, None, None),           # 17
        ('Metro/Bus', 'train', 'FF8F00', 0, 'expense', 4, None, None),               # 18

        # Entertainment subcategories (parent_id=5)
        ('Movies', 'movie', '9C27B0', 0, 'expense', 5, None, None),                  # 19
        ('Subscriptions', 'subscriptions', 'AB47BC', 0, 'expense', 5, None, None),    # 20
        ('Gaming', 'sports_esports', '7B1FA2', 0, 'expense', 5, None, None),         # 21

        # Health subcategories (parent_id=6)
        ('Medicines', 'medication', '00BCD4', 0, 'expense', 6, None, None),           # 22
        ('Gym', 'fitness_center', '0097A7', 0, 'expense', 6, None, None),             # 23
        ('Doctor Visit', 'medical_services', '00838F', 0, 'expense', 6, None, None),  # 24

        # Utilities subcategories (parent_id=7)
        ('Electricity', 'bolt', 'FF9800', 0, 'expense', 7, None, None),               # 25
        ('Internet', 'wifi', 'EF6C00', 0, 'expense', 7, None, None),                  # 26
        ('Mobile Recharge', 'phone_iphone', 'E65100', 0, 'expense', 7, None, None),   # 27
        ('Water', 'water_drop', 'F57C00', 0, 'expense', 7, None, None),               # 28

        # Salary subcategories (parent_id=3)
        ('Base Salary', 'money', '66BB6A', 0, 'income', 3, None, None),               # 29
        ('Freelance', 'work', '43A047', 0, 'income', 3, None, None),                  # 30

        # Other subcategories (parent_id=9)
        ('Shopping', 'shopping_bag', '9E9E9E', 0, 'expense', 9, None, None),           # 31
        ('Gifts', 'card_giftcard', 'BDBDBD', 0, 'expense', 9, None, None),            # 32
    ]
    for sc in subcategories:
        c.execute('''INSERT INTO category (name, icon, color, is_default, type, parent_id, spending_limit, dark_color)
                     VALUES (?,?,?,?,?,?,?,?)''', sc)

    # ═══════════════════════════════════════════════
    # 5. TRANSACTIONS — 4 months of data
    # ═══════════════════════════════════════════════
    # Months: March 2026 (3), April (4), May (5), June (6)

    random.seed(42)  # Reproducible

    all_transactions = []
    tx_id = 0

    for month in [3, 4, 5, 6]:
        year = 2026
        month_start = datetime(year, month, 1)
        if month == 12:
            month_end = datetime(year + 1, 1, 1) - timedelta(days=1)
        else:
            month_end = datetime(year, month + 1, 1) - timedelta(days=1)
        days_in_month = month_end.day

        # ── INCOME: ₹72,000 salary on 1st of each month ──
        salary_date = random_time(datetime(year, month, 1))
        tx_id += 1
        all_transactions.append((
            1,             # account_id: HDFC Savings
            3,             # category_id: Salary
            'Monthly Salary',
            72000.0,
            'income',
            iso(salary_date),
            'Salary credited for month',
            'monthly',     # recurrence
            None,          # recurrence_end_date
            0,             # is_private
            'salary,income',  # tags
            None,          # parent_id
            None,          # transfer_to_account_id
            iso(salary_date),
            29,            # subcategory_id: Base Salary
        ))

        # ── Occasional freelance income (some months) ──
        if month in [4, 6]:
            fl_date = random_time(datetime(year, month, random.randint(10, 20)))
            fl_amount = random.choice([5000, 8000, 10000, 12000])
            tx_id += 1
            all_transactions.append((
                1, 3, 'Freelance Project', fl_amount, 'income', iso(fl_date),
                'Side project payment', 'none', None, 0, 'freelance,income',
                None, None, iso(fl_date), 30
            ))

        # ── RENT: ₹15,000 on 5th ──
        rent_date = random_time(datetime(year, month, 5))
        tx_id += 1
        all_transactions.append((
            1, 2, 'Monthly Rent', 15000.0, 'expense', iso(rent_date),
            'Rent for the apartment', 'monthly', None, 0, 'rent,fixed',
            None, None, iso(rent_date), None
        ))

        # ── FOOD expenses (8–12 transactions per month) ──
        food_items = [
            ('Groceries - BigBasket', 12, 1500, 3500),
            ('Groceries - D-Mart', 12, 800, 2000),
            ('Dinner at restaurant', 13, 500, 2500),
            ('Swiggy order', 15, 150, 600),
            ('Zomato order', 15, 200, 700),
            ('Tea & Snacks', 14, 50, 200),
            ('Street food', 14, 100, 300),
            ('Weekend brunch', 13, 400, 1200),
        ]
        num_food = random.randint(8, 12)
        for _ in range(num_food):
            item = random.choice(food_items)
            day = random.randint(1, days_in_month)
            fd = random_time(datetime(year, month, day))
            amount = round(random.uniform(item[2], item[3]), 2)
            acct = random.choice([1, 2, 4])  # Bank, Cash, GPay
            tx_id += 1
            all_transactions.append((
                acct, 1, item[0], amount, 'expense', iso(fd),
                None, 'none', None, 0, 'food', None, None, iso(fd), item[1]
            ))

        # ── TRANSPORT (3–5 per month) ──
        transport_items = [
            ('Fuel - Petrol', 16, 800, 2000),
            ('Ola/Uber ride', 17, 100, 500),
            ('Metro pass', 18, 200, 500),
            ('Auto rickshaw', 17, 50, 200),
        ]
        for _ in range(random.randint(3, 5)):
            item = random.choice(transport_items)
            day = random.randint(1, days_in_month)
            td = random_time(datetime(year, month, day))
            amount = round(random.uniform(item[2], item[3]), 2)
            acct = random.choice([1, 2, 4])
            tx_id += 1
            all_transactions.append((
                acct, 4, item[0], amount, 'expense', iso(td),
                None, 'none', None, 0, 'transport', None, None, iso(td), item[1]
            ))

        # ── ENTERTAINMENT (2–4 per month) ──
        ent_items = [
            ('Netflix subscription', 20, 199, 649),
            ('Movie tickets - PVR', 19, 300, 800),
            ('Spotify Premium', 20, 119, 119),
            ('PlayStation game', 21, 500, 3000),
            ('YouTube Premium', 20, 129, 129),
        ]
        for _ in range(random.randint(2, 4)):
            item = random.choice(ent_items)
            day = random.randint(1, days_in_month)
            ed = random_time(datetime(year, month, day))
            amount = round(random.uniform(item[2], item[3]), 2)
            acct = random.choice([1, 3, 4])
            tx_id += 1
            all_transactions.append((
                acct, 5, item[0], amount, 'expense', iso(ed),
                None, 'none', None, 0, 'entertainment', None, None, iso(ed), item[1]
            ))

        # ── HEALTH (1–3 per month) ──
        health_items = [
            ('Gym membership', 23, 1500, 2500),
            ('Medicines from Apollo', 22, 200, 800),
            ('Doctor consultation', 24, 500, 1500),
        ]
        for _ in range(random.randint(1, 3)):
            item = random.choice(health_items)
            day = random.randint(1, days_in_month)
            hd = random_time(datetime(year, month, day))
            amount = round(random.uniform(item[2], item[3]), 2)
            acct = random.choice([1, 2])
            tx_id += 1
            all_transactions.append((
                acct, 6, item[0], amount, 'expense', iso(hd),
                None, 'none', None, 0, 'health', None, None, iso(hd), item[1]
            ))

        # ── UTILITIES (3–4 per month) ──
        util_items = [
            ('Electricity bill', 25, 1200, 2500),
            ('Internet - JioFiber', 26, 999, 999),
            ('Mobile recharge', 27, 239, 599),
            ('Water bill', 28, 200, 500),
        ]
        for item in util_items:
            day = random.randint(5, 20)
            ud = random_time(datetime(year, month, day))
            amount = round(random.uniform(item[2], item[3]), 2)
            acct = random.choice([1, 4])
            tx_id += 1
            all_transactions.append((
                acct, 7, item[0], amount, 'expense', iso(ud),
                None, 'none', None, 0, 'utilities,bills', None, None, iso(ud), item[1]
            ))

        # ── CREDIT CARD PAYMENT (1 per month) ──
        cc_day = random.randint(15, 25)
        cc_date = random_time(datetime(year, month, cc_day))
        cc_amount = round(random.uniform(3000, 8000), 2)
        tx_id += 1
        all_transactions.append((
            1, 8, 'Credit Card Bill Payment', cc_amount, 'expense', iso(cc_date),
            'ICICI CC bill payment', 'none', None, 0, 'credit-card',
            None, None, iso(cc_date), None
        ))

        # ── OTHER: Shopping & Gifts (2–3 per month) ──
        other_items = [
            ('Amazon order', 31, 500, 5000),
            ('Flipkart order', 31, 300, 3000),
            ('Birthday gift', 32, 500, 2000),
            ('Household items', 31, 200, 1000),
        ]
        for _ in range(random.randint(2, 3)):
            item = random.choice(other_items)
            day = random.randint(1, days_in_month)
            od = random_time(datetime(year, month, day))
            amount = round(random.uniform(item[2], item[3]), 2)
            acct = random.choice([1, 3, 4])
            tx_id += 1
            all_transactions.append((
                acct, 9, item[0], amount, 'expense', iso(od),
                None, 'none', None, 0, 'shopping', None, None, iso(od), item[1]
            ))

        # ── TRANSFER: Bank → Cash (1 per month) ──
        tf_day = random.randint(1, 15)
        tf_date = random_time(datetime(year, month, tf_day))
        tf_amount = random.choice([2000, 3000, 5000])
        tx_id += 1
        all_transactions.append((
            1, 9, 'ATM Withdrawal', tf_amount, 'transfer', iso(tf_date),
            'Cash withdrawal from ATM', 'none', None, 0, 'transfer',
            None, 2, iso(tf_date), None  # transfer_to_account_id = 2 (Cash)
        ))

        # ── Private transaction (1 per month for demo) ──
        priv_day = random.randint(10, 25)
        priv_date = random_time(datetime(year, month, priv_day))
        tx_id += 1
        all_transactions.append((
            2, 9, 'Personal expense', round(random.uniform(200, 1500), 2), 'expense', iso(priv_date),
            'Private spending', 'none', None, 1, '',  # is_private = 1
            None, None, iso(priv_date), None
        ))

    # Insert all transactions
    c.executemany('''INSERT INTO transaction_log
        (account_id, category_id, title, amount, type, date, note, recurrence, recurrence_end_date,
         is_private, tags, parent_id, transfer_to_account_id, created_at, subcategory_id)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''', all_transactions)

    # ═══════════════════════════════════════════════
    # 6. RECALCULATE ACCOUNT BALANCES
    # ═══════════════════════════════════════════════

    balances = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0}
    for tx in all_transactions:
        acct_id = tx[0]
        amount = tx[3]
        tx_type = tx[4]
        transfer_to = tx[12]

        if tx_type == 'income':
            balances[acct_id] = balances.get(acct_id, 0) + amount
        elif tx_type in ('expense', 'transfer'):
            balances[acct_id] = balances.get(acct_id, 0) - amount

        if transfer_to is not None:
            balances[transfer_to] = balances.get(transfer_to, 0) + amount

    for acct_id, balance in balances.items():
        c.execute('UPDATE account SET balance = ? WHERE id = ?', (round(balance, 2), acct_id))

    # ═══════════════════════════════════════════════
    # 7. BUDGETS (for current and last 3 months)
    # ═══════════════════════════════════════════════

    budget_data = [
        # (category_id, limit, group_name)
        (1, 12000.0, 'Essentials'),    # Food
        (2, 15000.0, 'Essentials'),    # Rent
        (4, 4000.0, 'Transport'),      # Transport
        (5, 3000.0, 'Lifestyle'),      # Entertainment
        (6, 2500.0, 'Essentials'),     # Health
        (7, 4000.0, 'Essentials'),     # Utilities
        (9, 5000.0, 'Lifestyle'),      # Other
    ]

    for month in [3, 4, 5, 6, 7]:
        month_str = f'2026-{month:02d}'
        for cat_id, limit_amt, group in budget_data:
            c.execute('''INSERT INTO budget (category_id, month, limit_amount, recurrence, group_name)
                         VALUES (?,?,?,?,?)''', (cat_id, month_str, limit_amt, 'monthly', group))

    # ═══════════════════════════════════════════════
    # 8. SAVINGS GOALS
    # ═══════════════════════════════════════════════

    savings_goals = [
        ('Emergency Fund', 300000.0, 85000.0, '2027-03-01T00:00:00.000', '4CAF50', 'savings', iso(NOW - timedelta(days=100))),
        ('New Laptop', 80000.0, 32000.0, '2026-12-31T00:00:00.000', '1E88E5', 'laptop', iso(NOW - timedelta(days=60))),
        ('Goa Trip', 25000.0, 12000.0, '2026-10-15T00:00:00.000', 'FF9800', 'flight', iso(NOW - timedelta(days=45))),
        ('iPhone 16', 120000.0, 20000.0, '2027-06-01T00:00:00.000', '9C27B0', 'phone_iphone', iso(NOW - timedelta(days=30))),
    ]
    for sg in savings_goals:
        c.execute('''INSERT INTO savings_goal (name, target_amount, current_amount, target_date, color, icon, created_at)
                     VALUES (?,?,?,?,?,?,?)''', sg)

    # ═══════════════════════════════════════════════
    # 9. DEBTS & LOANS
    # ═══════════════════════════════════════════════

    debts = [
        ('Education Loan', 'debt', 280000.0, 500000.0, 8.5, 12000.0, '2024-06-01T00:00:00.000', iso(NOW - timedelta(days=365*2))),
        ('Personal Loan', 'debt', 45000.0, 100000.0, 10.0, 5500.0, '2025-01-15T00:00:00.000', iso(NOW - timedelta(days=540))),
        ('Loan to Ravi', 'loan', 8000.0, 15000.0, 0.0, 0.0, '2026-04-01T00:00:00.000', iso(NOW - timedelta(days=99))),
    ]
    for d in debts:
        c.execute('''INSERT INTO debt_loan (name, type, balance, original_amount, interest_rate, monthly_payment, start_date, created_at)
                     VALUES (?,?,?,?,?,?,?,?)''', d)

    # ═══════════════════════════════════════════════
    # 10. TRANSACTION TEMPLATES
    # ═══════════════════════════════════════════════

    templates = [
        ('Monthly Salary', 72000.0, 'income', 3, 1),   # Salary → HDFC
        ('Monthly Rent', 15000.0, 'expense', 2, 1),     # Rent → HDFC
        ('Groceries', 2500.0, 'expense', 1, 4),         # Food → GPay
        ('Fuel', 1500.0, 'expense', 4, 1),              # Transport → HDFC
        ('JioFiber', 999.0, 'expense', 7, 1),           # Utilities → HDFC
        ('Mobile Recharge', 299.0, 'expense', 7, 4),    # Utilities → GPay
    ]
    for t in templates:
        c.execute('''INSERT INTO transaction_template (title, amount, type, category_id, account_id)
                     VALUES (?,?,?,?,?)''', t)

    # ═══════════════════════════════════════════════
    # 11. HEALTH SCORE HISTORY
    # ═══════════════════════════════════════════════

    scores = [
        ('2026-03-31', 62.0),
        ('2026-04-15', 58.0),
        ('2026-04-30', 65.0),
        ('2026-05-15', 68.0),
        ('2026-05-31', 71.0),
        ('2026-06-15', 69.0),
        ('2026-06-30', 73.0),
        ('2026-07-08', 75.0),
    ]
    for s in scores:
        c.execute('''INSERT INTO health_score_history (date, score) VALUES (?,?)''', s)

    # ═══════════════════════════════════════════════
    # 12. FILTER PRESETS
    # ═══════════════════════════════════════════════

    presets = [
        ('High Value Expenses', json.dumps({
            'minAmount': 5000,
            'maxAmount': None,
            'type': 'expense',
            'categories': [],
            'accounts': [],
        })),
        ('Food This Month', json.dumps({
            'minAmount': None,
            'maxAmount': None,
            'type': 'expense',
            'categories': [1],
            'accounts': [],
        })),
        ('All Income', json.dumps({
            'minAmount': None,
            'maxAmount': None,
            'type': 'income',
            'categories': [],
            'accounts': [],
        })),
    ]
    for p in presets:
        c.execute('''INSERT INTO filter_preset (name, filters_json) VALUES (?,?)''', p)

    # ═══════════════════════════════════════════════
    # COMMIT & CLOSE
    # ═══════════════════════════════════════════════

    c.execute('PRAGMA user_version = 10')
    conn.commit()

    # Print summary
    for table in ['user_profile', 'account', 'category', 'transaction_log', 'budget',
                   'savings_goal', 'debt_loan', 'transaction_template', 'health_score_history',
                   'filter_preset']:
        count = c.execute(f'SELECT COUNT(*) FROM {table}').fetchone()[0]
        print(f'  {table}: {count} rows')

    # Print account balances
    print('\nAccount Balances:')
    for row in c.execute('SELECT name, balance FROM account'):
        print(f'  {row[0]}: Rs.{row[1]:,.2f}')

    # Print monthly totals
    print('\nMonthly Summary:')
    for month in [3, 4, 5, 6]:
        month_str = f'2026-{month:02d}'
        income = c.execute("SELECT COALESCE(SUM(amount),0) FROM transaction_log WHERE type='income' AND date LIKE ?", (f'{month_str}%',)).fetchone()[0]
        expense = c.execute("SELECT COALESCE(SUM(amount),0) FROM transaction_log WHERE type='expense' AND date LIKE ?", (f'{month_str}%',)).fetchone()[0]
        print(f'  {month_str}: Income Rs.{income:,.2f} | Expenses Rs.{expense:,.2f} | Savings Rs.{income-expense:,.2f}')

    conn.close()
    abs_path = os.path.abspath(DB_PATH)
    print(f'\n[OK] Database created: {abs_path}')
    print(f'   Size: {os.path.getsize(abs_path) / 1024:.1f} KB')

if __name__ == '__main__':
    main()
