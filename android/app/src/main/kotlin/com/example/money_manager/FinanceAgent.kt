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

    @Tool
    fun getAccountBalances(): List<Map<String, Any>> {
        val db = getReadableDatabase() ?: return emptyList()
        val list = mutableListOf<Map<String, Any>>()
        try {
            val cursor = db.rawQuery("SELECT id, name, type, balance FROM account", null)
            if (cursor.moveToFirst()) {
                do {
                    val map = mapOf(
                        "id" to cursor.getInt(0),
                        "name" to cursor.getString(1),
                        "type" to cursor.getString(2),
                        "balance" to cursor.getDouble(3)
                    )
                    list.add(map)
                } while (cursor.moveToNext())
            }
            cursor.close()
        } catch (e: Exception) {
            Log.e("FinanceService", "getAccountBalances query failed: ${e.message}")
        } finally {
            db.close()
        }
        return list
    }

    @Tool
    fun getSpendingByCategoryForMonth(
        @Param("The month to analyze in YYYY-MM format. Defaults to current month if empty.") month: String
    ): List<Map<String, Any>> {
        val db = getReadableDatabase() ?: return emptyList()
        val targetMonth = if (month.isNullOrBlank()) {
            SimpleDateFormat("yyyy-MM", Locale.getDefault()).format(Date())
        } else {
            month
        }
        val list = mutableListOf<Map<String, Any>>()
        try {
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
                do {
                    val map = mapOf(
                        "category" to cursor.getString(0),
                        "total_spent" to cursor.getDouble(1)
                    )
                    list.add(map)
                } while (cursor.moveToNext())
            }
            cursor.close()
        } catch (e: Exception) {
            Log.e("FinanceService", "getSpendingByCategoryForMonth failed: ${e.message}")
        } finally {
            db.close()
        }
        return list
    }

    @Tool
    fun getBudgetsAndSpendingForMonth(
        @Param("The month to analyze in YYYY-MM format. Defaults to current month if empty.") month: String
    ): List<Map<String, Any>> {
        val db = getReadableDatabase() ?: return emptyList()
        val targetMonth = if (month.isNullOrBlank()) {
            SimpleDateFormat("yyyy-MM", Locale.getDefault()).format(Date())
        } else {
            month
        }
        val list = mutableListOf<Map<String, Any>>()
        try {
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
                do {
                    val category = budgetCursor.getString(0)
                    val limit = budgetCursor.getDouble(1)
                    val spent = spending[category] ?: 0.0
                    val map = mapOf(
                        "category" to category,
                        "limit_amount" to limit,
                        "total_spent" to spent,
                        "status" to if (spent > limit) "overspent" else "within_limit"
                    )
                    list.add(map)
                } while (budgetCursor.moveToNext())
            }
            budgetCursor.close()
        } catch (e: Exception) {
            Log.e("FinanceService", "getBudgetsAndSpendingForMonth failed: ${e.message}")
        } finally {
            db.close()
        }
        return list
    }

    @Tool
    fun getSavingsGoals(): List<Map<String, Any>> {
        val db = getReadableDatabase() ?: return emptyList()
        val list = mutableListOf<Map<String, Any>>()
        try {
            val cursor = db.rawQuery("SELECT id, name, target_amount, current_amount, target_date FROM savings_goal", null)
            if (cursor.moveToFirst()) {
                do {
                    val map = mapOf(
                        "id" to cursor.getInt(0),
                        "name" to cursor.getString(1),
                        "target_amount" to cursor.getDouble(2),
                        "current_amount" to cursor.getDouble(3),
                        "target_date" to (cursor.getString(4) ?: "")
                    )
                    list.add(map)
                } while (cursor.moveToNext())
            }
            cursor.close()
        } catch (e: Exception) {
            Log.e("FinanceService", "getSavingsGoals failed: ${e.message}")
        } finally {
            db.close()
        }
        return list
    }

    @Tool
    fun getRecentTransactions(
        @Param("Maximum number of transactions to return. Defaults to 10.") limit: Int
    ): List<Map<String, Any>> {
        val db = getReadableDatabase() ?: return emptyList()
        val limitVal = if (limit <= 0) 10 else limit
        val list = mutableListOf<Map<String, Any>>()
        try {
            val cursor = db.rawQuery(
                "SELECT t.id, t.title, t.amount, t.type, t.date, c.name, a.name " +
                "FROM transaction_log t " +
                "LEFT JOIN category c ON t.category_id = c.id " +
                "LEFT JOIN account a ON t.account_id = a.id " +
                "ORDER BY t.date DESC, t.id DESC LIMIT ?",
                arrayOf(limitVal.toString())
            )
            if (cursor.moveToFirst()) {
                do {
                    val map = mapOf(
                        "id" to cursor.getInt(0),
                        "title" to cursor.getString(1),
                        "amount" to cursor.getDouble(2),
                        "type" to cursor.getString(3),
                        "date" to cursor.getString(4),
                        "category" to (cursor.getString(5) ?: ""),
                        "account" to (cursor.getString(6) ?: "")
                    )
                    list.add(map)
                } while (cursor.moveToNext())
            }
            cursor.close()
        } catch (e: Exception) {
            Log.e("FinanceService", "getRecentTransactions failed: ${e.message}")
        } finally {
            db.close()
        }
        return list
    }
}

object FinanceAgent {
    private var dbPath: String = ""

    @JvmStatic
    fun setDatabasePath(path: String) {
        dbPath = path
    }

    @JvmField
    val rootAgent: LlmAgent by lazy {
        LlmAgent(
            name = "finance_agent",
            description = "Analyzes personal finance data and answers questions.",
            model = Gemini(
                name = "gemini-flash-latest",
                apiKey = System.getenv("GOOGLE_API_KEY") ?: "mock-key-for-local-testing"
            ),
            instruction = Instruction(
                "You are a helpful personal finance AI assistant. " +
                "You have access to the user's financial database through tools. " +
                "Answer user questions accurately. If asked about spending, accounts, budgets, savings goals, or recent transactions, call the appropriate tools. " +
                "Keep answers concise and informative."
            ),
            tools = FinanceService { dbPath }.generatedTools(),
        )
    }
}
