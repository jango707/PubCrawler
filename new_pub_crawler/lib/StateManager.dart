import 'dart:collection';
import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'pubcrawl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:newpubcrawler/Bar.dart';
import 'package:newpubcrawler/user.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

var uuid = Uuid();

class StateManager{
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  BehaviorSubject _stateManager  = BehaviorSubject<bool>();

  Stream get stream$ => _stateManager.stream;
  bool get crawlStarted => _stateManager.value;
  PubCrawl currentCrawl;

  User loggedInUser;

  startCrawl(Bar bar){
    print("crawl started");
    _stateManager.add(true);
    currentCrawl = new PubCrawl(uuid.v1(), DateTime.now(), loggedInUser.getUsername(), 5, bar);
  }

  endCrawl(){
    print("crawl ended");
    loggedInUser.addCrawlToProfile(currentCrawl);
    _stateManager.add(false);
  }

  getCurrentPubCrawl(){
    return currentCrawl;
  }

  getCrawlStarted(){
    return crawlStarted;
  }

  setUser(user){
    loggedInUser = user;
  }
  getUser(){
    return loggedInUser;
  }
  instantiateUser() async{
    print("instantiating");
    final prefs = await SharedPreferences.getInstance();
    var nameFromPrefs = json.decode(prefs.getString("user_id"))["name"].toString();
    var idFromPrefs = json.decode(prefs.getString("user_id"))["id"].toString();
    List<String> pubIds = [];
    User user = new User(idFromPrefs, nameFromPrefs);
    await _database
        .reference()
        .child("users/${user.getId()}/pubcrawls_done")
        .once()
        .then((snapshot){
          if(snapshot.value != null) {

            snapshot.value.forEach( (value, key) {
              pubIds.add(value);
            });
          }
          this.setUser(user);
    });
    if(pubIds.isNotEmpty){
      pubIds.forEach((_id) async {
       PubCrawl crawl = await getPubCrawlFromId(_id);
        user.addCrawlFromLoad(crawl);
      });
    }

    print("done");
  }


  Future<PubCrawl> getPubCrawlFromId(String _id) async{
    PubCrawl crawl;
    var _rating;
    var total = 0;
    int count;

    List<dynamic> barsAtCrawl= [];
    await _database
        .reference()
        .child("pubcrawls/$_id")
        .once()
        .then( (snapshot) {
          if(snapshot.value != null){
            crawl = new PubCrawl(
                _id,
                DateTime.parse(snapshot.value["pubcrawl_startTime"]),
                snapshot.value["pubcrawl_author"],
                snapshot.value["pubcrawl_num_participants"],
                null);
            crawl.setDesc(snapshot.value["pubcrawl_desc"]);

            Map<dynamic, dynamic> map = snapshot.value["pubcrawl_ratings"];
            count = snapshot.value["pubcrawl_ratings"].length;

            map.forEach((key, value) {
              total += value["rating"];
            });

            print("count: " + count.toString() + ", total: " + total.toString());
            _rating = total / count ;
            print(_rating);
            crawl.setRating(_rating);

            snapshot.value["bars"].forEach((value, key){
              barsAtCrawl.add((key));
              barsAtCrawl.sort((a, b) => a["bar_order"].compareTo(b["bar_order"]));
            });
          }
          barsAtCrawl.asMap().forEach( (value, key){
            Bar bar = new Bar(key["bar_lat"], key["bar_lng"], key["bar_id"], key["bar_name"], key["bar_photo"]);

            crawl.addBar(bar);
          });
    });
    return crawl;
  }
  Future<List<PubCrawl>> findCloseCrawls(LatLng coordinates) async {
    PubCrawl closest_crawl;
    List<PubCrawl> close_crawls = [];
    List<String> close_crawls_id = [];
    List<dynamic> barsAtCrawl= [];
    String closest_crawl_id;
    double closest_dis = 10000;
    await _database
        .reference()
        .child("pubcrawls")
        .once()
        .then((snapshot) {
          if(snapshot.value != null) {
            snapshot.value.forEach((value, key) {

              key["bars"].forEach((value2, key2) {
                  barsAtCrawl.add(key2);
                  barsAtCrawl.sort((a, b) => a["bar_order"].compareTo(b["bar_order"]));
              });

              barsAtCrawl.asMap().forEach((value2, key2) {

                var distance = mp.SphericalUtil.computeDistanceBetween(
                    mp.LatLng(coordinates.latitude, coordinates.longitude),
                    mp.LatLng(key2["bar_lat"], key2["bar_lng"]));
                if (distance < closest_dis) {
                  closest_crawl_id = value;
                  if (close_crawls_id.contains(value) == false) {
                    close_crawls_id.add(value);
                  }
                }
              });
            });
          }
    });
    if(closest_crawl_id != null && closest_crawl_id.length == 0){
      return close_crawls;
    }
    if(close_crawls_id.length >= 5){
      for(int i = 0; i < 5 ; i++){
          closest_crawl = await getPubCrawlFromId(close_crawls_id[i]);
          close_crawls.add(closest_crawl);

        }
      return close_crawls;
    }else{
      for(int i = 0; i < close_crawls_id.length ; i++){
        closest_crawl = await getPubCrawlFromId(close_crawls_id[i]);
        close_crawls.add(closest_crawl);

      }
      return close_crawls;
    }
  }

}