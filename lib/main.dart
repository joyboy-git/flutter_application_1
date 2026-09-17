import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const StudyAssistantApp());
}

class StudyAssistantApp extends StatelessWidget {
  const StudyAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Study Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class ChatItem {
  final String question;
  final String answer;
  final String mode;

  ChatItem({
    required this.question,
    required this.answer,
    required this.mode,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController questionController =
      TextEditingController();

  final ScrollController responseScrollController =
      ScrollController();

  String selectedMode = 'Explain';
  String answer = '';
  bool isLoading = false;
  String? errorMessage;

  final List<ChatItem> history = [];

  final List<String> modes = [
    'Explain',
    'Summarize',
    'Quiz',
    'Notes',
  ];

  @override
  void dispose() {
    questionController.dispose();
    responseScrollController.dispose();
    super.dispose();
  }

  Future<void> askAI() async {
    final question = questionController.text.trim();

    if (question.isEmpty) {
      setState(() {
        errorMessage = 'Please enter a question.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      answer = '';
      errorMessage = null;
    });
    const String baseUrl = 'http://10.0.2.2:5000';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ask'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question': question,
          'mode': selectedMode,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final newAnswer = data['answer'] ?? 'No response received.';

        setState(() {
          answer = newAnswer;

          history.insert(
            0,
            ChatItem(
              question: question,
              answer: newAnswer,
              mode: selectedMode,
            ),
          );
        });
      } else {
        setState(() {
          errorMessage =
              data['error'] ?? 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            'Could not connect to the backend.\n\nMake sure Flask is running.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void clearCurrentResponse() {
    setState(() {
      answer = '';
      errorMessage = null;
      questionController.clear();
    });
  }

  void clearHistory() {
    setState(() {
      history.clear();
      answer = '';
      errorMessage = null;
    });
  }

  void loadHistoryItem(ChatItem item) {
    setState(() {
      questionController.text = item.question;
      selectedMode = item.mode;
      answer = item.answer;
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Study Assistant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear history',
            onPressed: history.isEmpty ? null : clearHistory,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              const Text(
                'What do you want to learn?',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedMode,
                decoration: const InputDecoration(
                  labelText: 'Study Mode',
                  border: OutlineInputBorder(),
                ),
                items: modes.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(mode),
                  );
                }).toList(),
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            selectedMode = value;
                          });
                        }
                      },
              ),

              const SizedBox(height: 14),

              TextField(
                controller: questionController,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText:
                      'Example: Explain binary search with an example',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : askAI,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        isLoading ? 'Thinking...' : 'Ask AI',
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  IconButton(
                    tooltip: 'Clear',
                    onPressed: isLoading
                        ? null
                        : clearCurrentResponse,
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text(
                'AI Response',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('AI is preparing your answer...'),
                            ],
                          ),
                        )
                      : errorMessage != null
                          ? SingleChildScrollView(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : answer.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Your AI response will appear here.',
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : SingleChildScrollView(
                                  controller:
                                      responseScrollController,
                                  child: Text(
                                    answer,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                ),
              ),
            ],
          ),
        ),
      ),

      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [

              const DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school,
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Study History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: history.isEmpty
                    ? const Center(
                        child: Text(
                          'No study history yet.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];

                          return ListTile(
                            leading: const Icon(
                              Icons.history,
                            ),
                            title: Text(
                              item.question,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(item.mode),
                            onTap: () {
                              Navigator.pop(context);
                              loadHistoryItem(item);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}