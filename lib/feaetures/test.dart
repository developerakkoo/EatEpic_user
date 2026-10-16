import 'package:flutter/material.dart';

class TEST extends StatefulWidget {
  const TEST({super.key});

  @override
  State<TEST> createState() => _TESTState();
}

class _TESTState extends State<TEST> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
        Center(
          child: Text("CEnter"),
        )
        ],
      ),
    );
  }
}