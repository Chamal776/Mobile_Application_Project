import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: mainHome()));
}

class mainHome extends StatelessWidget {
  const mainHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Center(
          child: Text(
            "project 1",
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ),

      body: mainBody(),
    );
  }
}

class mainBody extends StatefulWidget {
  const mainBody({super.key});

  @override
  State<mainBody> createState() => _mainBodyState();
}

class _mainBodyState extends State<mainBody> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [Container(color: Colors.amber)]);
  }
}
