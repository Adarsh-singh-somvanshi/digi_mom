// task_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'task_repository.dart';
import 'notification_service.dart';

class TaskFormScreen extends StatefulWidget {
  static const routeName = '/task-form';

  final Task? task;
  const TaskFormScreen({Key? key, this.task}) : super(key: key);

  @override
  _TaskFormScreenState createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  DateTime _selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _selectedDateTime = widget.task?.dueDate ?? DateTime.now();

    // NOTE: previously there was a timer here that repeatedly set
    // _selectedDateTime = DateTime.now(); that overwrote the user's selection.
    // Remove that behavior. If you want to show a "live clock" in the UI,
    // maintain a separate `_currentTime` field and update that instead.
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      // create a Task object (without id - DB assigns it on create)
      final taskToSave = Task(
        id: widget.task?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _selectedDateTime,
        isCompleted: widget.task?.isCompleted ?? false,
      );

      try {
        Task savedTask;
        if (widget.task == null) {
          // create returns the task with id assigned; capture that result
          savedTask = await TaskRepository.instance.create(taskToSave);
        } else {
          // if updating, ensure DB is updated and keep using the same id
          await TaskRepository.instance.update(taskToSave);
          savedTask = taskToSave;
        }

        // Cancel any existing scheduled notification for this task id (for updates)
        if (savedTask.id != null) {
          await NotificationService().cancelNotification(savedTask.id!);
        }

        // schedule notification using the savedTask (has id)
        await NotificationService().scheduleNotification(savedTask);

        // IMPORTANT: pop with true so the caller's `.then((result){ if (result==true) ...})`
        // sees success and refreshes the task list immediately.
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving task: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDue =
    DateFormat.yMMMd().add_jm().format(_selectedDateTime);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              Text('Due: $formattedDue'),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _pickDateTime,
                child: Text('Pick Date & Time'),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveTask,
                child:
                Text(widget.task == null ? 'Add Task' : 'Update Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
