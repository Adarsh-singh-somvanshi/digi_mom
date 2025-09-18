import 'package:flutter/material.dart';
import 'task_model.dart';
import 'task_repository.dart';
import 'task_form_screen.dart';
import 'notification_service.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> _taskFuture;
  final ConfettiController _confettiController =
  ConfettiController(duration: const Duration(seconds: 1));

  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _refreshTasks();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  void _refreshTasks() {
    setState(() {
      _taskFuture = TaskRepository.instance.readAllTasks();
    });
  }

  void _toggleComplete(Task task) async {
    task.isCompleted = !task.isCompleted;
    await TaskRepository.instance.update(task);
    if (task.isCompleted) {
      _confettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Great job! Task completed 🎉')),
      );
      await NotificationService().cancelNotification(task.id!);
    }
    _refreshTasks();
  }

  void _deleteTask(int id) async {
    await TaskRepository.instance.delete(id);
    await NotificationService().cancelNotification(id);
    _refreshTasks();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Reminder App'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              DateFormat.yMMMd().add_jm().addPattern(' :ss').format(_currentTime),
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Task>>(
            future: _taskFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return Center(child: Text('No tasks. Add some!'));
              }
              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: ListTile(
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                          'Due: ${DateFormat.yMMMd().add_jm().format(task.dueDate)}\n${task.description}'),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 12,
                        children: [
                          Checkbox(
                              value: task.isCompleted,
                              onChanged: (value) {
                                _toggleComplete(task);
                              }),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              _deleteTask(task.id!);
                            },
                          )
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          TaskFormScreen.routeName,
                          arguments: task,
                        ).then((result) {
                          if (result == true) _refreshTasks();
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, TaskFormScreen.routeName).then((result) {
            if (result == true) _refreshTasks();
          });
        },
      ),
    );
  }
}
