class VoiceCommandResult {
  final String action; // 'create_task'
  final String title;
  final String? listName;
  final String priority; // 'low', 'medium', 'high'
  final DateTime? dueDate;

  VoiceCommandResult({
    required this.action,
    required this.title,
    this.listName,
    this.priority = 'medium',
    this.dueDate,
  });

  @override
  String toString() {
    return 'Action: $action, Title: $title, List: $listName, Priority: $priority, Due: $dueDate';
  }
}

class VoiceCommandParser {
  /// Analyzes a transcribed voice command and extracts task details
  /// using heuristic Natural Language Processing (Regex & Tokenization).
  static VoiceCommandResult parse(String transcript) {
    String text = transcript.toLowerCase().trim();

    // 1. Identify Priority
    String priority = 'medium';
    if (text.contains(RegExp(r'\b(urgent|high priority|asap|critical)\b'))) {
      priority = 'high';
    } else if (text.contains(RegExp(r'\b(low priority|whenever|not urgent)\b'))) {
      priority = 'low';
    }

    // 2. Identify Due Date (Heuristic temporal extraction)
    DateTime? dueDate;
    final now = DateTime.now();
    
    if (text.contains(RegExp(r'\b(today|tonight)\b'))) {
      dueDate = DateTime(now.year, now.month, now.day, 23, 59);
    } else if (text.contains(RegExp(r'\b(tomorrow)\b'))) {
      dueDate = DateTime(now.year, now.month, now.day + 1, 23, 59);
    } else if (text.contains(RegExp(r'\b(next week)\b'))) {
      dueDate = DateTime(now.year, now.month, now.day + 7, 23, 59);
    }

    // 3. Identify List Context (e.g. "in groceries", "to project list")
    String? listName;
    final listRegex = RegExp(r'\b(in|to) (the )?([a-z]+) (list|folder)\b');
    final listMatch = listRegex.firstMatch(text);
    if (listMatch != null) {
      listName = listMatch.group(3); // extracts the word before "list"
    } else {
      // Fallback: just look for "in [word]" at the end
      final shortListRegex = RegExp(r'\bin ([a-z]+)$');
      final shortMatch = shortListRegex.firstMatch(text);
      if (shortMatch != null) {
        listName = shortMatch.group(1);
      }
    }

    // 4. Extract Task Title
    // Remove all the extracted metadata keywords from the sentence to isolate the subject
    String title = text
        .replaceAll(RegExp(r'\b(add|create|remind me to|make a task to|task|urgent|high priority|asap|critical|low priority|whenever|not urgent|today|tonight|tomorrow|next week)\b'), '')
        .replaceAll(listRegex, '')
        .replaceAll(RegExp(r'\bin ([a-z]+)$'), '')
        .trim();

    // Clean up multiple spaces and lingering prepositions
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (title.startsWith('to ')) {
      title = title.substring(3).trim();
    }
    
    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    } else {
      title = "New voice task"; // Fallback
    }

    return VoiceCommandResult(
      action: 'create_task',
      title: title,
      listName: listName,
      priority: priority,
      dueDate: dueDate,
    );
  }
}
