import '../../models/transaction.dart';

class RecurrenceEngine {
  /// Adjusts a date to avoid weekends and key holidays (New Year's and Christmas)
  static DateTime adjustForWeekendsAndHolidays(DateTime date) {
    DateTime adjusted = date;
    if (adjusted.weekday == DateTime.saturday) {
      adjusted = adjusted.subtract(const Duration(days: 1));
    } else if (adjusted.weekday == DateTime.sunday) {
      adjusted = adjusted.add(const Duration(days: 1));
    }
    
    if (adjusted.month == 1 && adjusted.day == 1) {
      adjusted = adjusted.add(const Duration(days: 1));
    } else if (adjusted.month == 12 && adjusted.day == 25) {
      adjusted = adjusted.subtract(const Duration(days: 1));
    }
    
    if (adjusted.weekday == DateTime.saturday) {
      adjusted = adjusted.subtract(const Duration(days: 1));
    } else if (adjusted.weekday == DateTime.sunday) {
      adjusted = adjusted.add(const Duration(days: 1));
    }
    
    return adjusted;
  }

  /// Projects future instances of recurring transactions (up to 12 months out)
  static List<Transaction> projectFutureInstances(List<Transaction> baseTxs) {
    final List<Transaction> projected = [];
    final now = DateTime.now();
    final limitDate = DateTime(now.year, now.month + 12, now.day); // 12-month horizon

    for (var tx in baseTxs) {
      projected.add(tx); // Include the original historical transaction

      if (tx.recurrence == 'none') continue;

      DateTime nextDate = tx.date;
      int instanceCount = 1;

      while (true) {
        // Advance date based on recurrence interval
        switch (tx.recurrence) {
          case 'daily':
            nextDate = nextDate.add(const Duration(days: 1));
            break;
          case 'weekly':
            nextDate = nextDate.add(const Duration(days: 7));
            break;
          case 'monthly':
            nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
            break;
          case 'yearly':
            nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
            break;
          default:
            return projected;
        }

        final adjustedNextDate = adjustForWeekendsAndHolidays(nextDate);
        if (tx.recurrenceEndDate != null && adjustedNextDate.isAfter(tx.recurrenceEndDate!)) {
          break;
        }
        if (adjustedNextDate.isAfter(limitDate)) {
          break;
        }

        // Only project transactions that fall in the future (after today)
        if (adjustedNextDate.isAfter(now)) {
          projected.add(Transaction(
            id: tx.id != null ? -(tx.id! * 1000 + instanceCount) : null, // Virtual negative ID
            accountId: tx.accountId,
            categoryId: tx.categoryId,
            title: '${tx.title} (Projected)',
            amount: tx.amount,
            type: tx.type,
            date: adjustedNextDate,
            note: 'Virtual instance generated from recurrence template. Original ID: ${tx.id}. ${tx.note ?? ""}',
            recurrence: 'none', // Simulated single instances
            isPrivate: tx.isPrivate,
            tags: tx.tags,
            createdAt: tx.createdAt,
          ));
        }
        instanceCount++;
      }
    }

    // Sort combined transactions descending by date
    projected.sort((a, b) => b.date.compareTo(a.date));
    return projected;
  }
}
