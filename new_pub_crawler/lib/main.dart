import 'app.dart';
import 'package:flutter/material.dart';
import 'Pages/loginPage.dart';
import 'package:newpubcrawler/authentication.dart';
import 'package:newpubcrawler/root_page.dart';

void main() {
  runApp(MaterialApp(
    title: "PubCrawler",
    debugShowCheckedModeBanner: false,

    home: new RootPage(
      auth: Auth(),
    ),
  ));
}

