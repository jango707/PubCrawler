import 'dart:async';
import 'dart:convert';
import 'package:google_map_polyline/google_map_polyline.dart';
import '../Bar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../StateManager.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class Maps extends StatefulWidget {
  @override
  _MapsState createState() => _MapsState();
}

class _MapsState extends State<Maps> {

  Set<Polyline> _polyline = {};
  List<LatLng> _routeCoords;
  List<LatLng> _routeCoordsForCrawl;
  GoogleMapPolyline _googleMapPolyline = new GoogleMapPolyline(apiKey: 'AIzaSyA_BuKYcyde_OzgWfBtxwXLnx7dokqEHB8');
  String _APIkey = 'AIzaSyA_BuKYcyde_OzgWfBtxwXLnx7dokqEHB8';
  Completer<GoogleMapController> _controller = Completer();
  List<Bar> _bars = [];
  double _currentLat;
  double _currentLong;
  List<Marker> positionMarker= [];
  var stateManager;

  @override
  void initState() {
    super.initState();
    stateManager = getIt.get<StateManager>();
    _getCurrentLocation();
    if(stateManager.getCrawlStarted() == true){
      _placePolyLines();
    }

  }

  void _getCurrentLocation() async{
    final position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    // print(position);
    _currentLat = position.latitude;
    _currentLong = position.longitude;

    var currentPosition = CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 16);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(currentPosition));

    positionMarker.add(Marker(
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
      positionMarker = this.positionMarker;
    });

  }
  _placePolyLines() {
    if(stateManager.getCurrentPubCrawl() != null && stateManager.getCurrentPubCrawl().getPolylines()!= null ){
      placeMarkersForBars(stateManager.getCurrentPubCrawl().getBars());
      setState(() {
        _polyline = stateManager.getCurrentPubCrawl().getPolylines();
      });
    }
  }
  _findCloseBars() async {
    print("searching");
    String _mapsCall = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentLat.toString()},${_currentLong.toString()}&radius=500&type=bar&keyword=pub&key=${_APIkey}';
    final response =  await http.get(_mapsCall);
     var _list = json.decode(response.body);
    for(int i = 0; i < _list["results"].length; i++){
      var closeBar = new Bar(
          _list["results"][i]["geometry"]["location"]["lat"],
          _list["results"][i]["geometry"]["location"]["lng"],
          _list["results"][i]["place_id"],
          _list["results"][i]["name"],
          _list["results"][i]["photos"][0]["photo_reference"]
      );

      _bars.add(closeBar);
    }

    placeMarkersForBars(_bars);
  }

  void placeMarkersForBars( List<Bar> listOfbars){

    listOfbars.map((bar) {
      positionMarker.add(new Marker(
        markerId: MarkerId(bar.getPlaceId()),
        infoWindow: InfoWindow(title: bar.getName()),
        draggable: false,
        onTap: () {
          createAlertDialog(context, bar);
        },
        position: LatLng(bar.getLat(), bar.getLng()),
      ));

    }).toList();

    setState(() {
      //the marker is identified by the markerId and not with the index of the list
      positionMarker = this.positionMarker;
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
        _polyline.clear();
        _polyline.add(Polyline(
        polylineId: PolylineId(bar.getPlaceId()), //same as bar ID
        visible: true,
        points: _routeCoords,
        width: 8,
        color:  Colors.amber,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ));
    });
    stateManager.getCurrentPubCrawl().setPolylines(_polyline);
  }
  createRouteForCrawl(Bar bar1, Bar bar2) async{
    print(bar1.getCoord().toString() +  bar2.getCoord().toString());
    _routeCoordsForCrawl = await _googleMapPolyline.getCoordinatesWithLocation(
        origin:  bar1.getCoord(),
        destination: bar2.getCoord(),
        mode: RouteMode.walking
    );
    setState(() {
      _polyline.add(
        Polyline(
          polylineId: PolylineId(bar2.getPlaceId()),
          visible: true,
          points: _routeCoordsForCrawl,
          width: 10,
          color: Colors.redAccent,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        )
      );
    });
    stateManager.getCurrentPubCrawl().setPolylines(_polyline);
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
                  SizedBox(height: 20),
                  Container(
                    child: Align(
                      alignment: FractionalOffset.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        child: StreamBuilder(
                          stream: stateManager.stream$,
                          initialData: false,
                          builder: (BuildContext context, AsyncSnapshot snap) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                StartOrContinueButton(bar),
                                SizedBox(width: 20),
                                FlatButton(
                                  child: Text("take me here"),
                                  color: Colors.grey,
                                  onPressed: () {
                                    print("selected");
                                    Navigator.of(context).pop();
                                    createRoute(bar);
                                  },
                                )
                              ],
                            );
                          }),
                      ),
                    ),
                  ),
                ],
              )
          ),
        ),
      );
    });
  }
  StartOrContinueButton(Bar bar) {
    if (stateManager.getCrawlStarted() == false || stateManager.getCrawlStarted() == null) {
      return FlatButton(
        child: Text("Start Crawl"),
        color: Colors.grey,
        onPressed: () {
          Navigator.of(context).pop();
          stateManager.startCrawl(bar);
          createRoute(bar);
          //activateStartOverlay(context);
        },
      );
    }else{
      return FlatButton(
        child: Text("Contine here"),
        color: Colors.grey,
        onPressed: () {
          Navigator.of(context).pop();

          createRouteForCrawl(stateManager.getCurrentPubCrawl().getLatestBar(), bar);
          stateManager.getCurrentPubCrawl().addBar(bar);
          print("crawl continued");
        },
      );
    }
  }
  activateStartOverlay(BuildContext context){
    OverlayState overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder:  (context) => Positioned(
        top:100,
        right: 20,
        left: 200,
        child: Dialog(
          backgroundColor: Colors.green,
          child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                height: 30,
                child: Center(child: Text("started"))
        )
      ),
    )
   ));
    overlayState.insert(overlayEntry);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        polylines: _polyline,
        initialCameraPosition:  CameraPosition(
          target: LatLng(53.483959, -2.244644),
          zoom: 12,
        ),
        markers: Set.from(positionMarker),
      ),

      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,

        children: <Widget>[

          FloatingActionButton(
              child: Icon(Icons.location_searching),
              onPressed: () {
                _getCurrentLocation();
              }
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            child: Icon(Icons.settings_input_antenna),
            onPressed: () {
              _findCloseBars();
            },
          ),

        ],
      ),

    );
  }
}
