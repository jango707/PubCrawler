import 'package:newpubcrawler/user.dart';
import 'package:newpubcrawler/Pages/findCrawlPage.dart';
import 'Pages/loading.dart';
import 'Pages/googlemap.dart';
import 'package:flutter/material.dart';
import 'StateManager.dart';
import 'package:get_it/get_it.dart';
import 'Pages/crawlPage.dart';
import 'package:newpubcrawler/authentication.dart';
import 'package:newpubcrawler/Pages/ProfilePage.dart';

final getIt = GetIt.instance;

class App extends StatefulWidget {
  App({Key key, this.auth, this.user, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final User user;

  @override
  _AppState createState() => _AppState();

}
enum AppView {
  Home,
  Maps,
  Crawl,
  Profile,
  FindCrawl,
}

class AppViewInfo {
  /// The title to display in the app bar
  final String title;
  /// A constructor function for this widget
  final Widget Function() widget;

  const AppViewInfo(this.title, this.widget);
}

final Map<AppView, AppViewInfo> views = {};

class _AppState extends State<App> {
  void changeView(){
    print("changed");
  }
  AppView _view = AppView.Home;
  var stateManager;

  @override
  void initState() {
    super.initState();
    views[AppView.Home] = AppViewInfo("Home", () => Home(
      user: widget.user,
      auth: widget.auth,
      logoutCallback: widget.logoutCallback,
    ),
    );
    views[AppView.FindCrawl] = AppViewInfo("Find Crawl", () => FindCrawlPage());
    views[AppView.Maps] = AppViewInfo("Map", () => Maps());
    views[AppView.Profile] = AppViewInfo("Profile", () => Profile(
      user: widget.user,
      auth: widget.auth,
      logoutCallback: widget.logoutCallback,
    ));
    if(!getIt.isRegistered<StateManager>()) {
      getIt.registerSingleton<StateManager>(StateManager());
    }

    stateManager = getIt.get<StateManager>();
  }

  void setView(AppView view) {

    Navigator.of(context).pop();
    setState(() {
      _view = view;
    });
  }

  List<Widget> buildDrawerList() {


    return List.from(views.entries.map((entry) => ListTile(
        title: Text(entry.value.title),
        trailing: Icon(Icons.arrow_forward),
        onTap: () => setView(entry.key)
    )));
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      child: Scaffold(
          body: views[_view].widget(),
          appBar: AppBar(
            title: Text(views[_view].title),
            backgroundColor: Colors.grey[800],
          ),
          drawer: StreamBuilder(
              stream: stateManager.stream$,
              initialData: false,
              builder: (BuildContext context, AsyncSnapshot snap){
                if(stateManager.getCrawlStarted() == true){
                  views[AppView.Crawl] = AppViewInfo("Crawl", () => Crawl());
                }else{
                  views.remove(AppView.Crawl);
                }
                return  Drawer(
                  child: ListView.builder(
                      itemCount: views.length,
                      itemBuilder: (BuildContext context, int index){
                        AppView key = views.keys.elementAt(index);
                        return new ListTile(
                            title: Text(views[key].title),
                            trailing: Icon(Icons.arrow_forward),
                            onTap: () => setView(key)
                        );
                      }
                  ),
                );
              }

          )
      ),

    );
  }

}
