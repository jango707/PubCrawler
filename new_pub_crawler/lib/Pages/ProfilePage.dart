import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:newpubcrawler/authentication.dart';
import 'package:newpubcrawler/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newpubcrawler/StateManager.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:newpubcrawler/pubcrawl.dart';

final getIt = GetIt.instance;

class Profile extends StatefulWidget {
  Profile({Key key, this.auth, this.user, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final User user;


  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  var stateManager;
  var _user;
  bool isLoaded = false;
  final FirebaseDatabase _database = FirebaseDatabase.instance;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    stateManager = getIt.get<StateManager>();
    if(stateManager.getUser() == null){
      setUser();
    }else{
      _user = stateManager.getUser();
      isLoaded = true;
    }

  }
  setUser() async{
    if(widget.user == null){
      stateManager.setUser(widget.user);
      _user = widget.user;
      setState(() {
        isLoaded = true;
      });
      print("loaded");

    }else{

      await stateManager.instantiateUser();

      _user = stateManager.getUser();
      print(_user.getNumberOfCrawls());
      setState(() {
        isLoaded = true;
      });
      print("loaded");
    }

  }
  @override
  Widget build(BuildContext context) {
    if (isLoaded ) {
      return Container(
      color: Colors.grey,
      child: Padding(
          padding: EdgeInsets.all(5),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.85,
              child: Card(
                color: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        CircleAvatar(
                          child: Icon(
                            Icons.local_bar,
                            size: 90,
                            color: Colors.black54,
                          ),
                          backgroundColor: Colors.amber,
                          radius: 80,
                        ),
                        SizedBox(height: 20),
                        Text(
                            _user.getUsername(),
                            style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[500]
                          ),
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _user.getPubCrawlList().length,
                              itemBuilder: (BuildContext context, int index) {
                                return Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text( _user.getPubCrawlList()[index].getNumberOfBars().toString())
                                      ],
                                    ),
                                  ),
                                );
                              }
                          ),
                        )

                      ],
                    ),

                  ),
                ),
              ),
            ),
          ),
        ),
    );
    } else {
      return Text("loading");
    }
  }
}
