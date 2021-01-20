import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'first_left_pane.dart';

void main() {
  runApp(NestedRouterDemo());
}

class Project {
  final String id;
  final String name;

  Project(this.id, this.name);
}

class NestedRouterDemo extends StatefulWidget {
  @override
  _NestedRouterDemoState createState() => _NestedRouterDemoState();
}

class _NestedRouterDemoState extends State<NestedRouterDemo> {
  final _routerDelegate = TopRouterDelegate();
  final _routeInformationParser = AppRouteInformationParser();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Routing Demo',
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeInformationParser,
    );
  }
}

enum AppSection { projects, templates, people }

class AppState extends ChangeNotifier {
  AppSection _currentAppSection;

  String _selectedProjectID;

  AppState() : _currentAppSection = AppSection.projects;

  AppSection get appSection => _currentAppSection;

  set appSection(AppSection section) {
    _currentAppSection = section;
    notifyListeners();
  }

  String get selectedProjectID => _selectedProjectID;

  set selectedProjectID(String projectID) {
    _selectedProjectID = projectID;
    notifyListeners();
  }
}

class AppRouteInformationParser extends RouteInformationParser<AppRoutePath> {
  @override
  Future<AppRoutePath> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location);
    if (uri.pathSegments.isEmpty) return ProjectsListPath();

    if (uri.pathSegments.first == 'people') {
      return PeopleListPath();
    } else if (uri.pathSegments.first == 'templates') {
      return TemplateListPath();
    } else if (uri.pathSegments.first == 'projects') {
      if (uri.pathSegments.length >= 2) {
        return ProjectPath(uri.pathSegments[1]);
      }
      return ProjectsListPath();
    }

    return Page404Path();
  }

  @override
  RouteInformation restoreRouteInformation(AppRoutePath configuration) {
    if (configuration is ProjectsListPath) {
      return const RouteInformation(location: '/projects');
    }
    if (configuration is TemplateListPath) {
      return const RouteInformation(location: '/templates');
    }
    if (configuration is PeopleListPath) {
      return const RouteInformation(location: '/people');
    }
    if (configuration is ProjectPath) {
      return RouteInformation(location: '/projects/${configuration.id}');
    }
    if (configuration is Page404Path) {
      return const RouteInformation(location: '/404');
    }
    return null;
  }
}

class TopRouterDelegate extends RouterDelegate<AppRoutePath> with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  AppState appState = AppState();

  TopRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>() {
    appState.addListener(notifyListeners);
  }

  @override
  AppRoutePath get currentConfiguration {
    if (appState.appSection == AppSection.templates) return TemplateListPath();
    if (appState.appSection == AppSection.people) return PeopleListPath();
    if (appState.selectedProjectID == null) return ProjectsListPath();
    return ProjectPath(appState.selectedProjectID);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: Navigator(
        key: navigatorKey,
        pages: [
          MaterialPage(
            child: AppShell(appState: appState),
          ),
        ],
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }

          notifyListeners();
          return true;
        },
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    if (configuration is ProjectsListPath) {
      appState
        ..appSection = AppSection.projects
        ..selectedProjectID = null;
    } else if (configuration is TemplateListPath) {
      appState.appSection = AppSection.templates;
    } else if (configuration is PeopleListPath) {
      appState.appSection = AppSection.people;
    } else if (configuration is ProjectPath) {
      appState.selectedProjectID = configuration.id;
    }
  }
}

// Routes
abstract class AppRoutePath {}

class ProjectsListPath extends AppRoutePath {}

class TemplateListPath extends AppRoutePath {}

class PeopleListPath extends AppRoutePath {}

class ProjectPath extends AppRoutePath {
  final String id;

  ProjectPath(this.id);
}

class Page404Path extends AppRoutePath {}

// Widget that contains the AdaptiveNavigationScaffold
class AppShell extends StatefulWidget {
  final AppState appState;

  AppShell({@required this.appState});

