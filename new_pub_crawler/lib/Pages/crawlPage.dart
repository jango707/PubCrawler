import 'package:flutter/material.dart';
import '../StateManager.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

final getIt = GetIt.instance;

class Crawl extends StatefulWidget {
  @override
  _CrawlState createState() => _CrawlState();
}

class _CrawlState extends State<Crawl> {
  var stateManager;
  var showPopUp = false;
  var _rating = 0.0;
  var _description;
  var _name;
  final _formKey = GlobalKey<FormState>();
  TextEditingController NameController = TextEditingController();
  TextEditingController DescController = TextEditingController();
  @override

  void initState() {
    stateManager = getIt.get<StateManager>();
  }

  createPopUp(BuildContext context){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.grey[100],
          elevation: 0,
          title: Center(child: Text("End crawl")),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: ListBody(
                children: <Widget>[
                  Text("You have finished this pub crawl"),
                  SizedBox(height: 10),
                  Text("Please name this Crawl: "),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: NameController,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Give a name';
                      }
                      return null;
                    },
                    cursorColor: Colors.amber,
                    maxLines: 1,
                    decoration: InputDecoration(
                      border: new OutlineInputBorder(
                        borderSide: new BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: new OutlineInputBorder(
                        borderSide: new BorderSide(color: Colors.grey),
                      ),
                      prefixIcon: Icon(
                        Icons.label_outline,
                        color: Colors.grey,
                      ),
                      focusColor: Colors.amber,
                      fillColor: Colors.amber,
                      hoverColor: Colors.amber,
                      labelText: 'Name',
                      labelStyle: TextStyle(color: Colors.black54),
                      isDense: true,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("Please add a description: "),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: DescController,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Give a description';
                      }
                      return null;
                    },
                    cursorColor: Colors.amber,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: new OutlineInputBorder(
                        borderSide: new BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: new OutlineInputBorder(
                        borderSide: new BorderSide(color: Colors.grey),
                      ),
                      prefixIcon: Icon(
                        Icons.description,
                        color: Colors.grey,
                      ),
                      focusColor: Colors.amber,
                      fillColor: Colors.amber,
                      hoverColor: Colors.amber,
                      labelText: 'Enter the desciption',
                      labelStyle: TextStyle(color: Colors.black54),
                      isDense: true,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("Please add a rating: "),
                  SizedBox(height: 10),
                  RatingBar(
                    initialRating: 1,
                    minRating: 0,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemPadding: EdgeInsets.all(4.0),
                    unratedColor: Colors.black26,
                    itemBuilder: (context, _) => Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      _rating = rating;
                    },
                  ),
                  SizedBox(height: 10),
                  Align(
                    child: RaisedButton(
                      child: Text("Submit"),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          stateManager.getCurrentPubCrawl().setName(NameController.text);
                          stateManager.getCurrentPubCrawl().setDesc(DescController.text);
                          stateManager.getCurrentPubCrawl().setRating(_rating);
                          stateManager.endCrawl();
                          print("rating: " + _rating.toString() + " name: " + NameController.text + " description: " + DescController.text);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );

  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: Center(
        child: Column(
          children: <Widget>[

            Text("YOUR PUBCRAWL"),
            Text("started by: " + stateManager.getCurrentPubCrawl().getAuthor()),
            Text("Started at: " + stateManager.getCurrentPubCrawl().getStartTime().toString()),
            Text("starting bar: " + stateManager.getCurrentPubCrawl().getStartBar().getName() ),
            Text("Bars visited: " + stateManager.getCurrentPubCrawl().getNumberOfBars().toString() ),
            FlatButton(
              child: Text("End Crawl"),
              color: Colors.grey,
              onPressed: () {
                createPopUp(context);
              }
            )

          ],
        ),
      ),
    );
  }
}
