package com.saisurya.moneymanager

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MoneyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.money_widget_layout).apply {
                val netWorth = widgetData.getString("net_worth", "$0.00")
                val todaySpend = widgetData.getString("today_spend", "$0.00")
                
                // Set text views. If formatting isn't prefixing currency, we add it.
                // We fallback to standard formatting
                setTextViewText(R.id.widget_net_worth, netWorth)
                setTextViewText(R.id.widget_today_spend, todaySpend)
            }
            
            // Allow tap on widget to open app
            val intent = android.content.Intent(context, MainActivity::class.java)
            val pendingIntent = android.app.PendingIntent.getActivity(
                context,
                0,
                intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_title, pendingIntent)

            // Setup PendingIntents for Quick Actions
            val expenseIntent = android.content.Intent(context, MainActivity::class.java).apply {
                putExtra("action_type", "add_expense")
            }
            val pendingExpense = android.app.PendingIntent.getActivity(
                context,
                1,
                expenseIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_widget_expense, pendingExpense)

            val incomeIntent = android.content.Intent(context, MainActivity::class.java).apply {
                putExtra("action_type", "add_income")
            }
            val pendingIncome = android.app.PendingIntent.getActivity(
                context,
                2,
                incomeIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_widget_income, pendingIncome)

            val transferIntent = android.content.Intent(context, MainActivity::class.java).apply {
                putExtra("action_type", "add_transfer")
            }
            val pendingTransfer = android.app.PendingIntent.getActivity(
                context,
                3,
                transferIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_widget_transfer, pendingTransfer)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
