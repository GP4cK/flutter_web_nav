import 'dart:html';
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
  final List<AppRoutePath> _history;

  AppState() : _history = [ProjectsListPath()];

  void popPage() {
    if (_history.isNotEmpty) {
      _history.removeLast();
      notifyListeners();
    }
  }

  void replace(AppRoutePath page) {
    final index = _history.indexWhere((h) => h.key == page.key);
    if (index == -1) {
      _history
        ..removeLast()
        ..add(page);
    } else {
      _history.removeRange(index + 1, _history.length);
    }
    notifyListeners();
  }

  void push(AppRoutePath page) {
    _history.add(page);
    notifyListeners();
  }

  AppRoutePath get currentPage => _history.last;

  void popUntil(AppRoutePath configuration) {
    for (var i = _history.length - 1; i >= 0; i--) {
      final page = _history[i];
      if (page.key != configuration.key) {
        _history.removeLast();
      } else {
        break;
      }
    }
    if (_history.isEmpty) _history.add(configuration);
    notifyListeners();
  }

  bool canPop() {
    return _history.length > 1;
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
    // Order matters here because ProjectPath is a ProjectListPath
    if (configuration is ProjectPath) {
      return RouteInformation(location: '/projects/${configuration.id}');
    }
    if (configuration is ProjectsListPath) {
      return const RouteInformation(location: '/projects');
    }
    if (configuration is TemplateListPath) {
      return const RouteInformation(location: '/templates');
    }
    if (configuration is PeopleListPath) {
      return const RouteInformation(location: '/people');
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
    return appState.currentPage;
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
    appState.popUntil(configuration);
  }
}

// Routes
abstract class AppRoutePath {
  String get key;
  Widget get widget;
  AppSection get section;
}

class ProjectsListPath extends AppRoutePath {
  @override
  String get key => 'projects';
  @override
  Widget get widget => ProjectsListScreen();
  @override
  AppSection get section => AppSection.projects;
}

class TemplateListPath extends AppRoutePath {
  @override
  String get key => 'templates';
  @override
  Widget get widget => TemplatesListScreen();
  @override
  AppSection get section => AppSection.templates;
}

class PeopleListPath extends AppRoutePath {
  @override
  String get key => 'people';
  @override
  AppSection get section => AppSection.people;
  @override
  Widget get widget => PeopleListScreen();
}

class ProjectPath extends ProjectsListPath {
  final String id;
  ProjectPath(this.id);
  @override
  String get key => 'projects/$id';
  @override
  Widget get widget => ProjectScreen(projectID: id);
}

class Page404Path extends AppRoutePath {
  @override
  String get key => '404';
  @override
  AppSection get section => throw UnimplementedError();
  @override
  Widget get widget => Page404();
}

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
      pages: appState._history
          .map((history) => FadeAnimationPage(
                key: ValueKey(history.key),
                child: history.widget,
              ))
          .toList(),
      onPopPage: (route, result) {
        appState.popPage();
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const TextField(),
          for (var project in projects)
            ListTile(
              title: Text(project.name),
              onTap: () => onSelectProject(context, project),
            ),
        ],
      ),
    );
  }

  void onSelectProject(BuildContext context, Project project) {
    context.read<AppState>().push(ProjectPath(project.id));
  }
}

class TemplatesListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Templates screen'),
      ),
    );
  }
}

class PeopleListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      body: Column(
        children: [
          const Center(child: Text('People screen')),
          if (appState.canPop())
            TextButton(
                onPressed: () {
                  appState.popPage();
                },
                child: const Text('Pop route'))
          else
            const Text('No route to pop')
        ],
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

class ProjectScreen extends StatefulWidget {
  final String projectID;

  ProjectScreen({@required this.projectID});

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
            // if we access the project directly by entering a url in the address bar,
            // we may not be able to pop the route
            if (context.watch<AppState>().canPop())
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
    context.read<AppState>().push(PeopleListPath());
  }
}
