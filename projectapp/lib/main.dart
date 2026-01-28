import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomePage());
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Second Project"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            print("Menu clicked");
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              print("Search clicked");
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              print("More clicked");
            },
          ),
        ],
      ),
      body: const Center(
        child: Text("Wellcome Project!", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
