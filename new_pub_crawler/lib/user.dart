import 'package:newpubcrawler/pubcrawl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:newpubcrawler/Bar.dart';
class User{
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  String name;
  String id;
  List<PubCrawl> pubCrawls = [];
  bool isLoaded  = false;


  User(this.id, this.name);
  User.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        id = json['id'];

  Map<String, dynamic> toJson() => {
    'name': name,
    'id': id,
  };
  getIsLoaded(){
    return isLoaded;
  }
  setIsLoaded(bool check){
    isLoaded = check;
  }
  getId(){
    return id;
  }
  getUsername(){
    return name;
  }
  addCrawlFromLoad(PubCrawl crawl){
    pubCrawls.add(crawl);
  }
  addCrawlToProfile(PubCrawl crawl){
    //also adds to general database
    pubCrawls.add(crawl);
    _database
        .reference()
        .child("users")
        .child(id)
        .child("pubcrawls_done/${crawl.getId()}")
        .set({
          "pubcrawl_name": crawl.getName(),
    });
    _database
        .reference()
        .child("pubcrawls/${crawl.getId()}")
        .set({
    "pubcrawl_name": crawl.getName(),
    "pubcrawl_startTime": crawl.getStartTime().toString(),
    "pubcrawl_author": crawl.getAuthor(),
    "pubcrawl_num_participants": crawl.getNumberOfParticipants(),
    "is_public": true,
    });

    crawl.getBars().asMap().forEach((index, bar) {
      print(bar.getName());
      _database
          .reference()
          .child("pubcrawls/${crawl.getId()}/bars/${bar.getPlaceId()}")
          .set({
            "bar_id": bar.getPlaceId(),
            "bar_name": bar.getName(),
            "bar_lng": bar.getLng(),
            "bar_lat": bar.getLat(),
            "bar_photo": bar.getPhotoRef(),
            "bar_order": index
      });
    });

  }
  getPubCrawlList(){
    return pubCrawls;
  }
  getNumberOfCrawls(){
    return pubCrawls.length;
  }
}