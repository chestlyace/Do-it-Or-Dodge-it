import 'package:flutter/material.dart';

import '../../../core/utils/task_display.dart';
import '../../../data/models/enums.dart';

/// The values entered in [AddTaskSheet].
class NewTaskValues {
  const NewTaskValues({
    required this.title,
    required this.category,
    this.customCategory,
    this.note,
    this.dueAt,
  });

  final String title;
  final TaskCategory category;
  final String? customCategory;
  final String? note;
  final DateTime? dueAt;
}

/// Bottom sheet for adding a task. Pops with [NewTaskValues] when saved.
class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  final _custom = TextEditingController();
  TaskCategory _category = TaskCategory.work;
  DateTime? _due;
  String? _titleError;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _custom.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _due = picked);
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      setState(() => _titleError = 'Give the task a title');
      return;
    }
    Navigator.of(context).pop(
      NewTaskValues(
        title: _title.text,
        category: _category,
        customCategory: _custom.text,
        note: _note.text,
        dueAt: _due,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add a task', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'What are you avoiding?',
                errorText: _titleError,
              ),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in TaskCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (c) => setState(() => _category = c ?? _category),
            ),
            if (_category == TaskCategory.other)
              TextField(
                controller: _custom,
                decoration: const InputDecoration(
                  labelText: 'Describe the category (optional)',
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _due == null ? 'No due date' : 'Due ${formatDate(_due!)}',
                  ),
                ),
                if (_due != null)
                  IconButton(
                    tooltip: 'Clear due date',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _due = null),
                  ),
                TextButton(
                  onPressed: _pickDate,
                  child: const Text('Pick a due date'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _save, child: const Text('Add task')),
          ],
        ),
      ),
    );
  }
}
