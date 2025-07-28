import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TaskApp extends StatefulWidget {
  @override
  State<TaskApp> createState() => _TaskAppState();
}

class _TaskAppState extends State<TaskApp> {
  final List<String> sections = ['To Do', 'In Progress', 'Done'];
  final Map<String, List<String>> tasks = {
    'To Do': [],
    'In Progress': [],
    'Done': [],
  };
  final Map<String, bool> isSectionExpanded = {
    'To Do': true,
    'In Progress': true,
    'Done': true,
  };

  String? _lastDeletedTask;
  String? _lastDeletedSection;
  int? _lastDeletedIndex;

  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final box = await Hive.openBox('tasks');
      for (var section in sections) {
        tasks[section] = List<String>.from(box.get(section, defaultValue: []));
      }
      final savedTheme = box.get('darkMode', defaultValue: false);
      setState(() {
        _isDarkMode = savedTheme;
      });
    } catch (e) {
      print("Error loading tasks: $e");
    }
  }

  void saveTasks() {
    try {
      final box = Hive.box('tasks');
      for (var section in sections) {
        box.put(section, tasks[section]);
      }
      box.put('darkMode', _isDarkMode);
    } catch (e) {
      print("Error saving tasks: $e");
    }
  }

  void addTask(String section, String task) {
    setState(() {
      tasks[section]!.add(task);
      saveTasks();
    });
  }

  void removeTask(String section, int index) {
    setState(() {
      _lastDeletedTask = tasks[section]![index];
      _lastDeletedSection = section;
      _lastDeletedIndex = index;

      tasks[section]!.removeAt(index);
      saveTasks();
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            if (_lastDeletedTask != null && _lastDeletedSection != null && _lastDeletedIndex != null) {
              setState(() {
                tasks[_lastDeletedSection!]!.insert(_lastDeletedIndex!, _lastDeletedTask!);
                saveTasks();
              });
            }
          },
        ),
      ),
    );
  }

  void moveTask(String fromSection, String toSection, int index) {
    setState(() {
      final task = tasks[fromSection]!.removeAt(index);
      tasks[toSection]!.add(task);
      saveTasks();
    });
  }

  void reorderTask(String section, int oldIndex, int newIndex) {
    setState(() {
      final taskList = tasks[section]!;
      final task = taskList.removeAt(oldIndex);
      taskList.insert(newIndex, task);
      saveTasks();
    });
  }

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      saveTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Task Manager'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
              tooltip: 'Toggle Theme',
              onPressed: toggleTheme,
            ),
          ],
        ),
        body: ListView(
          children: sections.map((section) {
            return ExpansionTile(
              key: PageStorageKey(section),
              title: Text(section),
              initiallyExpanded: isSectionExpanded[section]!,
              onExpansionChanged: (expanded) {
                setState(() {
                  isSectionExpanded[section] = expanded;
                });
              },
              children: [
                AnimatedSize(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: ReorderableListView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    onReorder: (oldIndex, newIndex) =>
                        reorderTask(section, oldIndex, newIndex > oldIndex ? newIndex - 1 : newIndex),
                    children: [
                      for (int i = 0; i < tasks[section]!.length; i++)
                        ListTile(
                          key: ValueKey('$section-$i'),
                          title: Text(tasks[section]![i]),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => removeTask(section, i),
                          ),
                          onLongPress: () => showSectionMoveDialog(section, i),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () => showAddTaskDialog(section),
                    icon: Icon(Icons.add),
                    label: Text('Add Task'),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void showAddTaskDialog(String section) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('New Task in $section'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter task'),
          onSubmitted: (_) => _submitNewTask(section, controller),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _submitNewTask(section, controller);
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _submitNewTask(String section, TextEditingController controller) {
    if (controller.text.trim().isNotEmpty) {
      addTask(section, controller.text.trim());
    }
  }

  void showSectionMoveDialog(String fromSection, int taskIndex) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Move Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sections.where((s) => s != fromSection).map((toSection) {
            return ListTile(
              title: Text('Move to $toSection'),
              onTap: () {
                moveTask(fromSection, toSection, taskIndex);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
