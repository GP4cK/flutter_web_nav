import 'package:flutter/material.dart';
import 'package:web_nav/main.dart';

class FirstLeftPane extends StatelessWidget {
  final AppState appState;
  const FirstLeftPane(this.appState, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.grey[200],
        child: ListView(
          children: [
            ListTile(
                title: const Text('Project'), selected: appState.appSection == AppSection.projects, onTap: () => appState.appSection = AppSection.projects),
            ListTile(
                title: const Text('Templates'), selected: appState.appSection == AppSection.templates, onTap: () => appState.appSection = AppSection.templates),
            ListTile(title: const Text('People'), selected: appState.appSection == AppSection.people, onTap: () => appState.appSection = AppSection.people),
          ],
        ),
      ),
    );
  }
}
