import 'package:flutter/material.dart';
import 'features/notebook/presentation/screens/notebook_home_screen.dart';
import 'app.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MyWidget(title: "goal"));
  }
}
