import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:newpubcrawler/pubcrawl.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:newpubcrawler/StateManager.dart';
import 'package:get_it/get_it.dart';
import 'package:newpubcrawler/Bar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

var uuid = Uuid();

final getIt = GetIt.instance;

class FindCrawlPage extends StatefulWidget {
  @override
  _FindCrawlPageState createState() => _FindCrawlPageState();
}

class _FindCrawlPageState extends State<FindCrawlPage> {

  Future<String>_loadFromAsset() async {
    return await rootBundle.loadString("assets/key.json");
  }
  Future parseJson() async {
    String jsonString = await _loadFromAsset();
    final jsonResponse = jsonDecode(jsonString);
    _APIkey = jsonResponse['google_API_key'].toString();
    _googleMapPolyline = new GoogleMapPolyline(apiKey: _APIkey);
    print(jsonResponse['google_API_key'].toString());
  }
  String _APIkey;
  GoogleMapPolyline _googleMapPolyline;
  var stateManager;
  Completer<GoogleMapController> _controller = Completer();
  Set<Polyline> _polyline = {};
  List<LatLng> _routeCoords;
  List<Marker> _barMarker= [];
  List<Marker> positionMarker= [];
  double _currentLat;
  double _currentLong;
  PubCrawl currentCrawl;
  var _currentLocation = CameraPosition(target:  LatLng(53.483959, -2.244644), zoom: 15);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    parseJson();
    stateManager = getIt.get<StateManager>();
  }
  void _getCurrentLocation() async{
    final position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    // print(position);
    _currentLat = position.latitude;
    _currentLong = position.longitude;

    var currentPosition = CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 16);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(currentPosition));

    _barMarker.add(Marker(
      icon:  await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(1,1)), 'assets/images/bluedot.png'),

      markerId: MarkerId("mymarker"),
      draggable: false,
      onTap: () {
        print("your position");
      },
      position: LatLng(position.latitude, position.longitude),
    ),
    );
    setState(() {
      //the marker is identified by the markerId and not with the index of the list
      _barMarker = this._barMarker;
    });

  }
  void _getLatLng(Prediction prediction) async {
    GoogleMapsPlaces _places = new GoogleMapsPlaces(apiKey: _APIkey);  //Same API_KEY as above
    PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(prediction.placeId);
    double latitude = detail.result.geometry.location.lat;
    double longitude = detail.result.geometry.location.lng;

    final GoogleMapController controller = await _controller.future;
    _currentLocation = CameraPosition(target: LatLng(latitude, longitude), zoom: 16);
    controller.animateCamera(CameraUpdate.newCameraPosition(_currentLocation));

  }

  _findCrawlsHere() async{
    currentCrawl = null;
    setState(() {
      _polyline.clear();
    });
    List<PubCrawl> close_crawls = [];
    List<Bar> barsFromCrawl = [];

    close_crawls = await stateManager.findCloseCrawls(LatLng(_currentLocation.target.latitude, _currentLocation.target.longitude));

    close_crawls.forEach((crawl) {
      for(int i = 0; i < crawl.getNumberOfBars(); i++) {
        barsFromCrawl.add(crawl.getBars()[i]);
      }
      createRouteForCrawl(crawl, false);
      barsFromCrawl.add(crawl.getBars().last);

      barsFromCrawl.clear();
    });


  }
  Color getColorFromCrawlId(String id, bool isSelected){
    if(isSelected){
      return Colors.lightBlueAccent[100];
    }
    switch(id[0]){
      case '6':
        return Colors.amber;
      case '7':
        return Colors.red;
      case '8':
        return Colors.red;
      case '9':
        return Colors.red;
      case '4':
      return Colors.red;
      case '1':
        return Colors.red;
      case '3':
      return Colors.red;
      case '2':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  createRouteForCrawl(PubCrawl crawl, bool check){
    for(int i = 0; i < crawl.getNumberOfBars(); i++){
      if(i+1 != crawl.getNumberOfBars()){
        createRouteBetweenBars(crawl.getBars()[i], crawl.getBars()[i+1], crawl, check);
      }else{
        createRouteBetweenBars(crawl.getBars()[i-1], crawl.getBars()[i], crawl, check);
      }
    }
    placeMarkersForBars(crawl.getBars());
  }
  createRouteBetweenBars(Bar bar1, Bar bar2, PubCrawl crawl, bool isSelected) async{

    var color =  getColorFromCrawlId(crawl.getId(), isSelected);
    if(currentCrawl == null){
      currentCrawl = crawl;
    }

    if (crawl != currentCrawl ) {
      currentCrawl = crawl;
    }

      _routeCoords = await _googleMapPolyline.getCoordinatesWithLocation(
          origin:  bar1.getCoord(),
          destination: bar2.getCoord(),
          mode: RouteMode.walking
      );
      setState(() {
        _polyline.add(
            Polyline(
              polylineId: PolylineId(uuid.v1()),
              visible: true,
              points: _routeCoords,
              width: 10,
              consumeTapEvents: true,
              onTap: () {
                if(!isSelected ){
                  createCrawlDialog(context, crawl);
                }
              },
              color: color,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            )
        );
      });
  }
  createRoute(Bar bar) async{
    //route from current position
    _routeCoords = await _googleMapPolyline.getCoordinatesWithLocation(
        origin:  LatLng(_currentLat, _currentLong),
        destination: bar.getCoord(),
        mode: RouteMode.walking
    );
    setState(() {
      _polyline.add(Polyline(
        polylineId: PolylineId(uuid.v1()), //same as bar ID
        visible: true,
        points: _routeCoords,
        width: 8,
        color:  Colors.amber,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ));
    });
  }

  void placeMarkersForBars( List<Bar> listOfBars) async{
    print("executed");
    listOfBars.asMap().entries.map((entry) async{

      int index = entry.key;
      Bar bar = entry.value;
      BitmapDescriptor _icon = BitmapDescriptor.defaultMarkerWithHue(333);

      if(index == 0){
        _icon =  await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(0.5,0.5)), 'assets/images/start.png');
      }
      if(index == listOfBars.length - 1){
        print("last");
        _icon =  await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(0.5,0.5)), 'assets/images/finish.png');
      }
      _barMarker.add(new Marker(
        icon:_icon,
        markerId: MarkerId(uuid.v1()),
        infoWindow: InfoWindow(title: bar.getName()),
        draggable: false,
        position: LatLng(bar.getLat(), bar.getLng()),
      ));

    }).toList();

    setState(() {
      //the marker is identified by the markerId and not with the index of the list
      _barMarker = this._barMarker;
    });
  }
  createCrawlDialog(BuildContext context, PubCrawl crawl) {
    return showDialog(context: context, builder: (context){
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            height: 500,
            width: 400,
            child: Center(
              child: ListView(
                children: <Widget>[
                  Text(
                    crawl.getName(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:  getColorFromCrawlId(crawl.getId(), false),
                    ),
                  ),
                  SizedBox(height:30),
                  Text("Created by: " + crawl.getAuthor()),
                  SizedBox(height:30),
                  Text("Created at: " + crawl.getStartTime().toString()),
                  SizedBox(height: 50),
                  Text("Bars visited: "),
                  SizedBox(height: 10),
                  ListView.builder(
                      shrinkWrap: true,
                      itemCount: crawl.getNumberOfBars(),
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          child: InkWell(
                            splashColor: getColorFromCrawlId(crawl.getId(), false),
                            onTap: () {
                              createAlertDialog(context,  crawl.getBars()[index]);
                            },
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text( crawl.getBars()[index].getName()),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                  ),
                  SizedBox(height:30),
                  FlatButton(
                    color:  getColorFromCrawlId(crawl.getId(), false),
                    child: Text("Follow this crawl"),
                    onPressed: () {
                      setState(() {
                        _polyline.clear();
                        _barMarker.clear();
                      });
                      Navigator.of(context).pop();
                      print("follow this crawl");
                      createRoute(crawl.getStartBar());
                      _getCurrentLocation();
                      createRouteForCrawl(crawl, true);
                      placeMarkersForBars(crawl.getBars());


                    },
                  )
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  createAlertDialog(BuildContext context, Bar bar) async{
    String _reviewCall =  'https://maps.googleapis.com/maps/api/place/details/json?place_id=${bar.getPlaceId()}&fields=reviews&key=$_APIkey';
    final response =  await http.get(_reviewCall);
    var _reviews = json.decode(response.body);

    var _reviewGood;

    int highestRating = 0;
    for(int i = 0; i< _reviews["result"].length; i++){
      if (_reviews["result"]["reviews"][i]["rating"] > highestRating){
        highestRating = _reviews["result"]["reviews"][i]["rating"];
        _reviewGood = _reviews["result"]["reviews"][i]["text"];
      }
    }
    return showDialog(context: context, builder: (context){
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
              height: 500,
              width: 400,
              child: ListView(
                children: <Widget>[
                  Center(
                    child: Text(
                      bar.getName(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                      ),
                    ),

                  ),
                  SizedBox(height: 20),
                  Image.network(
                    'https://maps.googleapis.com/maps/api/place/photo?maxwidth=300&photoreference=${bar.getPhotoRef()}&key=$_APIkey',
                  ),
                  SizedBox(height: 20),
                  Text(
                    _reviewGood,
                  ),
                  SizedBox(height: 50),
                  FlatButton(
                    color: Colors.amber,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Return"),
                  )
                ],
              ),
          ),
        ),
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Replace this container with your Map widget
        Container(
            child: Scaffold(
              body: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                polylines: _polyline,
                markers: Set.from(_barMarker),
                mapToolbarEnabled: false,
                initialCameraPosition:  CameraPosition(
                  target: LatLng(53.483959, -2.244644),
                  zoom: 12,
                ),
              ),
              floatingActionButton: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.blur_linear),
                    onPressed: () {
                      _findCrawlsHere();
                    },
                  ),
                  SizedBox(width: 10),
                  FloatingActionButton(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.my_location),
                    onPressed: () {
                      _getCurrentLocation();
                    },
                  )
                ],
              ),
            ),
        ),

        Positioned(
          top: 10,
          right: 15,
          left: 15,
          child: Container(

            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                    Radius.circular(20)
                )
            ),
            child: Row(
              children: <Widget>[
                IconButton(
                  splashColor: Colors.grey,
                  icon: Icon(Icons.search),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    onTap: () async{
                      Prediction p = await PlacesAutocomplete.show(
                        mode: Mode.overlay,
                          context: context,
                          apiKey: _APIkey,
                          language: "en",
                      );
                      if(p != null){
                        _getLatLng(p);
                      }
                    },
                    cursorColor: Colors.black,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.go,
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 15),
                        hintText: "go to  ",
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
