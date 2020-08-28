
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:newpubcrawler/Bar.dart';

class PubCrawl {

  String name;
  String id;
  Bar startingBar;
  List<Bar> barsVisited = [];
  DateTime startTime;
  DateTime endTime;
  DateTime duration; // not sure if DateTime
  String description;
  String author;
  int numberParticipants;
  Set<Polyline> polylines = {};




  PubCrawl(this.id, this.startTime, this.author, this.numberParticipants, this.startingBar){
    barsVisited.clear();
    if(startingBar != null){
      barsVisited.add(this.startingBar);
    }
    name= "defaultName";
  }
  getName(){
    return name;
  }
  setName(String _name){
    name = _name;
  }
  getPolylines(){
    return polylines;
  }
  setPolylines(Set<Polyline> _polylines){
    polylines = _polylines;
  }
  addBar(Bar bar){
    barsVisited.add(bar);
  }
  getAuthor(){
    return author;
  }
  getId(){
    return id;
  }
  getStartTime(){
    return startTime;
  }
  getBars(){
      return barsVisited;
  }
  getStartBar(){
    return barsVisited[0];
  }
  getLatestBar(){
    return barsVisited.last;
  }
  getNumberOfBars(){
    return barsVisited.length;
  }
  getNumberOfParticipants(){
    return numberParticipants;
  }
}