  @override
  _AppShellState createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  InnerRouterDelegate _routerDelegate;
  ChildBackButtonDispatcher _backButtonDispatcher;

  @override
  void initState() {
    super.initState();
    _routerDelegate = InnerRouterDelegate(widget.appState);
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _routerDelegate.appState = widget.appState;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer back button dispatching to the child router
    _backButtonDispatcher = Router.of(context).backButtonDispatcher.createChildBackButtonDispatcher();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;

    // Claim priority, If there are parallel sub router, you will need
    // to pick which one should take priority;
    _backButtonDispatcher.takePriority();

    return Scaffold(
      body: Row(
        children: [
          FirstLeftPane(appState),
          Expanded(
            child: Router(
              routerDelegate: _routerDelegate,
              backButtonDispatcher: _backButtonDispatcher,
            ),
          ),
        ],
      ),
    );
  }
}

class InnerRouterDelegate extends RouterDelegate<AppRoutePath> with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  AppState get appState => _appState;
  AppState _appState;
  set appState(AppState value) {
    if (value == _appState) {
      return;
    }
    _appState = value;
    notifyListeners();
  }

  InnerRouterDelegate(this._appState);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        if (appState.appSection == AppSection.projects) ...[
          FadeAnimationPage(
            child: ProjectsListScreen(
              onSelectProject: _onSelectProject,
            ),
            key: const ValueKey('ProjectsListPage'),
          ),
          if (appState.selectedProjectID != null)
            MaterialPage(
              key: ValueKey(appState.selectedProjectID),
              child: ProjectScreen(projectID: appState.selectedProjectID),
            ),
        ] else if (appState.appSection == AppSection.templates)
          FadeAnimationPage(
            child: TemplatesScreen(),
            key: const ValueKey('TemplatesPage'),
          )
        else if (appState.appSection == AppSection.people)
          FadeAnimationPage(
            child: PeopleScreen(),
            key: const ValueKey('PeoplePage'),
          ),
      ],
      onPopPage: (route, result) {
        appState.selectedProjectID = null;
        notifyListeners();
        return route.didPop(result);
      },
    );
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    // This is not required for inner router delegate because it does not
    // parse route
    assert(false);
  }

  void _onSelectProject(Project project) {
    appState.selectedProjectID = project.id;
    notifyListeners();
  }
}

class FadeAnimationPage extends Page {
  final Widget child;

  FadeAnimationPage({Key key, this.child}) : super(key: key);

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, animation2) {
        final curveTween = CurveTween(curve: Curves.easeIn);
        return FadeTransition(
          opacity: animation.drive(curveTween),
          child: child,
        );
      },
    );
  }
}

final projects = [Project('p0', 'Project 0'), Project('p1', 'Project 1')];

// Screens
class ProjectsListScreen extends StatelessWidget {
  final ValueChanged<Project> onSelectProject;

  ProjectsListScreen({
    @required this.onSelectProject,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const TextField(),
          for (var project in projects)
            ListTile(
              title: Text(project.name),
              onTap: () => onSelectProject(project),
            ),
        ],
      ),
    );
  }
}

class ProjectScreen extends StatefulWidget {
  final String projectID;

  ProjectScreen({
    @required this.projectID,
  });

  @override
  _ProjectScreenState createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
            Text('A project screen', style: Theme.of(context).textTheme.headline6),
            TextField(controller: ctrl),
            TextButton(onPressed: goToPeople, child: const Text('Go to people')),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    print('Disposing txt controller ${ctrl.text}');
    ctrl.dispose();
    super.dispose();
  }

  void goToPeople() {
    final appState = context.read<AppState>();
    // ignore: cascade_invocations
    appState.appSection = AppSection.people;
  }
}

class TemplatesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Templates screen'),
      ),
    );
  }
}

class PeopleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('People screen'),
      ),
    );
  }
}

class Page404 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Not found'),
      ),
    );
  }
}
