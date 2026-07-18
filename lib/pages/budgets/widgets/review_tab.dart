import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/planning_state_provider.dart';
import '../../../widgets/common/glassmorphism_card.dart';

class ReviewTab extends ConsumerStatefulWidget {
  const ReviewTab({super.key});

  @override
  ConsumerState<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends ConsumerState<ReviewTab> {
  String? _selectedMood;
  final Set<String> _selectedReasonTags = {};
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planningStateProvider);
    final notifier = ref.read(planningStateProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Sunday Weekly Check-in Card
          Text('Sunday Weekly Check-in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          
          GlassmorphismCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'How did your spending go this week?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Mood Selector Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMoodButton('😀', 'great'),
                      _buildMoodButton('🙂', 'good'),
                      _buildMoodButton('😐', 'okay'),
                      _buildMoodButton('😟', 'bad'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Reason Tags (visible if mood is neutral or bad)
                  if (_selectedMood != null) ...[
                    Text(
                      _selectedMood == '😟' || _selectedMood == '😐'
                          ? 'What unexpected events happened?'
                          : 'Any specific drivers this week?',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildReasonChip('Unexpected Bills'),
                        _buildReasonChip('Medical'),
                        _buildReasonChip('Travel'),
                        _buildReasonChip('Shopping'),
                        _buildReasonChip('Dining Out'),
                        _buildReasonChip('Other'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Notes input
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      labelText: 'Add some details / notes...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _selectedMood != null
                        ? () async {
                            final tags = _selectedReasonTags.join(',');
                            await notifier.submitWeeklyCheckin(
                              _selectedMood!,
                              tags.isNotEmpty ? tags : null,
                              _notesController.text.isNotEmpty ? _notesController.text : null,
                            );

                            if (!context.mounted) return;
                            setState(() {
                              _selectedMood = null;
                              _selectedReasonTags.clear();
                              _notesController.clear();
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Weekly check-in submitted successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    child: const Text('Submit Weekly Review'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Previous Check-ins History
          if (state.checkins.isNotEmpty) ...[
            Text('Review History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.checkins.length,
              itemBuilder: (context, index) {
                final checkin = state.checkins[index];
                
                String moodEmoji = '😀';
                if (checkin.mood == 'good') moodEmoji = '🙂';
                if (checkin.mood == 'okay') moodEmoji = '😐';
                if (checkin.mood == 'bad') moodEmoji = '😟';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassmorphismCard(
                    child: ListTile(
                      leading: Text(moodEmoji, style: const TextStyle(fontSize: 28)),
                      title: Text('Week Ending: ${checkin.weekEndDate}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (checkin.reasonTags != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text('Drivers: ${checkin.reasonTags}', style: const TextStyle(fontSize: 12, color: Colors.blueAccent)),
                            ),
                          if (checkin.notes != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text('Notes: ${checkin.notes}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // 3. Monthly carry-forward planning
          Text('Monthly Carry-Forward Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          
          const GlassmorphismCard(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Month Strategy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'When August starts, we will carry forward your unallocated leftovers (₹3,000) '
                    'and auto-adjust your Wants categories based on your check-in notes to ensure comfortable saving.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMoodButton(String emoji, String moodValue) {
    final isSelected = _selectedMood == moodValue;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = moodValue),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.15) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  Widget _buildReasonChip(String tag) {
    final isSelected = _selectedReasonTags.contains(tag);
    return ChoiceChip(
      label: Text(tag, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedReasonTags.add(tag);
          } else {
            _selectedReasonTags.remove(tag);
          }
        });
      },
    );
  }
}
