import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key, required this.title});
  final String title;
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  int count = 0;
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(child: Text("increment $count")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {
          setState(() {
            count++;
          }),
        },
      ),
    );
  }
}
