package com.example.money_manager

import android.database.sqlite.SQLiteDatabase
import android.util.Log
import com.google.adk.kt.agents.Instruction
import com.google.adk.kt.agents.LlmAgent
import com.google.adk.kt.annotations.Param
import com.google.adk.kt.annotations.Tool
import com.google.adk.kt.models.Gemini
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class FinanceService(private val dbPathProvider: () -> String) {

    private fun getReadableDatabase(): SQLiteDatabase? {
        val dbPath = dbPathProvider()
        return try {
            val file = File(dbPath)
            if (!file.exists()) {
                Log.e("FinanceService", "Database file does not exist at $dbPath")
                return null
            }
            SQLiteDatabase.openDatabase(dbPath, null, SQLiteDatabase.OPEN_READONLY or SQLiteDatabase.NO_LOCALIZED_COLLATORS)
        } catch (e: Exception) {
            Log.e("FinanceService", "Error opening database: ${e.message}")
            null
        }
    }

    private fun getCurrencySymbol(db: SQLiteDatabase): String {
        return try {
            val cursor = db.rawQuery("SELECT preferred_currency FROM user_profile LIMIT 1", null)
            var symbol = "$"
            if (cursor.moveToFirst()) {
                val code = cursor.getString(0).uppercase(Locale.ROOT)
                symbol = when (code) {
                    "INR" -> "₹"
                    "EUR" -> "€"
                    "GBP" -> "£"
                    "JPY" -> "¥"
                    "AUD" -> "A$"
                    "CAD" -> "C$"
                    else -> "$code "
                }
            }
            cursor.close()
            symbol
        } catch (e: Exception) {
            "$"
        }
    }

    @Tool
    fun getAccountBalances(): String {
        val db = getReadableDatabase() ?: return "Error: Database not accessible"
        val buffer = StringBuilder()
        try {
            val symbol = getCurrencySymbol(db)
            val cursor = db.rawQuery("SELECT name, type, balance FROM account", null)
            if (cursor.moveToFirst()) {
                do {
                    val name = cursor.getString(0)
                    val type = cursor.getString(1)
                    val balance = cursor.getDouble(2)
                    buffer.append("- $name ($type): $symbol$balance\n")
                } while (cursor.moveToNext())
            } else {
                buffer.append("No accounts found.")
            }
            cursor.close()
        } catch (e: Exception) {
            Log.e("FinanceService", "getAccountBalances query failed: ${e.message}")
            return "Error querying account balances"
        } finally {
            db.close()
        }
        return buffer.toString()
    }

    @Tool
    fun getSpendingByCategoryForMonth(
        @Param("The month to analyze in YYYY-MM format. Defaults to current month if empty.") month: String
    ): String {
        val db = getReadableDatabase() ?: return "Error: Database not accessible"
        val targetMonth = if (month.isNullOrBlank()) {
            SimpleDateFormat("yyyy-MM", Locale.getDefault()).format(Date())
        } else {
            month
        }
        val buffer = StringBuilder()
        try {
            val symbol = getCurrencySymbol(db)
            val cursor = db.rawQuery(
                "SELECT c.name, SUM(t.amount) " +
                "FROM transaction_log t " +
                "JOIN category c ON t.category_id = c.id " +
                "WHERE t.type = 'expense' AND strftime('%Y-%m', t.date) = ? " +
                "GROUP BY c.name " +
                "ORDER BY SUM(t.amount) DESC",
                arrayOf(targetMonth)
            )
            if (cursor.moveToFirst()) {
                buffer.append("Spending by category for $targetMonth:\n")
                do {
                    val catName = cursor.getString(0)
                    val total = cursor.getDouble(1)
                    buffer.append("- $catName: $symbol$total\n")
                } while (cursor.moveToNext())
            } else {
                buffer.append("No spending found for $targetMonth.")
            }
            cursor.close()
        } catch (e: Exception) {
            Log.e("FinanceService", "getSpendingByCategoryForMonth failed: ${e.message}")
            return "Error querying spending by category"
        } finally {
            db.close()
        }
        return buffer.toString()
    }

    @Tool
    fun getBudgetsAndSpendingForMonth(
        @Param("The month to analyze in YYYY-MM format. Defaults to current month if empty.") month: String
    ): String {
        val db = getReadableDatabase() ?: return "Error: Database not accessible"
        val targetMonth = if (month.isNullOrBlank()) {
            SimpleDateFormat("yyyy-MM", Locale.getDefault()).format(Date())
        } else {
            month
        }
        val buffer = StringBuilder()
        try {
            val symbol = getCurrencySymbol(db)
            // First get the spending
            val spending = mutableMapOf<String, Double>()
            val spendCursor = db.rawQuery(
                "SELECT c.name, SUM(t.amount) " +
                "FROM transaction_log t " +
                "JOIN category c ON t.category_id = c.id " +
                "WHERE t.type = 'expense' AND strftime('%Y-%m', t.date) = ? " +
                "GROUP BY c.name",
                arrayOf(targetMonth)
            )
            if (spendCursor.moveToFirst()) {
                do {
                    spending[spendCursor.getString(0)] = spendCursor.getDouble(1)
                } while (spendCursor.moveToNext())
            }
            spendCursor.close()

            // Get budgets
            val budgetCursor = db.rawQuery(
                "SELECT c.name, b.limit_amount " +
                "FROM budget b " +
                "JOIN category c ON b.category_id = c.id " +
                "WHERE b.month = ?",
                arrayOf(targetMonth)
            )
            if (budgetCursor.moveToFirst()) {
                buffer.append("Budgets and spending for $targetMonth:\n")
                do {
                    val category = budgetCursor.getString(0)
                    val limit = budgetCursor.getDouble(1)
                    val spent = spending[category] ?: 0.0
                    val status = if (spent > limit) "OVERSPENT" else "WITHIN LIMIT"
                    buffer.append("- $category: Limit $symbol$limit, Spent $symbol$spent ($status)\n")
                } while (budgetCursor.moveToNext())
            } else {
                buffer.append("No budgets set for $targetMonth.")
            }
            budgetCursor.close()
        } catch (e: Exception) {
            Log.e("FinanceService", "getBudgetsAndSpendingForMonth failed: ${e.message}")
            return "Error querying budgets and spending"
        } finally {
            db.close()
        }
        return buffer.toString()
    }

    @Tool
    fun getSavingsGoals(): String {
        val db = getReadableDatabase() ?: return "Error: Database not accessible"
        val buffer = StringBuilder()
        try {
            val symbol = getCurrencySymbol(db)
            val cursor = db.rawQuery("SELECT name, target_amount, current_amount, target_date FROM savings_goal", null)
            if (cursor.moveToFirst()) {
                buffer.append("Savings Goals:\n")
                do {
                    val name = cursor.getString(0)
                    val target = cursor.getDouble(1)
                    val current = cursor.getDouble(2)
                    val date = cursor.getString(3) ?: "No Date"
                    buffer.append("- $name: Target $symbol$target, Current $symbol$current, Target Date: $date\n")
                } while (cursor.moveToNext())
            } else {
                buffer.append("No savings goals found.")
            }
            cursor.close()
        } catch (e: Exception) {
            Log.e("FinanceService", "getSavingsGoals failed: ${e.message}")
            return "Error querying savings goals"
        } finally {
            db.close()
        }
        return buffer.toString()
    }

    @Tool
    fun getRecentTransactions(
        @Param("Maximum number of transactions to return. Defaults to 10.") limit: Int
    ): String {
        val db = getReadableDatabase() ?: return "Error: Database not accessible"
        val limitVal = if (limit <= 0) 10 else limit
        val buffer = StringBuilder()
        try {
            val symbol = getCurrencySymbol(db)
            val cursor = db.rawQuery(
                "SELECT t.title, t.amount, t.type, t.date, c.name, a.name " +
                "FROM transaction_log t " +
                "LEFT JOIN category c ON t.category_id = c.id " +
                "LEFT JOIN account a ON t.account_id = a.id " +
                "ORDER BY t.date DESC, t.id DESC LIMIT ?",
                arrayOf(limitVal.toString())
            )
            if (cursor.moveToFirst()) {
                buffer.append("Recent Transactions (max $limitVal):\n")
                do {
                    val title = cursor.getString(0)
                    val amount = cursor.getDouble(1)
                    val type = cursor.getString(2)
                    val date = cursor.getString(3)
                    val category = cursor.getString(4) ?: "Uncategorized"
                    val account = cursor.getString(5) ?: "Unknown Account"
                    val sign = if (type == "income") "+" else "-"
                    buffer.append("- $title ($category): $sign$symbol$amount on $date using $account ($type)\n")
                } while (cursor.moveToNext())
            } else {
                buffer.append("No transactions found.")
            }
            cursor.close()
        } catch (e: Exception) {
            Log.e("FinanceService", "getRecentTransactions failed: ${e.message}")
            return "Error querying recent transactions"
        } finally {
            db.close()
        }
        return buffer.toString()
    }
}

object FinanceAgent {
    private var dbPath: String = ""
    private var rootAgentInstance: LlmAgent? = null

    @JvmStatic
    fun setDatabasePath(path: String) {
        dbPath = path
    }

    fun getAgent(apiKey: String): LlmAgent {
        var agent = rootAgentInstance
        if (agent == null) {
            agent = LlmAgent(
                name = "finance_agent",
                description = "Analyzes personal finance data and answers questions.",
                model = Gemini(
                    name = "gemini-flash-latest",
                    apiKey = apiKey
                ),
                instruction = Instruction(
                    "You are a helpful personal finance AI assistant. " +
                    "You have access to the user's financial database through tools. " +
                    "Answer user questions accurately. If asked about spending, accounts, budgets, savings goals, or recent transactions, call the appropriate tools. " +
                    "Keep answers concise and informative."
                ),
                tools = FinanceService { dbPath }.generatedTools(),
            )
            rootAgentInstance = agent
        }
        return agent
    }
}
