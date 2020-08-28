import 'dart:convert';

import 'package:flutter/material.dart';
import '../StateManager.dart';
import 'package:get_it/get_it.dart';
import 'package:newpubcrawler/authentication.dart';
import 'package:newpubcrawler/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

class Home extends StatefulWidget {
  Home({Key key, this.auth, this.user, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final User user;
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isLoaded = false;

  var stateManager;
  var user;

  @override
  void initState(){
    super.initState();
    stateManager = getIt.get<StateManager>();
    if(stateManager.getUser() == null){
      setUser();
    }else{
     user = stateManager.getUser();
     isLoaded = true;
    }

    if(!getIt.isRegistered<StateManager>()) {
      getIt.registerSingleton<StateManager>(StateManager());
    }


  }
  setUser() async{
   await  stateManager.instantiateUser();
    setState(() {
      isLoaded = true;
    });

    user = stateManager.getUser();
    print("loaded");
    print("user: " + user.getUsername());
  }
  signOut() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("user_id");
    print(user.getUsername() + " has signed out");
    stateManager.setUser(null);
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          child: StreamBuilder(
            stream: stateManager.stream$,
            initialData: false,
            builder: (BuildContext context, AsyncSnapshot snap){
              if(snap.data == true){
                return Text('Crawl Started');
              }else{
                return isLoaded ? Text('Welcome ' + stateManager.getUser().getUsername()) : Text("loading");
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Text("log out"),
        onPressed: signOut,
      ),
    );
  }
}
