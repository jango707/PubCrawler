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
  @override

  void initState() {
    stateManager = getIt.get<StateManager>();
  }

  createPopUp(BuildContext context){

    SimpleDialog alert = SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: Center(child: Text("End crawl")),
        children: <Widget>[
          Center(child: Text("You have finished this pub crawl")),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Text("Please add a description: "),
          ),
          Center(
            child: Container(
              height: 100,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: TextFormField(
                  cursorColor: Colors.amber,
                  maxLines: 20,
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
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Text("Please add a rating: "),
          ),
          Center(
            child: RatingBar(
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
          ),

          Align(
            child: RaisedButton(
              child: Text("Submit"),
              onPressed: () => {
                print(_rating)
              },
            ),
          )
        ],
      );


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
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
