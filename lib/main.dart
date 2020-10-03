import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Meme App',
        theme: ThemeData(
          primarySwatch: Colors.purple,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: Text("Meme app"),
          ),
          body: ChangeNotifierProvider<MemeLoader>(
              create: (context) => MemeLoader(context),
              child: Center(child: MemePage())),
        ));
  }
}

class MemePage extends StatelessWidget {
  MemePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Consumer<MemeLoader>(
      builder: (context, memeLoader, child) => GestureDetector(
        onTap: () => memeLoader.next(context),
        onLongPress: () => memeLoader.previous(context),
        child: FutureBuilder<Meme>(
          future: memeLoader.currentMeme,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              throw snapshot.error;
            }

            if (snapshot.connectionState == ConnectionState.done) {
              return snapshot.data.preloadedImage;
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}

class Meme {
  final String postLink;
  final String subReddit;
  final String title;
  final String url;
  Image preloadedImage;

  Meme({this.postLink, this.subReddit, this.title, this.url});

  void preloadImage(BuildContext context) {
    final configuration = createLocalImageConfiguration(context);
    preloadedImage = Image(image: NetworkImage(url)..resolve(configuration));
  }

  factory Meme.fromJson(Map<String, dynamic> json) {
    return Meme(
      postLink: json['postLink'],
      subReddit: json['subReddit'],
      title: json['title'],
      url: json['url'],
    );
  }
}

// TODO: Unload old memes
class MemeLoader extends ChangeNotifier {
  static const int amountOfMemesToPreload = 5;
  final List<Future<Meme>> _loadingMemes = [];
  int _currentMemeIndex = 0;
  Future<Meme> currentMeme;

  MemeLoader(BuildContext context) {
    for (int i = 0; i < amountOfMemesToPreload; i++) {
      loadNewMeme(context);
    }

    currentMeme = _loadingMemes[0];
  }

  Future<Meme> fetchRandomMeme() {
    return http.get('https://meme-api.herokuapp.com/gimme').then((res) {
      return Meme.fromJson(jsonDecode(res.body));
    });
  }

  void loadNewMeme(BuildContext context) {
    final randomMemeFuture = fetchRandomMeme();
    // Once the meme is loaded, start loading it's image
    randomMemeFuture.then((meme) => meme.preloadImage(context));
    _loadingMemes.add(randomMemeFuture);
  }

  void next(BuildContext context) {
    currentMeme = _loadingMemes[++_currentMemeIndex];
    loadNewMeme(context);
    notifyListeners();
  }

  void previous(BuildContext context){
    if (_currentMemeIndex == 0){
      return;
    }

    currentMeme = _loadingMemes[--_currentMemeIndex];
    notifyListeners();
  }
}
