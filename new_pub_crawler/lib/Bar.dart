
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Bar {

   String _businessStatus;
   LatLng _coords;
   double _lat;
   double _lng;
   String _id;
   String _placeId;
   String _name;
   String _openNow;
   String _photoRef;



   Bar(this._lat, this._lng, this._placeId, this._name, this._photoRef);

   getName(){ return _name;}
   getCoord(){ return LatLng(_lat,_lng);}
   getLat(){ return _lat;}
   getLng(){ return _lng;}
   getId(){ return _id;}
   getPlaceId(){ return _placeId;}
   getOpenNow(){ return _openNow;}
   getPhotoRef(){ return _photoRef;}

}