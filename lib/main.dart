import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_manager.dart';  // Import the TaskManager class

void main() async {

  debugPrint = (String? message, {int? wrapWidth}) {};

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('tasks'); // Open the box for storing tasks

  // Run the app
  runApp(TaskApp());
}
