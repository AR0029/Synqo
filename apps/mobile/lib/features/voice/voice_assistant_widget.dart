import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/voice_command_parser.dart';

class VoiceAssistantWidget extends StatefulWidget {
  final String? defaultListId;

  const VoiceAssistantWidget({super.key, this.defaultListId});

  @override
  State<VoiceAssistantWidget> createState() => _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends State<VoiceAssistantWidget> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speech.initialize();
  }

  void _listen() async {
    if (!_isListening) {
      // Check mic permission
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        bool available = await _speech.initialize(
          onStatus: (val) => print('onStatus: $val'),
          onError: (val) => print('onError: $val'),
        );
        if (available) {
          setState(() {
            _isListening = true;
            _text = ''; // clear previous
          });
          _speech.listen(
            onResult: (val) {
              setState(() {
                _text = val.recognizedWords;
              });
              // Stop automatically after a pause
              if (val.hasConfidenceRating && val.confidence > 0) {
                if (!_speech.isListening) {
                  _processCommand();
                }
              }
            },
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required for Voice Assistant')));
        }
      }
    } else {
      setState(() {
        _isListening = false;
      });
      _speech.stop();
      _processCommand();
    }
  }

  void _processCommand() async {
    if (_text.trim().isEmpty) return;

    setState(() {
      _isListening = false;
      _isProcessing = true;
    });

    try {
      final result = VoiceCommandParser.parse(_text);

      if (result.action == 'create_task') {
        String? listId = widget.defaultListId;
        String resolvedListName = result.listName ?? 'Current List';

        // Find the matching list if no default is provided
        if (listId == null) {
          final lists = await Supabase.instance.client.from('lists').select('id, title');
          
          if (result.listName != null) {
            final matchedList = lists.cast<Map<String, dynamic>>().firstWhere(
              (l) => l['title'].toString().toLowerCase().contains(result.listName!.toLowerCase()),
              orElse: () => <String, dynamic>{},
            );
            if (matchedList.isNotEmpty) {
              listId = matchedList['id'] as String?;
              resolvedListName = matchedList['title'] as String;
            }
          }
          
          if (listId == null && lists.isNotEmpty) {
            listId = lists.first['id'] as String?;
            resolvedListName = lists.first['title'] as String;
          }
        }

        if (listId != null) {
          await Supabase.instance.client.from('tasks').insert({
            'title': result.title,
            'list_id': listId,
            'priority': result.priority,
            'due_date': result.dueDate?.toIso8601String(),
            'created_by': Supabase.instance.client.auth.currentUser!.id,
          }).select(); // force execution and error checking

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Task "${result.title}" added to $resolvedListName'),
                backgroundColor: const Color(0xFF8B5CF6),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No lists available. Create a project first.')),
            );
          }
        }
      }
    } catch (e) {
      print('Voice parsing error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _text = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isListening || _isProcessing)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
            ),
            child: Text(
              _isProcessing ? "Processing command..." : (_text.isEmpty ? "Listening..." : _text),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        FloatingActionButton(
          heroTag: null,
          onPressed: _listen,
          backgroundColor: _isListening ? Colors.redAccent : const Color(0xFF8B5CF6),
          child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
        ),
      ],
    );
  }
}
