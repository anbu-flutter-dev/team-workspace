import 'package:flutter/material.dart';

class EditTaskPage extends StatelessWidget {
  const EditTaskPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit task')),
      body: Center(child: Text('Edit form for $taskId coming up next')),
    );
  }
}
