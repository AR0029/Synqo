import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsServiceProvider = Provider((ref) => TtsService());

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Natural reading pace
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// Speaks a text aloud. Used for the Daily Briefing.
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  /// Stops any ongoing speech.
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Generates a conversational briefing from a list of tasks.
  String generateBriefing(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      return "You have no pending tasks in this list. Great job!";
    }

    int high = tasks.where((t) => t['priority'] == 'high').length;
    int medium = tasks.where((t) => t['priority'] == 'medium').length;
    int low = tasks.where((t) => t['priority'] == 'low').length;

    String briefing = "You have ${tasks.length} task${tasks.length > 1 ? 's' : ''}. ";
    
    if (high > 0) {
      briefing += "$high are high priority. ";
    }
    
    if (tasks.length == 1) {
      return "$briefing The task is: ${tasks.first['title']}.";
    }

    // Sort tasks: high priority first
    final sortedTasks = List.from(tasks)..sort((a, b) {
      const priorityMap = {'high': 0, 'medium': 1, 'low': 2};
      int pA = priorityMap[a['priority']] ?? 1;
      int pB = priorityMap[b['priority']] ?? 1;
      return pA.compareTo(pB);
    });

    int tasksToRead = tasks.length > 5 ? 5 : tasks.length;
    
    briefing += "First, you need to ${sortedTasks[0]['title']}. ";
    
    for (int i = 1; i < tasksToRead; i++) {
      if (i == tasksToRead - 1) {
        briefing += "And lastly, ${sortedTasks[i]['title']}. ";
      } else {
        briefing += "Then, ${sortedTasks[i]['title']}. ";
      }
    }
    
    if (tasks.length > 5) {
      briefing += "And there are ${tasks.length - 5} more tasks waiting for you.";
    }

    return briefing;
  }
}
