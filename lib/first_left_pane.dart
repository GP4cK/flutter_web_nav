import 'package:flutter/material.dart';
import 'package:web_nav/main.dart';

class FirstLeftPane extends StatelessWidget {
  final AppState appState;
  const FirstLeftPane(this.appState, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentPage = appState.currentPage;
    return Drawer(
      child: Container(
        color: Colors.grey[200],
        child: ListView(
          children: [
            ListTile(title: const Text('Projects'), selected: currentPage.section == AppSection.projects, onTap: () => appState.replace(ProjectsListPath())),
            ListTile(title: const Text('Templates'), selected: currentPage.section == AppSection.templates, onTap: () => appState.replace(TemplateListPath())),
            ListTile(title: const Text('People'), selected: currentPage.section == AppSection.people, onTap: () => appState.replace(PeopleListPath())),
          ],
        ),
      ),
    );
  }
}
